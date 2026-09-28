-- DESTRUCTIVE ONLY TO SYNTHETIC ROWS; final ROLLBACK is mandatory.
-- Run as postgres on a disposable restore after 004.
BEGIN;
SET LOCAL statement_timeout='45s';
SET LOCAL lock_timeout='5s';

CREATE FUNCTION pg_temp.assert_true(ok boolean,message text)
RETURNS void LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',message; END IF;
  RAISE NOTICE 'PASS: %',message;
END $$;
CREATE FUNCTION pg_temp.expect_error(command text,expected_state text)
RETURNS void LANGUAGE plpgsql AS $$ DECLARE actual text; BEGIN
  BEGIN EXECUTE command;
  EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS actual=RETURNED_SQLSTATE;
    IF actual=expected_state THEN RETURN; END IF;
    RAISE EXCEPTION 'Expected %, got %: %',expected_state,actual,SQLERRM;
  END;
  RAISE EXCEPTION 'Expected error %, statement succeeded',expected_state;
END $$;
CREATE FUNCTION pg_temp.config(kind text DEFAULT 'ocean',background uuid DEFAULT NULL,
  elements jsonb DEFAULT '[]'::jsonb)
RETURNS jsonb LANGUAGE sql AS $$ SELECT jsonb_build_object(
  'schema_version',1,'template','orbit','typography','inter','motion','soft',
  'buttons',jsonb_build_object('shape','rounded','finish','solid'),
  'colors',jsonb_build_object(
    'primary',jsonb_build_object('hex','#675CFF','saturation',0.52,'lightness',0.68,'transparency',0),
    'secondary',jsonb_build_object('hex','#22B8CF','saturation',0.71,'lightness',0.47,'transparency',0),
    'accent',jsonb_build_object('hex','#FFC857','saturation',1,'lightness',0.67,'transparency',0),
    'background',jsonb_build_object('hex','#080D24','saturation',0.64,'lightness',0.09,'transparency',0)),
  'ambience',jsonb_build_object('kind',kind,'selected_scene',CASE WHEN kind='ocean' THEN 'turtleReef' END,
    'preview_by_section',true,'section_scenes',jsonb_build_object(
      'student','{}'::jsonb,'teacher','{}'::jsonb,'admin','{}'::jsonb),
    'background_intensity',65,'decorative_elements_intensity',65,'element_motion',35,
    'custom_background_asset_id',background,'custom_element_asset_ids',elements,
    'custom_element_slots',coalesce((SELECT jsonb_object_agg((ordinality-1)::text,value)
      FROM jsonb_array_elements_text(elements) WITH ORDINALITY), '{}'::jsonb),
    'focal_points',jsonb_build_object('mobile',jsonb_build_object('x',0,'y',0),
      'desktop',jsonb_build_object('x',0,'y',0))),
  'decoration_overrides','{}'::jsonb) $$;

CREATE TEMP TABLE fixture(kind text PRIMARY KEY,id uuid DEFAULT gen_random_uuid());
INSERT INTO fixture(kind) VALUES
 ('admin_a'),('admin_b'),('student_a'),('student_b'),('teacher_a'),
 ('super'),('new_admin'),('institution_a'),('institution_b'),('request_a'),
 ('request_b'),('asset_background');
GRANT SELECT ON fixture TO authenticated;
-- pg_restore rehearsal intentionally used --no-privileges; restore the two
-- production grants exercised directly by this test transaction.
GRANT SELECT,UPDATE ON public.institutions TO authenticated;
GRANT SELECT ON public.institution_memberships TO authenticated;
GRANT USAGE ON SCHEMA auth TO authenticated;

INSERT INTO auth.users(id,email,role,aud,raw_user_meta_data,raw_app_meta_data,created_at,updated_at)
SELECT id,'appearance-'||kind||'@example.invalid','authenticated','authenticated',
 jsonb_build_object('username','appearance_'||kind),'{}'::jsonb,now(),now()
FROM fixture WHERE kind IN ('admin_a','admin_b','student_a','student_b','teacher_a','super','new_admin');
INSERT INTO public.profiles(id,username,role,approval_status,account_status,approved_by)
SELECT id,'appearance_'||kind,
 CASE WHEN kind='super' THEN 'super_admin'
      WHEN kind LIKE 'admin_%' OR kind='new_admin' THEN 'institution_admin'
      WHEN kind='teacher_a' THEN 'teacher' ELSE 'student' END,
 'approved','active',(SELECT id FROM fixture WHERE kind='super')
