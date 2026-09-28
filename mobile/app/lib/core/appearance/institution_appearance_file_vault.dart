import 'institution_appearance_file_vault_io.dart'
    if (dart.library.js_interop) 'institution_appearance_file_vault_web.dart';
import 'institution_appearance_pending_store.dart';

InstitutionAppearanceFileVault createInstitutionAppearanceFileVault() =>
    createPlatformInstitutionAppearanceFileVault();
