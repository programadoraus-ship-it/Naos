# Institution appearance deployment review

Status: local candidate only. Nothing in this folder has been applied to the
Supabase project.

## Exact remote package

1. Apply `004_institution_appearance.sql` as `postgres` in one transaction.
   Its preflight stops before writes unless migrations 000–003, the expected
   `institutions` columns, and the required RPCs exist. It also stops if either
   new table or the bucket already exists.
2. Verify the two tables, bucket, RLS, function ACLs, trigger guards and the
   replacement definition of `bootstrap_institution(text)`.
3. Deploy `supabase/functions/institution-appearance-assets` with JWT
   verification enabled. It additionally resolves the caller with
   `auth.getUser()` and uses the service role only after the caller RPC has
   authorized the institution and request.
4. Run an authenticated smoke test with development accounts from two
   institutions. Flutter is not published by this package.

If step 1 fails, PostgreSQL rolls the whole migration back. If Edge deployment
fails after step 1, existing NAOS behavior is unchanged: no appearance row is
backfilled, dashboards keep using the legacy columns, and the private bucket
has no client write policy. Fix or remove the function deployment and retry.

## Schema and compatibility

- `institution_appearances`: exactly one active configuration per institution,
  schema version 1, optimistic `revision`, idempotent `last_request_id`, updater
  and timestamp.
- `institution_appearance_assets`: one manifest per uploaded object with
  institution, request, kind, slot, stable Storage path, verified metadata,
  SHA-256 and lifecycle (`pending`, `active`, `retired`, `cleanup_pending`).
- There is no backfill. An institution without an appearance row gets the safe
  Flutter fallback assembled from existing `template`, `theme_color`,
  `font_style` and `button_style` columns.
- Activation synchronizes those four legacy columns for compatibility.
- Only `activate_institution_appearance(...)` can change the active config or
  finish onboarding. With `p_complete_onboarding=true`, the same transaction
  writes the config/assets and sets step 9/completed. It requires an unfinished
  institution at step 8 with name, timezone and saved structure.

## JSON limit and validation

The maximum is **262,144 UTF-8 bytes (256 KiB)**, enforced independently in
Flutter and PostgreSQL. Schema v1 validates:

- the nine template IDs, ten local font IDs and six motion values;
- button shape and finish;
- four HEX RGB colors, saturation/lightness in 0–1 and transparency in 0–100;
- ambience, its valid selected scene, stable maps for student/teacher/admin,
  focal points for Mobile/Desktop and the three ambience controls;
- at most five distinct custom element IDs, slots 0–4 and their correspondence;
- custom asset references only for `my`, correct background/element kinds,
  same institution/request, and an object with matching size/MIME in Storage;
- decoration override data as an object. Unknown version-1 top-level fields are
  retained for forward-compatible v1 additions, but required structure cannot
  be omitted.

## Private Storage

Bucket: `institution-appearance`, private, 5 MiB bucket-level limit, PNG/JPEG/
WebP MIME allowlist. Stable object paths are:

```
<institutionId>/requests/<requestId>/background.<ext>
<institutionId>/requests/<requestId>/elements/<assetId>.<ext>
```

The Edge validator narrows these rules:

- background: PNG/JPEG/WebP, <= 5 MiB, each dimension 180–4096 px;
- element: PNG/WebP with alpha channel, <= 2 MiB, each dimension 16–2048 px;
- byte signatures, filename extension, dimensions and static encoding are
  checked; animated PNG/WebP and falsified types are rejected.

Authenticated clients receive only a Storage SELECT policy, scoped by the
first UUID folder and `can_read_institution_appearance`. There is deliberately
no client INSERT/UPDATE/DELETE policy. Upload/removal uses the Edge Function's
service role only after `can_manage_institution_appearance` has confirmed one
coherent active admin link plus membership, or a super admin.

## Pending recovery and safe cleanup

Flutter persists request ID, expected revision, validated JSON and asset IDs in
local preferences before the coordinated save. It does not persist file bytes
or signed URLs. On restart it combines that record with
`list_pending_institution_appearance_assets`:

- an already uploaded object is reused by stable ID/checksum;
- a file that never reached Storage must be selected again;
- activation is idempotent by request ID and conflicts on stale revision;
- the previous active configuration remains active until activation commits;
- the local record is cleared only after successful activation.

Pending and retired manifests survive a closed app or lost connection and are
listed for retry/cleanup. Cleanup first changes the row to `cleanup_pending` in
a locked transaction. Activation rejects that status, closing the race between
authorization and object deletion. A failed removal remains retryable. The
manifest is deleted only after Storage confirms the object is gone. Active or
still-referenced assets are always rejected by the cleanup RPC.

## Signed URLs

The database stores only private Storage paths. Flutter requests one-hour
signed URLs, caches them only in memory and renews after 50 minutes. Sign-out or
explicit cache clearing removes the cache; a new device simply obtains new
signed URLs after the institution-scoped read RPC.

## `bootstrap_institution()` change

The replacement preserves all reviewed eligibility, ambiguity and conflict
checks. It returns an existing linked institution unchanged. Only when an
approved active admin has no institution does it create the institution, link
the existing/new `institution_admins` row and insert the matching active
`institution_memberships` row in the same transaction. It never reassigns an
existing institution or repairs conflicting data automatically.

## Local verification performed

- Restored the verified backup into disposable PostgreSQL 17. The only restore
  omissions were the three expected `supabase_vault` statements unavailable in
  portable PostgreSQL; the required NAOS/Auth/Storage schema restored.
- Reapplied 000, 001, 001a, 002, 003 and 004 in order. The historical copied
  ineligible admin link was disabled only in the disposable database so that
  the already-reviewed preflight matched current development state.
- SQL functional test passed and rolled back: two institutions, two admins,
  cross-institution rejection, student/teacher reads, super-admin access,
  transactional onboarding completion, revision conflict, malformed JSON,
  kind mismatch, asset activation/retirement, race-safe cleanup, interrupted
  upload recovery and bootstrap membership creation.
- Edge byte-validator test passed; Node TypeScript syntax check passed.
- Flutter targeted analysis passed with no issues. Twelve affected tests passed
  for fallback, JSON validation, signed URL renewal, pending recovery, mapper
  round-trip, custom slots/focal points and My ambience behavior.
- Full-project `flutter analyze` completed with 60 existing warnings/info items
  outside this persistence package; it introduced no targeted analyzer error.

The full deployed Edge HTTP/Storage integration cannot be executed against the
portable PostgreSQL process because it has no Supabase Auth/Storage API. That
smoke test is the first post-deployment validation and uses development test
accounts only.
