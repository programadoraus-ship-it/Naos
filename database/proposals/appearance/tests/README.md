# Appearance package tests

All SQL tests are destructive to synthetic records and must run only against a
disposable restore. `appearance_functional.sql` always ends in `ROLLBACK`.

Order:

1. Restore the already verified NAOS backup into a disposable PostgreSQL/Supabase environment.
2. Apply the previously deployed `000`, `001`, `001a`, `002`, and `003` state, or use the restored state that already contains them.
3. Apply `004_institution_appearance.sql`.
4. Run `appearance_functional.sql` as `postgres`.
5. Run the byte validator with Node 24:
   `node --experimental-strip-types supabase/functions/institution-appearance-assets/image_validation_node_test.ts`.
6. From `mobile/app`, run:
   `flutter test test/institution_appearance_config_test.dart test/institution_brand_config_mapper_test.dart test/institution_appearance_pending_store_test.dart test/institution_my_ambience_test.dart`.

The SQL suite covers two institutions, two administrators, students belonging
to different institutions, one teacher, one super-admin fixture, onboarding
activation, revision conflicts, direct-write rejection, malformed JSON and
asset-kind rejection, asset retirement, race-safe cleanup and bootstrap
membership creation.
