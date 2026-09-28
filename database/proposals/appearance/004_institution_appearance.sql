-- REVIEWED PACKAGE CANDIDATE. LOCAL PREPARATION ONLY.
-- Do not apply remotely without the user's explicit deployment approval.
BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';

DO $$
BEGIN
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Run as postgres; current role is %', current_user;
  END IF;
  IF to_regprocedure('public.bootstrap_institution(text)') IS NULL
     OR to_regprocedure('public.is_institution_admin(uuid)') IS NULL
     OR to_regprocedure('public.is_super_admin()') IS NULL
     OR to_regprocedure('public.save_school_structure(uuid,integer,uuid,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'Required NAOS security/structure migrations are missing';
  END IF;
  IF to_regclass('public.institution_appearances') IS NOT NULL
     OR to_regclass('public.institution_appearance_assets') IS NOT NULL THEN
    RAISE EXCEPTION 'Appearance schema already exists; inspect it before retrying';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='institutions'
      AND column_name='structure_revision' AND data_type='integer'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='institutions'
      AND column_name='template' AND data_type='text'
  ) THEN
    RAISE EXCEPTION 'Unexpected institutions schema';
  END IF;
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id='institution-appearance') THEN
    RAISE EXCEPTION 'Bucket institution-appearance already exists; inspect before retrying';
  END IF;
END $$;

CREATE TABLE public.institution_appearances (
  institution_id uuid PRIMARY KEY
    REFERENCES public.institutions(id) ON DELETE CASCADE,
  schema_version smallint NOT NULL DEFAULT 1
    CONSTRAINT institution_appearance_schema_v1 CHECK (schema_version = 1),
  config jsonb NOT NULL
    CONSTRAINT institution_appearance_config_object
      CHECK (jsonb_typeof(config) = 'object'),
  revision bigint NOT NULL DEFAULT 1
    CONSTRAINT institution_appearance_revision_positive CHECK (revision > 0),
  last_request_id uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL
);

COMMENT ON COLUMN public.institution_appearances.config IS
  'Versioned NAOS appearance JSON; maximum 262144 UTF-8 bytes enforced by RPC/trigger.';

CREATE TABLE public.institution_appearance_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id uuid NOT NULL
    REFERENCES public.institutions(id) ON DELETE CASCADE,
  request_id uuid NOT NULL,
  kind text NOT NULL CHECK (kind IN ('background','element')),
  slot smallint NOT NULL CHECK (slot BETWEEN 0 AND 4),
  storage_path text NOT NULL UNIQUE,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes > 0),
  width integer NOT NULL CHECK (width > 0),
  height integer NOT NULL CHECK (height > 0),
  checksum_sha256 text NOT NULL
    CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','active','retired','cleanup_pending')),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  activated_at timestamptz,
  retired_at timestamptz,
  CONSTRAINT institution_appearance_asset_kind_slot CHECK (
    (kind='background' AND slot=0) OR kind='element'
  ),
  CONSTRAINT institution_appearance_asset_limits CHECK (
    (kind='background' AND mime_type IN ('image/png','image/jpeg','image/webp')
      AND size_bytes<=5242880 AND width BETWEEN 180 AND 4096
      AND height BETWEEN 180 AND 4096)
    OR
    (kind='element' AND mime_type IN ('image/png','image/webp')
      AND size_bytes<=2097152 AND width BETWEEN 16 AND 2048
      AND height BETWEEN 16 AND 2048)
  ),
  UNIQUE (institution_id,request_id,kind,slot)
);

CREATE UNIQUE INDEX institution_appearance_one_active_background
  ON public.institution_appearance_assets(institution_id)
  WHERE status='active' AND kind='background';
CREATE UNIQUE INDEX institution_appearance_active_element_slots
  ON public.institution_appearance_assets(institution_id,slot)
  WHERE status='active' AND kind='element';
CREATE INDEX institution_appearance_assets_request
  ON public.institution_appearance_assets(institution_id,request_id,status);

ALTER TABLE public.institution_appearances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institution_appearance_assets ENABLE ROW LEVEL SECURITY;