FROM fixture WHERE kind IN ('admin_a','admin_b','student_a','student_b','teacher_a','super','new_admin')
ON CONFLICT(id) DO UPDATE SET role=excluded.role,approval_status='approved',account_status='active';
INSERT INTO public.institutions(id,name,timezone,structure_revision,onboarding_step,onboarding_completed)
SELECT id,'Appearance '||kind,'Australia/Brisbane',1,8,false
FROM fixture WHERE kind IN ('institution_a','institution_b');
INSERT INTO public.institution_admins(user_id,institution_id,is_active)
SELECT (SELECT id FROM fixture WHERE kind='admin_a'),id,true FROM fixture WHERE kind='institution_a'
UNION ALL
SELECT (SELECT id FROM fixture WHERE kind='admin_b'),id,true FROM fixture WHERE kind='institution_b';
INSERT INTO public.institution_memberships(user_id,institution_id,status,requested_role,requested_at,approved_at)
VALUES
 ((SELECT id FROM fixture WHERE kind='admin_a'),(SELECT id FROM fixture WHERE kind='institution_a'),'active','institution_admin',now(),now()),
 ((SELECT id FROM fixture WHERE kind='admin_b'),(SELECT id FROM fixture WHERE kind='institution_b'),'active','institution_admin',now(),now()),
 ((SELECT id FROM fixture WHERE kind='student_a'),(SELECT id FROM fixture WHERE kind='institution_a'),'active','student',now(),now()),
 ((SELECT id FROM fixture WHERE kind='student_b'),(SELECT id FROM fixture WHERE kind='institution_b'),'active','student',now(),now());
INSERT INTO public.institution_teachers(user_id,institution_id,is_active)
VALUES((SELECT id FROM fixture WHERE kind='teacher_a'),(SELECT id FROM fixture WHERE kind='institution_a'),true);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='admin_a'),true);
SELECT public.activate_institution_appearance(
 (SELECT id FROM fixture WHERE kind='institution_a'),0,
 (SELECT id FROM fixture WHERE kind='request_a'),pg_temp.config(),true);
SELECT pg_temp.assert_true((SELECT onboarding_step=9 AND onboarding_completed
  AND template='orbit' AND theme_color='#675CFF' AND font_style='inter'
  AND button_style='rounded:solid' FROM public.institutions
  WHERE id=(SELECT id FROM fixture WHERE kind='institution_a')),
  'Appearance activation and onboarding completion are atomic');
SELECT pg_temp.assert_true((SELECT revision=1 FROM public.institution_appearances
  WHERE institution_id=(SELECT id FROM fixture WHERE kind='institution_a')),
  'First revision stored');
SELECT pg_temp.expect_error(format($q$SELECT public.activate_institution_appearance(
  %L,1,%L,pg_temp.config()-'template',false)$q$,
  (SELECT id FROM fixture WHERE kind='institution_a'),gen_random_uuid()),'22023');
SELECT pg_temp.expect_error($q$UPDATE public.institutions SET template='nexus'
 WHERE id=(SELECT id FROM fixture WHERE kind='institution_a')$q$,'42501');
SELECT pg_temp.expect_error(format($q$SELECT public.activate_institution_appearance(%L,0,%L,pg_temp.config(),false)$q$,
  (SELECT id FROM fixture WHERE kind='institution_a'),gen_random_uuid()),'40001');

SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='admin_b'),true);
SELECT pg_temp.expect_error(format('SELECT public.get_institution_appearance(%L)',
  (SELECT id FROM fixture WHERE kind='institution_a')),'42501');
SELECT pg_temp.expect_error(format($q$SELECT public.activate_institution_appearance(%L,1,%L,pg_temp.config(),false)$q$,
  (SELECT id FROM fixture WHERE kind='institution_a'),gen_random_uuid()),'42501');

SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='super'),true);
SELECT pg_temp.assert_true(public.get_institution_appearance(
  (SELECT id FROM fixture WHERE kind='institution_a')) IS NOT NULL
  AND public.can_manage_institution_appearance(
    (SELECT id FROM fixture WHERE kind='institution_a')),
  'Super admin can read and manage institutional appearance');

SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='student_a'),true);
SELECT pg_temp.assert_true(public.get_institution_appearance(
  (SELECT id FROM fixture WHERE kind='institution_a')) IS NOT NULL,
  'Same-institution active student can read appearance');
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='student_b'),true);
SELECT pg_temp.expect_error(format('SELECT public.get_institution_appearance(%L)',
  (SELECT id FROM fixture WHERE kind='institution_a')),'42501');
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='teacher_a'),true);
SELECT pg_temp.assert_true(public.get_institution_appearance(
  (SELECT id FROM fixture WHERE kind='institution_a')) IS NOT NULL,
  'Same-institution active teacher can read appearance');

SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='admin_a'),true);
SELECT public.prepare_institution_appearance_asset(
 (SELECT id FROM fixture WHERE kind='institution_a'),
 (SELECT id FROM fixture WHERE kind='request_b'),
 (SELECT id FROM fixture WHERE kind='asset_background'),'background',0,'png','image/png',1024,512,512,
 repeat('a',64));
RESET ROLE;
INSERT INTO storage.objects(bucket_id,name,owner,metadata)
SELECT 'institution-appearance',storage_path,(SELECT id FROM fixture WHERE kind='admin_a'),
 jsonb_build_object('size',size_bytes,'mimetype',mime_type)
FROM public.institution_appearance_assets WHERE id=(SELECT id FROM fixture WHERE kind='asset_background');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='admin_a'),true);
SELECT pg_temp.expect_error(format($q$SELECT public.activate_institution_appearance(%L,1,%L,
 pg_temp.config('my',NULL,jsonb_build_array(%L::text)),false)$q$,
 (SELECT id FROM fixture WHERE kind='institution_a'),gen_random_uuid(),
 (SELECT id FROM fixture WHERE kind='asset_background')),'22023');
SELECT public.activate_institution_appearance(
 (SELECT id FROM fixture WHERE kind='institution_a'),1,
 (SELECT id FROM fixture WHERE kind='request_b'),
 pg_temp.config('my',(SELECT id FROM fixture WHERE kind='asset_background')),false);
SELECT pg_temp.assert_true((SELECT status='active' FROM public.institution_appearance_assets
 WHERE id=(SELECT id FROM fixture WHERE kind='asset_background')),
 'Pending asset becomes active only with its referencing configuration');
SELECT pg_temp.expect_error(format('SELECT public.authorize_institution_appearance_asset_cleanup(%L)',
 (SELECT id FROM fixture WHERE kind='asset_background')),'23503');
SELECT public.activate_institution_appearance(
 (SELECT id FROM fixture WHERE kind='institution_a'),2,gen_random_uuid(),pg_temp.config(),false);
SELECT pg_temp.assert_true((SELECT status='retired' FROM public.institution_appearance_assets
 WHERE id=(SELECT id FROM fixture WHERE kind='asset_background')),
 'Unreferenced former active asset becomes retired, not deleted');
SELECT pg_temp.assert_true(public.authorize_institution_appearance_asset_cleanup(
 (SELECT id FROM fixture WHERE kind='asset_background')) IS NOT NULL,
 'Retired unreferenced asset is eligible for cleanup');
SELECT pg_temp.assert_true((SELECT status='cleanup_pending'
 FROM public.institution_appearance_assets
 WHERE id=(SELECT id FROM fixture WHERE kind='asset_background')),
 'Cleanup authorization closes the activation race and remains retryable');

-- A prepared request with no object survives as a visible pending manifest.
SELECT public.prepare_institution_appearance_asset(
 (SELECT id FROM fixture WHERE kind='institution_a'),gen_random_uuid(),
 gen_random_uuid(),'element',3,'png','image/png',512,64,64,repeat('b',64));
SELECT pg_temp.assert_true((SELECT count(*)>=2 FROM
 public.list_pending_institution_appearance_assets(
   (SELECT id FROM fixture WHERE kind='institution_a'))),
 'Interrupted uploads remain discoverable as pending/retired cleanup work');

RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true);
-- Approved admin initially without an institution: bootstrap creates exactly one
-- matching link and membership and never changes an existing assignment.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM fixture WHERE kind='new_admin'),true);
SELECT public.bootstrap_institution('Appearance bootstrap') AS created_school \gset
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.institution_admins
 WHERE user_id=auth.uid() AND institution_id=:'created_school'::uuid AND is_active),
 'Bootstrap creates the authoritative admin link');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.institution_memberships
 WHERE user_id=auth.uid() AND institution_id=:'created_school'::uuid
   AND status='active' AND requested_role='institution_admin'),
 'Bootstrap creates the matching administrative membership');

ROLLBACK;