CREATE FUNCTION public.can_read_institution_appearance(p_institution_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT public.is_super_admin()
    OR public.is_institution_admin(p_institution_id)
    OR EXISTS (
      SELECT 1 FROM public.institution_memberships m
      JOIN public.profiles p ON p.id=m.user_id
      WHERE m.user_id=auth.uid() AND m.institution_id=p_institution_id
        AND m.status='active' AND p.account_status='active'
        AND p.approval_status='approved'
    )
    OR EXISTS (
      SELECT 1 FROM public.institution_teachers t
      JOIN public.profiles p ON p.id=t.user_id
      WHERE t.user_id=auth.uid() AND t.institution_id=p_institution_id
        AND t.is_active AND p.account_status='active'
        AND p.approval_status='approved'
    );
$$;

CREATE FUNCTION public.can_manage_institution_appearance(p_institution_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT public.is_super_admin() OR (
    public.is_institution_admin(p_institution_id)
    AND (SELECT count(*)=1 FROM public.institution_admins a
         WHERE a.user_id=auth.uid() AND a.is_active
           AND a.institution_id=p_institution_id)
    AND (SELECT count(*)=1 FROM public.institution_memberships m
         WHERE m.user_id=auth.uid() AND m.institution_id=p_institution_id
           AND m.status='active' AND m.requested_role='institution_admin')
    AND NOT EXISTS (
      SELECT 1 FROM public.institution_memberships m
      WHERE m.user_id=auth.uid() AND m.status='active'
        AND m.requested_role='institution_admin'
        AND m.institution_id<>p_institution_id
    )
  );
$$;

REVOKE ALL ON FUNCTION public.can_read_institution_appearance(uuid),
  public.can_manage_institution_appearance(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.can_read_institution_appearance(uuid),
  public.can_manage_institution_appearance(uuid) TO authenticated,service_role;

CREATE POLICY naos_appearance_read
  ON public.institution_appearances FOR SELECT TO authenticated
  USING (public.can_read_institution_appearance(institution_id));
CREATE POLICY naos_appearance_assets_read
  ON public.institution_appearance_assets FOR SELECT TO authenticated
  USING (public.can_read_institution_appearance(institution_id));

GRANT SELECT ON public.institution_appearances,
  public.institution_appearance_assets TO authenticated;
REVOKE INSERT,UPDATE,DELETE,TRUNCATE ON public.institution_appearances,
  public.institution_appearance_assets FROM PUBLIC,anon,authenticated;

CREATE SCHEMA IF NOT EXISTS naos_security;
CREATE TABLE naos_security.appearance_write_capability (
  backend_pid integer NOT NULL,
  transaction_id bigint NOT NULL,
  user_id uuid NOT NULL,
  institution_id uuid NOT NULL,
  PRIMARY KEY (backend_pid,transaction_id,user_id,institution_id)
);
REVOKE ALL ON naos_security.appearance_write_capability
  FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION naos_security.has_appearance_write_capability(p_institution_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
  SELECT EXISTS (
    SELECT 1 FROM naos_security.appearance_write_capability c
    WHERE c.backend_pid=pg_backend_pid()
      AND c.transaction_id=txid_current()
      AND c.user_id=auth.uid()
      AND c.institution_id=p_institution_id
  );
$$;
REVOKE ALL ON FUNCTION naos_security.has_appearance_write_capability(uuid)
  FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION naos_security.validate_appearance_config(p_config jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog
AS $$
DECLARE slot text; c jsonb; a jsonb; buttons jsonb; selected_scene text;
  custom_slot_count integer;
BEGIN
  IF p_config IS NULL OR jsonb_typeof(p_config) IS DISTINCT FROM 'object'
     OR octet_length(p_config::text)>262144
     OR coalesce((p_config->>'schema_version')::integer,0)<>1
     OR coalesce(p_config->>'template','') NOT IN
       ('orbit','academy','pulse','littleSteps','adventure','studio',
        'heritage','prestige','nexus')
     OR coalesce(p_config->>'typography','') NOT IN
       ('inter','lora','spaceMono','nunito','fredoka','playfairDisplay',
        'poppins','quicksand','montserrat','bitter')
     OR coalesce(p_config->>'motion','') NOT IN
       ('none','soft','slide','spring','depth','playful') THEN
    RETURN false;
  END IF;
  buttons:=p_config->'buttons';
  IF jsonb_typeof(buttons) IS DISTINCT FROM 'object'
     OR coalesce(buttons->>'shape','') NOT IN ('square','soft','rounded','pill')
     OR coalesce(buttons->>'finish','') NOT IN
       ('solid','outlined','tonal','gradient','elevated') THEN RETURN false; END IF;
  IF jsonb_typeof(p_config->'colors') IS DISTINCT FROM 'object' THEN RETURN false; END IF;
  FOREACH slot IN ARRAY ARRAY['primary','secondary','accent','background'] LOOP
    c:=p_config->'colors'->slot;
    IF jsonb_typeof(c) IS DISTINCT FROM 'object'
       OR coalesce(c->>'hex','') !~ '^#[0-9A-Fa-f]{6}$'
       OR jsonb_typeof(c->'saturation') IS DISTINCT FROM 'number'
       OR jsonb_typeof(c->'lightness') IS DISTINCT FROM 'number'
       OR jsonb_typeof(c->'transparency') IS DISTINCT FROM 'number'
       OR (c->>'saturation')::numeric NOT BETWEEN 0 AND 1
       OR (c->>'lightness')::numeric NOT BETWEEN 0 AND 1
       OR (c->>'transparency')::numeric NOT BETWEEN 0 AND 100 THEN RETURN false; END IF;
  END LOOP;
  a:=p_config->'ambience';
  IF jsonb_typeof(a) IS DISTINCT FROM 'object'
     OR coalesce(a->>'kind','') NOT IN ('none','space','animals','ocean','nature','fantasy','my')
     OR jsonb_typeof(a->'section_scenes') IS DISTINCT FROM 'object'
     OR jsonb_typeof(a->'focal_points') IS DISTINCT FROM 'object'
     OR jsonb_typeof(a->'custom_element_asset_ids') IS DISTINCT FROM 'array'
     OR jsonb_typeof(a->'custom_element_slots') IS DISTINCT FROM 'object'
     OR jsonb_array_length(a->'custom_element_asset_ids')>5
     OR jsonb_typeof(a->'background_intensity') IS DISTINCT FROM 'number'
     OR jsonb_typeof(a->'decorative_elements_intensity') IS DISTINCT FROM 'number'
     OR jsonb_typeof(a->'element_motion') IS DISTINCT FROM 'number'
     OR (a->>'background_intensity')::numeric NOT BETWEEN 0 AND 100
     OR (a->>'decorative_elements_intensity')::numeric NOT BETWEEN 0 AND 100
     OR (a->>'element_motion')::numeric NOT BETWEEN 0 AND 100
     OR jsonb_typeof(p_config->'decoration_overrides') IS DISTINCT FROM 'object' THEN
    RETURN false;
  END IF;
  FOREACH slot IN ARRAY ARRAY['student','teacher','admin'] LOOP
    IF jsonb_typeof(a->'section_scenes'->slot) IS DISTINCT FROM 'object' THEN RETURN false; END IF;
  END LOOP;
  selected_scene:=a->>'selected_scene';
  IF NOT coalesce((
       (a->>'kind'='ocean' AND selected_scene IN
         ('turtleReef','sharkReef','jellyfishGarden'))
       OR (a->>'kind'='space' AND selected_scene IN
         ('planetExploration','orbitalStation','asteroidExpedition'))
       OR (a->>'kind'='animals' AND selected_scene IN
         ('foxGrove','deerMeadow','owlCanopy'))
       OR (a->>'kind'='nature' AND selected_scene IN
         ('ancientGrove','alpineVista','waterfallHaven'))
       OR (a->>'kind'='fantasy' AND selected_scene IN
         ('floatingCastle','enchantedLibrary','dragonGarden'))
       OR (a->>'kind' IN ('none','my') AND selected_scene IS NULL)
     ),false) THEN RETURN false; END IF;
  FOREACH slot IN ARRAY ARRAY['mobile','desktop'] LOOP
    c:=a->'focal_points'->slot;
    IF jsonb_typeof(c) IS DISTINCT FROM 'object'
       OR jsonb_typeof(c->'x') IS DISTINCT FROM 'number'
       OR jsonb_typeof(c->'y') IS DISTINCT FROM 'number'
       OR (c->>'x')::numeric NOT BETWEEN -1 AND 1
       OR (c->>'y')::numeric NOT BETWEEN -1 AND 1 THEN RETURN false; END IF;
  END LOOP;
  IF a->>'kind'<>'my' AND
     (a->>'custom_background_asset_id' IS NOT NULL
      OR jsonb_array_length(a->'custom_element_asset_ids')<>0
      OR a->'custom_element_slots'<>'{}'::jsonb) THEN RETURN false; END IF;
  SELECT count(*) INTO custom_slot_count
    FROM jsonb_object_keys(a->'custom_element_slots');
  IF a->>'kind'='my' AND (
       custom_slot_count <>
         jsonb_array_length(a->'custom_element_asset_ids')
       OR EXISTS (
         SELECT 1 FROM jsonb_each_text(a->'custom_element_slots') e
         WHERE e.key !~ '^[0-4]$'
            OR e.value !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
            OR NOT (a->'custom_element_asset_ids' ? e.value)
       )
     ) THEN RETURN false; END IF;
  RETURN true;
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range
  OR null_value_not_allowed THEN RETURN false;
END $$;
REVOKE ALL ON FUNCTION naos_security.validate_appearance_config(jsonb)
  FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION naos_security.guard_appearance_config()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF NOT naos_security.validate_appearance_config(NEW.config) THEN
    RAISE EXCEPTION 'Invalid appearance configuration' USING ERRCODE='23514';
  END IF;
  IF NOT naos_security.has_appearance_write_capability(NEW.institution_id) THEN
    RAISE EXCEPTION 'Appearance changes require the activation RPC' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION naos_security.guard_appearance_config()
  FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER naos_guard_appearance_config
BEFORE INSERT OR UPDATE ON public.institution_appearances
FOR EACH ROW EXECUTE FUNCTION naos_security.guard_appearance_config();

CREATE FUNCTION naos_security.guard_institution_appearance_fields()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NULL AND current_setting('role',true) IN ('none','postgres') THEN
    RETURN NEW;
  END IF;
  IF NEW.template IS DISTINCT FROM OLD.template
     OR NEW.theme_color IS DISTINCT FROM OLD.theme_color
     OR NEW.font_style IS DISTINCT FROM OLD.font_style
     OR NEW.button_style IS DISTINCT FROM OLD.button_style
     OR NEW.onboarding_completed IS DISTINCT FROM OLD.onboarding_completed
     OR (NEW.onboarding_step=9 AND OLD.onboarding_step IS DISTINCT FROM 9) THEN
    IF NOT naos_security.has_appearance_write_capability(NEW.id) THEN
      RAISE EXCEPTION 'Appearance activation/finalization requires the activation RPC'
        USING ERRCODE='42501';
    END IF;
  END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION naos_security.guard_institution_appearance_fields()
  FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER naos_guard_institution_appearance_fields
BEFORE UPDATE ON public.institutions FOR EACH ROW
EXECUTE FUNCTION naos_security.guard_institution_appearance_fields();

INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES ('institution-appearance','institution-appearance',false,5242880,
  ARRAY['image/png','image/jpeg','image/webp']::text[]);

CREATE POLICY naos_appearance_objects_read
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id='institution-appearance'
  AND (storage.foldername(name))[1] ~
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
  AND public.can_read_institution_appearance(((storage.foldername(name))[1])::uuid)
);
-- No authenticated INSERT/UPDATE/DELETE policy is created. The validated Edge
-- Function writes with its server-side service role. Active objects therefore
-- cannot be overwritten or deleted directly by an application client.

CREATE FUNCTION public.prepare_institution_appearance_asset(
  p_institution_id uuid,p_request_id uuid,p_asset_id uuid,p_kind text,
  p_slot integer,p_extension text,p_mime_type text,p_size_bytes bigint,
  p_width integer,p_height integer,p_checksum_sha256 text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE existing public.institution_appearance_assets%ROWTYPE; path text;
BEGIN
  IF NOT public.can_manage_institution_appearance(p_institution_id) THEN
    RAISE EXCEPTION 'Institution appearance management required' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_asset_id IS NULL OR p_kind NOT IN ('background','element')
     OR p_slot NOT BETWEEN 0 AND 4 OR (p_kind='background' AND p_slot<>0)
     OR p_extension NOT IN ('png','jpg','jpeg','webp')
     OR p_checksum_sha256 !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'Invalid asset manifest' USING ERRCODE='22023';
  END IF;
  IF p_kind='background' THEN
    path:=p_institution_id||'/requests/'||p_request_id||'/background.'||p_extension;
  ELSE
    path:=p_institution_id||'/requests/'||p_request_id||'/elements/'||p_asset_id||'.'||p_extension;
  END IF;
  SELECT * INTO existing FROM public.institution_appearance_assets
    WHERE institution_id=p_institution_id AND request_id=p_request_id
      AND kind=p_kind AND slot=p_slot FOR UPDATE;
  IF FOUND THEN
    IF existing.id=p_asset_id AND existing.checksum_sha256=p_checksum_sha256
       AND existing.status='pending' THEN
      RETURN to_jsonb(existing);
    END IF;
    RAISE EXCEPTION 'Asset slot already prepared with different content' USING ERRCODE='23505';
  END IF;
  INSERT INTO public.institution_appearance_assets(
    id,institution_id,request_id,kind,slot,storage_path,mime_type,size_bytes,
    width,height,checksum_sha256,created_by)
  VALUES (p_asset_id,p_institution_id,p_request_id,p_kind,p_slot,path,
    p_mime_type,p_size_bytes,p_width,p_height,p_checksum_sha256,auth.uid())
  RETURNING * INTO existing;
  RETURN to_jsonb(existing);
END $$;

CREATE FUNCTION public.get_institution_appearance(p_institution_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE result jsonb;
BEGIN
  IF NOT public.can_read_institution_appearance(p_institution_id) THEN
    RAISE EXCEPTION 'Institution appearance access required' USING ERRCODE='42501';
  END IF;
  SELECT jsonb_build_object(
    'institution_id',i.id,'template',i.template,'theme_color',i.theme_color,
    'font_style',i.font_style,'button_style',i.button_style,
    'appearance',CASE WHEN a.institution_id IS NULL THEN NULL ELSE
      jsonb_build_object('schema_version',a.schema_version,'config',a.config,
        'revision',a.revision,'updated_at',a.updated_at) END,
    'assets',coalesce((SELECT jsonb_agg(jsonb_build_object(
      'id',x.id,'kind',x.kind,'slot',x.slot,'storage_path',x.storage_path,
      'mime_type',x.mime_type,'width',x.width,'height',x.height)
      ORDER BY x.kind,x.slot) FROM public.institution_appearance_assets x
      WHERE x.institution_id=i.id AND x.status='active'),'[]'::jsonb)
  ) INTO result FROM public.institutions i
  LEFT JOIN public.institution_appearances a ON a.institution_id=i.id
  WHERE i.id=p_institution_id;
  IF result IS NULL THEN RAISE EXCEPTION 'Institution not found' USING ERRCODE='22023'; END IF;
  RETURN result;
END $$;

CREATE FUNCTION public.activate_institution_appearance(
  p_institution_id uuid,p_expected_revision bigint,p_request_id uuid,
  p_config jsonb,p_complete_onboarding boolean DEFAULT false
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE inst public.institutions%ROWTYPE; current_revision bigint:=0;
  existing_request uuid; ref_ids uuid[]:=ARRAY[]::uuid[]; raw text; aid uuid;
  required_pending integer; present_pending integer; new_revision bigint;
BEGIN
  IF NOT public.can_manage_institution_appearance(p_institution_id) THEN
    RAISE EXCEPTION 'Institution appearance management required' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR NOT naos_security.validate_appearance_config(p_config) THEN
    RAISE EXCEPTION 'Invalid appearance activation request' USING ERRCODE='22023';
  END IF;
  SELECT * INTO inst FROM public.institutions WHERE id=p_institution_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Institution not found' USING ERRCODE='22023'; END IF;
  SELECT revision,last_request_id INTO current_revision,existing_request
    FROM public.institution_appearances WHERE institution_id=p_institution_id FOR UPDATE;
  current_revision:=coalesce(current_revision,0);
  IF existing_request=p_request_id THEN
    RETURN jsonb_build_object('revision',current_revision,'idempotent',true,
      'onboarding_completed',inst.onboarding_completed);
  END IF;
  IF p_expected_revision IS DISTINCT FROM current_revision THEN
    RAISE EXCEPTION 'Appearance changed in another session. Reload before saving.'
      USING ERRCODE='40001';
  END IF;
  raw:=p_config->'ambience'->>'custom_background_asset_id';
  IF raw IS NOT NULL THEN
    IF raw !~ '^[0-9a-fA-F-]{36}$' THEN RAISE EXCEPTION 'Invalid background asset ID'; END IF;
    ref_ids:=array_append(ref_ids,raw::uuid);
    IF NOT EXISTS (
      SELECT 1 FROM public.institution_appearance_assets x
      WHERE x.id=raw::uuid AND x.kind='background'
    ) THEN RAISE EXCEPTION 'Background asset ID does not identify a background'
      USING ERRCODE='22023'; END IF;
  END IF;
  FOR raw IN SELECT jsonb_array_elements_text(
      p_config->'ambience'->'custom_element_asset_ids') LOOP
    IF raw !~ '^[0-9a-fA-F-]{36}$' THEN RAISE EXCEPTION 'Invalid element asset ID'; END IF;
    aid:=raw::uuid;
    IF aid=ANY(ref_ids) THEN RAISE EXCEPTION 'Duplicate custom asset ID'; END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.institution_appearance_assets x
      WHERE x.id=aid AND x.kind='element'
    ) THEN RAISE EXCEPTION 'Element asset ID does not identify an element'
      USING ERRCODE='22023'; END IF;
    ref_ids:=array_append(ref_ids,aid);
  END LOOP;
  IF p_config->'ambience'->>'kind'='my' THEN
    IF EXISTS (SELECT 1 FROM unnest(ref_ids) r
      LEFT JOIN public.institution_appearance_assets x ON x.id=r
      WHERE x.id IS NULL OR x.institution_id<>p_institution_id
        OR (x.status='pending' AND x.request_id<>p_request_id)
        OR x.status IN ('retired','cleanup_pending')) THEN
      RAISE EXCEPTION 'Custom asset does not belong to this active request/institution';
    END IF;
  ELSIF cardinality(ref_ids)<>0 THEN
    RAISE EXCEPTION 'Built-in ambience cannot reference custom assets';
  END IF;
  SELECT count(*) INTO required_pending FROM public.institution_appearance_assets
    WHERE id=ANY(ref_ids) AND status='pending' AND request_id=p_request_id;
  SELECT count(*) INTO present_pending
    FROM public.institution_appearance_assets x
    JOIN storage.objects o ON o.bucket_id='institution-appearance'
      AND o.name=x.storage_path
    WHERE x.id=ANY(ref_ids) AND x.status='pending' AND x.request_id=p_request_id
      AND coalesce((o.metadata->>'size')::bigint,x.size_bytes)=x.size_bytes
      AND coalesce(o.metadata->>'mimetype',x.mime_type)=x.mime_type;
  IF required_pending<>present_pending THEN
    RAISE EXCEPTION 'One or more prepared assets are missing or changed in Storage';
  END IF;
  IF p_complete_onboarding THEN
    IF public.is_super_admin() OR inst.onboarding_completed OR inst.onboarding_step<>8
       OR nullif(btrim(inst.name),'') IS NULL OR inst.structure_revision<1
       OR nullif(btrim(inst.timezone),'') IS NULL THEN
      RAISE EXCEPTION 'Onboarding prerequisites are not satisfied' USING ERRCODE='23514';
    END IF;
  END IF;
  INSERT INTO naos_security.appearance_write_capability
    VALUES(pg_backend_pid(),txid_current(),auth.uid(),p_institution_id);
  UPDATE public.institution_appearance_assets SET status='retired',retired_at=now()
    WHERE institution_id=p_institution_id AND status='active'
      AND NOT(id=ANY(ref_ids));
  UPDATE public.institution_appearance_assets
    SET status='active',activated_at=coalesce(activated_at,now()),retired_at=NULL
    WHERE institution_id=p_institution_id AND id=ANY(ref_ids)
      AND status='pending' AND request_id=p_request_id;
  new_revision:=current_revision+1;
  INSERT INTO public.institution_appearances(
    institution_id,schema_version,config,revision,last_request_id,updated_at,updated_by)
  VALUES(p_institution_id,1,p_config,new_revision,p_request_id,now(),auth.uid())
  ON CONFLICT(institution_id) DO UPDATE SET schema_version=1,config=excluded.config,
    revision=excluded.revision,last_request_id=excluded.last_request_id,
    updated_at=now(),updated_by=auth.uid();
  UPDATE public.institutions SET
    template=p_config->>'template',
    theme_color=p_config->'colors'->'primary'->>'hex',
    font_style=p_config->>'typography',
    button_style=(p_config->'buttons'->>'shape')||':'||
      (p_config->'buttons'->>'finish'),
    onboarding_step=CASE WHEN p_complete_onboarding THEN 9 ELSE onboarding_step END,
    onboarding_completed=CASE WHEN p_complete_onboarding THEN true ELSE onboarding_completed END
    WHERE id=p_institution_id;
  DELETE FROM naos_security.appearance_write_capability
    WHERE backend_pid=pg_backend_pid() AND transaction_id=txid_current()
      AND user_id=auth.uid() AND institution_id=p_institution_id;
  RETURN jsonb_build_object('revision',new_revision,'idempotent',false,
    'onboarding_completed',p_complete_onboarding OR inst.onboarding_completed);
END $$;

CREATE FUNCTION public.authorize_institution_appearance_asset_cleanup(p_asset_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE x public.institution_appearance_assets%ROWTYPE;
BEGIN
  SELECT * INTO x FROM public.institution_appearance_assets WHERE id=p_asset_id FOR UPDATE;
  IF NOT FOUND OR NOT public.can_manage_institution_appearance(x.institution_id) THEN
    RAISE EXCEPTION 'Asset cleanup is not authorized' USING ERRCODE='42501';
  END IF;
  IF x.status='active' OR EXISTS (
    SELECT 1 FROM public.institution_appearances a
    WHERE a.institution_id=x.institution_id AND
      (a.config->'ambience'->>'custom_background_asset_id'=x.id::text
       OR a.config->'ambience'->'custom_element_asset_ids' ? x.id::text)
  ) THEN RAISE EXCEPTION 'An active configuration still references this asset' USING ERRCODE='23503'; END IF;
  UPDATE public.institution_appearance_assets
    SET status='cleanup_pending',retired_at=coalesce(retired_at,now())
    WHERE id=x.id
    RETURNING * INTO x;
  RETURN jsonb_build_object('id',x.id,'institution_id',x.institution_id,
    'storage_path',x.storage_path,'status',x.status);
END $$;

CREATE FUNCTION public.confirm_institution_appearance_asset_cleanup(p_asset_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE x public.institution_appearance_assets%ROWTYPE;
BEGIN
  SELECT * INTO x FROM public.institution_appearance_assets WHERE id=p_asset_id FOR UPDATE;
  IF NOT FOUND THEN RETURN; END IF;
  IF NOT public.can_manage_institution_appearance(x.institution_id)
     OR x.status<>'cleanup_pending' THEN
    RAISE EXCEPTION 'Asset cleanup is not authorized' USING ERRCODE='42501';
  END IF;
  IF EXISTS(SELECT 1 FROM storage.objects o
    WHERE o.bucket_id='institution-appearance' AND o.name=x.storage_path) THEN
    RAISE EXCEPTION 'Storage object still exists; delete it before confirming cleanup';
  END IF;
  DELETE FROM public.institution_appearance_assets WHERE id=p_asset_id;
END $$;

CREATE FUNCTION public.list_pending_institution_appearance_assets(p_institution_id uuid)
RETURNS SETOF public.institution_appearance_assets LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog AS $$
BEGIN
  IF NOT public.can_manage_institution_appearance(p_institution_id) THEN
    RAISE EXCEPTION 'Institution appearance management required' USING ERRCODE='42501';
  END IF;
  RETURN QUERY SELECT * FROM public.institution_appearance_assets x
    WHERE x.institution_id=p_institution_id
      AND x.status IN ('pending','retired','cleanup_pending')
    ORDER BY x.created_at,x.id;
END $$;

REVOKE ALL ON FUNCTION public.prepare_institution_appearance_asset(
  uuid,uuid,uuid,text,integer,text,text,bigint,integer,integer,text),
  public.get_institution_appearance(uuid),
  public.activate_institution_appearance(uuid,bigint,uuid,jsonb,boolean),
  public.authorize_institution_appearance_asset_cleanup(uuid),
  public.confirm_institution_appearance_asset_cleanup(uuid),
  public.list_pending_institution_appearance_assets(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.prepare_institution_appearance_asset(
  uuid,uuid,uuid,text,integer,text,text,bigint,integer,integer,text),
  public.get_institution_appearance(uuid),
  public.activate_institution_appearance(uuid,bigint,uuid,jsonb,boolean),
  public.authorize_institution_appearance_asset_cleanup(uuid),
  public.confirm_institution_appearance_asset_cleanup(uuid),
  public.list_pending_institution_appearance_assets(uuid)
  TO authenticated;

-- Replace bootstrap with the reviewed implementation plus one narrowly scoped
-- change: a newly-created school receives its matching active admin membership
-- in the same transaction. Existing linked schools are never repaired/reassigned.
CREATE OR REPLACE FUNCTION public.bootstrap_institution(p_name text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE u uuid:=auth.uid(); p public.profiles%ROWTYPE;
  a public.institution_admins%ROWTYPE; institution uuid;
BEGIN
  IF u IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  SELECT * INTO p FROM public.profiles WHERE id=u FOR UPDATE;
  IF NOT FOUND OR p.role IS DISTINCT FROM 'institution_admin'
     OR p.approval_status IS DISTINCT FROM 'approved'
     OR p.account_status IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION 'Approved active institution admin required' USING ERRCODE='42501';
  END IF;
  IF p_name IS NULL OR btrim(p_name)='' THEN RAISE EXCEPTION 'School name required' USING ERRCODE='22023'; END IF;
  IF (SELECT count(*) FROM public.institution_admins WHERE user_id=u)>1 THEN
    RAISE EXCEPTION 'Ambiguous admin relations: contact super admin' USING ERRCODE='22023';
  END IF;
  SELECT * INTO a FROM public.institution_admins WHERE user_id=u FOR UPDATE;
  IF FOUND AND NOT a.is_active THEN RAISE EXCEPTION 'Admin relation is inactive' USING ERRCODE='42501'; END IF;
  PERFORM 1 FROM public.institution_memberships WHERE user_id=u FOR UPDATE;
  IF EXISTS(SELECT 1 FROM public.institution_memberships m WHERE m.user_id=u
    AND m.status='active' AND m.requested_role='institution_admin'
    AND m.institution_id IS DISTINCT FROM a.institution_id) THEN
    RAISE EXCEPTION 'Administrative membership and admin link disagree; explicit review required'
      USING ERRCODE='22023';
  END IF;
  IF a.institution_id IS NOT NULL THEN RETURN a.institution_id; END IF;
  INSERT INTO public.institutions(name) VALUES(btrim(p_name)) RETURNING id INTO institution;
  INSERT INTO naos_security.bootstrap_capability
    VALUES(pg_backend_pid(),txid_current(),u,institution);
  IF a.id IS NULL THEN
    INSERT INTO public.institution_admins(user_id,institution_id,is_active)
      VALUES(u,institution,true);
  ELSE
    UPDATE public.institution_admins SET institution_id=institution WHERE id=a.id;
  END IF;
  INSERT INTO public.institution_memberships(
    user_id,institution_id,status,requested_role,requested_at,approved_at,
    approved_by,reviewed_at,created_at,updated_at)
  VALUES(u,institution,'active','institution_admin',now(),now(),p.approved_by,now(),now(),now());
  DELETE FROM naos_security.bootstrap_capability
    WHERE backend_pid=pg_backend_pid() AND transaction_id=txid_current() AND user_id=u;
  RETURN institution;
END $$;
REVOKE ALL ON FUNCTION public.bootstrap_institution(text) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.bootstrap_institution(text) TO authenticated;

NOTIFY pgrst,'reload schema';
COMMIT;
