import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/appearance/institution_appearance_asset_gateway.dart';
import '../../../../core/appearance/institution_appearance_config.dart';
import '../../../../core/appearance/institution_appearance_finish_service.dart';
import '../../../../core/appearance/institution_appearance_file_vault.dart';
import '../../../../core/appearance/institution_appearance_pending_store.dart';
import '../../../../core/appearance/institution_appearance_repository.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/supabase/institution_admin_context.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../domain/institution_onboarding_progress.dart';
import 'institution_onboarding_background.dart';
import 'english_levels_editor.dart';
import 'courses_editor.dart';
import 'classes_editor.dart';
import 'school_structure_draft.dart';
import 'naos_tools_showcase.dart';
import 'animated_welcome.dart';
import 'institution_brand_draft.dart';
import 'institution_brand_editor.dart';
import 'institution_brand_config_mapper.dart';

@visibleForTesting
void openInstitutionDashboardAfterSetup(BuildContext context) {
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRouter.institutionAdmin, (route) => false);
}

/// NAOS — Institution onboarding
///
/// One permanent cosmic background.
/// Only the foreground content changes between steps.
///
/// Steps:
/// 0 Welcome
/// 1 NAOS introduction
/// 2 What is NAOS?
/// 3 School name
/// 4 Identity
/// 5 Location
/// 6 Build your school
/// 7 NAOS tools
/// 8 Make it yours
/// 9 Ready
class InstitutionOnboardingFlowPage extends StatefulWidget {
  const InstitutionOnboardingFlowPage({super.key});

  @override
  State<InstitutionOnboardingFlowPage> createState() =>
      _InstitutionOnboardingFlowPageState();
}

class _InstitutionOnboardingFlowPageState
    extends State<InstitutionOnboardingFlowPage>
    with SingleTickerProviderStateMixin {
  static const int _lastStep = InstitutionOnboardingProgress.lastStep;
  // Preserve persisted step IDs; legacy introduction (1) is merged into welcome.
  static const _visibleSteps = [0, 2, 3, 4, 5, 6, 7, 8, 9];

  // ==========================================================
  // ONBOARDING
  // ==========================================================

  int _step = 0;
  final _englishLevelsDraft = EnglishLevelsDraft();
  final _coursesDraft = CoursesDraft();
  late final _structure = SchoolStructureDraft(
    _englishLevelsDraft,
    _coursesDraft,
  );
  final _brandDraft = InstitutionBrandDraft();

  // ==========================================================
  // ANIMATION
  // ==========================================================

  late final AnimationController _contentController;

  // ==========================================================
  // SUPABASE / INSTITUTION
  // ==========================================================

  String? _institutionId;
  String? _institutionAdminId;

  bool _loadingInstitution = true;
  bool _advancing = false;
  bool _savingIdentity = false;
  bool _onboardingWasValidlyCompleted = false;
  String? _institutionContextError;

  InstitutionAppearanceAssetGateway? _appearanceAssetGateway;
  InstitutionAppearancePendingStore? _appearancePendingStore;
  InstitutionAppearanceFileVault? _appearanceFileVault;
  InstitutionAppearanceFinishService? _appearanceFinishService;
  LoadedInstitutionAppearance? _activeAppearance;
  PendingInstitutionAppearanceRequest? _pendingAppearanceRequest;
  String? _activeBackgroundAssetId;
  Uint8List? _activeBackgroundBytes;
  final Map<int, String> _activeElementAssetIds = {};
  final Map<int, Uint8List> _activeElementBytes = {};
  bool _savingSetup = false;
  int _uploadedAppearanceFiles = 0;
  int _totalAppearanceFiles = 0;
  String? _finishSetupError;

  Timer? _schoolNameSaveTimer;

  // ==========================================================
  // FORM CONTROLLERS
  // ==========================================================

  final TextEditingController _schoolNameController = TextEditingController();

  final TextEditingController _sloganController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedLogoBytes;
  String? _selectedLogoFileName;
  String? _savedLogoUrl;

  final TextEditingController _countryController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();

    _loadInstitution();
    _schoolNameController.addListener(_onSchoolNameChanged);
  }

  Future<void> _loadInstitution() async {
    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        debugPrint('NAOS: No authenticated user found.');

        if (mounted) {
          setState(() {
            _loadingInstitution = false;
          });
        }

        return;
      }

      debugPrint('========================================');
      debugPrint('NAOS - LOADING INSTITUTION');
      debugPrint('User ID: ${user.id}');

      // ==========================================================
      // FIND ADMIN RECORD
      // ==========================================================

      final adminContext = await InstitutionAdminContextResolver(
        SupabaseService.client,
      ).resolve(user.id);

      // ==========================================================
      // NO ADMIN RECORD
      // ==========================================================

      _institutionAdminId = adminContext.adminLinkId;
      _institutionId = adminContext.institutionId;

      debugPrint('NAOS: Institution Admin ID = $_institutionAdminId');

      debugPrint('NAOS: Institution ID = $_institutionId');

      // ==========================================================
      // ADMIN APPROVED BUT NO INSTITUTION YET
      // ==========================================================

      if (_institutionId == null || _institutionId!.isEmpty) {
        debugPrint('NAOS: Admin has NO institution yet.');

        debugPrint('NAOS: Waiting for school name to create institution.');

        // IMPORTANT:
        // Do NOT put a default school name here.
        _schoolNameController.clear();

        if (mounted) {
          setState(() {
            _loadingInstitution = false;
          });
        }

        return;
      }

      // ==========================================================
      // EXISTING INSTITUTION
      // ==========================================================

      debugPrint('NAOS: Existing institution found.');

      // ==========================================================
      // LOAD EXISTING SCHOOL NAME
      // ==========================================================

      final institutionData = await SupabaseService.client
          .from('institutions')
          .select(
            'name, slogan, description, logo_url, country, city, address, '
            'onboarding_completed, onboarding_step',
          )
          .eq('id', _institutionId!)
          .maybeSingle();

      if (institutionData == null) {
        throw Exception('The linked institution could not be found.');
      }

      final progress = InstitutionOnboardingProgress.fromValues(
        step: institutionData['onboarding_step'],
        completed: institutionData['onboarding_completed'],
      );
      _onboardingWasValidlyCompleted = progress.isCompleted;

      final savedName = institutionData['name'] as String?;

      if (savedName != null && savedName.trim().isNotEmpty) {
        _schoolNameController.text = savedName.trim();
        debugPrint('NAOS: Loaded school name = $savedName');
      }

      _sloganController.text =
          institutionData['slogan']?.toString().trim() ?? '';
      _descriptionController.text =
          institutionData['description']?.toString().trim() ?? '';
      _savedLogoUrl = institutionData['logo_url']?.toString().trim();
      _countryController.text =
          institutionData['country']?.toString().trim() ?? '';
      _cityController.text = institutionData['city']?.toString().trim() ?? '';
      _addressController.text =
          institutionData['address']?.toString().trim() ?? '';

      await _loadAppearanceState(_institutionId!);

      if (mounted) {
        setState(() {
          _institutionContextError = null;
          _step = progress.resumeStep;
          _loadingInstitution = false;
        });
        if (progress.message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(progress.message!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        }
      }

      if (_institutionId != null && _step >= 6) {
        unawaited(_structure.load(SupabaseService.client, _institutionId!));
      }

      debugPrint('NAOS: Institution loading completed.');
    } catch (e, stackTrace) {
      debugPrint('NAOS: Error loading institution: $e');

      debugPrint('$stackTrace');

      if (mounted) {
        setState(() {
          _institutionContextError = 'Could not resolve your institution: $e';
          _loadingInstitution = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not resolve your institution: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    }
  }

  Future<void> _loadAppearanceState(String institutionId) async {
    final gateway = InstitutionAppearanceAssetGateway();
    final repository = InstitutionAppearanceRepository(
      SupabaseInstitutionAppearanceBackend(SupabaseService.client),
    );
    final pendingStore = InstitutionAppearancePendingStore(
      await SharedPreferences.getInstance(),
    );
    final fileVault = createInstitutionAppearanceFileVault();
    final finishService = InstitutionAppearanceFinishService(
      backend: SupabaseInstitutionAppearanceCompletionBackend(
        client: SupabaseService.client,
        repository: repository,
        assets: gateway,
      ),
      pendingStore: pendingStore,
      fileVault: fileVault,
    );
    _appearanceAssetGateway = gateway;
    _appearancePendingStore = pendingStore;
    _appearanceFileVault = fileVault;
    _appearanceFinishService = finishService;

    final recovery = await finishService.recover(institutionId);
    final active = await repository.load(institutionId);
    _activeAppearance = active;
    _pendingAppearanceRequest = recovery.request;
    _activeBackgroundAssetId = null;
    _activeBackgroundBytes = null;
    _activeElementAssetIds.clear();
    _activeElementBytes.clear();

    final activeSelection = InstitutionBrandConfigMapper.restore(
      _brandDraft,
      active.config,
    );
    await _restoreActiveAppearanceFiles(active, activeSelection);

    final pending = recovery.request;
    if (pending != null) {
      final pendingSelection = InstitutionBrandConfigMapper.restore(
        _brandDraft,
        pending.config,
      );
      await _restorePendingAppearanceFiles(pending, pendingSelection);
      _finishSetupError =
          'A previous save is ready to retry. Its draft is locked until the request finishes.';
    }
    if (recovery.cleanupFailures > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A previous appearance cleanup is still pending. You can retry safely.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _restoreActiveAppearanceFiles(
    LoadedInstitutionAppearance active,
    RecoveredCustomAssetSelection selection,
  ) async {
    if (active.config.ambience['kind'] != 'my') return;
    final gateway = _appearanceAssetGateway!;
    final byId = {for (final asset in active.assets) asset.id: asset};
    final backgroundId = selection.backgroundAssetId;
    if (backgroundId != null && byId[backgroundId]?.signedUrl != null) {
      final asset = byId[backgroundId]!;
      final bytes = await gateway.download(asset.signedUrl!);
      _activeBackgroundAssetId = backgroundId;
      _activeBackgroundBytes = bytes;
      _brandDraft.myBackground = MyAmbienceFile(
        name: asset.storagePath.split('/').last,
        bytes: bytes,
        width: asset.width,
        height: asset.height,
        format: _formatFromMime(asset.mimeType),
      );
    }
    for (final entry in selection.elementAssetIds.entries) {
      final asset = byId[entry.value];
      if (asset?.signedUrl == null) continue;
      final bytes = await gateway.download(asset!.signedUrl!);
      _activeElementAssetIds[entry.key] = asset.id;
      _activeElementBytes[entry.key] = bytes;
      _brandDraft.myElements[entry.key] = MyAmbienceFile(
        name: asset.storagePath.split('/').last,
        bytes: bytes,
        width: asset.width,
        height: asset.height,
        format: _formatFromMime(asset.mimeType),
      );
    }
  }

  Future<void> _restorePendingAppearanceFiles(
    PendingInstitutionAppearanceRequest pending,
    RecoveredCustomAssetSelection selection,
  ) async {
    _brandDraft.myBackground = null;
    _brandDraft.myElements.clear();
    final vault = _appearanceFileVault!;
    final active = _activeAppearance;
    final activeById = {
      for (final asset
          in active?.assets ?? const <InstitutionAppearanceAsset>[])
        asset.id: asset,
    };
    final activeBackgroundId = selection.backgroundAssetId;
    if (activeBackgroundId != null &&
        activeBackgroundId == _activeBackgroundAssetId &&
        _activeBackgroundBytes != null) {
      final asset = activeById[activeBackgroundId];
      if (asset != null) {
        _brandDraft.myBackground = MyAmbienceFile(
          name: asset.storagePath.split('/').last,
          bytes: _activeBackgroundBytes!,
          width: asset.width,
          height: asset.height,
          format: _formatFromMime(asset.mimeType),
        );
      }
    }
    for (final entry in selection.elementAssetIds.entries) {
      final bytes = _activeElementBytes[entry.key];
      final asset = activeById[entry.value];
      if (_activeElementAssetIds[entry.key] == entry.value &&
          bytes != null &&
          asset != null) {
        _brandDraft.myElements[entry.key] = MyAmbienceFile(
          name: asset.storagePath.split('/').last,
          bytes: bytes,
          width: asset.width,
          height: asset.height,
          format: _formatFromMime(asset.mimeType),
        );
      }
    }
    for (final asset in pending.assets) {
      final bytes = await vault.read(asset.localPath);
      final file = MyAmbienceFile(
        name: asset.fileName,
        bytes: bytes,
        width: asset.width,
        height: asset.height,
        format: asset.format,
      );
      if (asset.kind == 'background' &&
          selection.backgroundAssetId == asset.id) {
        _brandDraft.myBackground = file;
      } else if (asset.kind == 'element' &&
          selection.elementAssetIds[asset.slot] == asset.id) {
        _brandDraft.myElements[asset.slot] = file;
      }
    }
  }

  String _formatFromMime(String mime) => switch (mime) {
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    _ => 'png',
  };
  // ==========================================================
  // LOAD CURRENT ADMIN'S INSTITUTION
  // ==========================================================

  // ==========================================================
  // SCHOOL NAME CHANGED
  // ==========================================================

  void _onSchoolNameChanged() {
    if (_loadingInstitution) {
      return;
    }

    _schoolNameSaveTimer?.cancel();

    _schoolNameSaveTimer = Timer(
      const Duration(milliseconds: 700),
      _saveSchoolName,
    );
  }

  // ==========================================================
  // SAVE SCHOOL NAME
  // ==========================================================

  Future<bool>? _schoolNameSave;

  Future<bool> _saveSchoolName() {
    _schoolNameSaveTimer?.cancel();
    final pending = _schoolNameSave;
    if (pending != null) return pending;
    final future = _persistSchoolName();
    _schoolNameSave = future;
    return future.whenComplete(() {
      _schoolNameSave = null;
    });
  }

  Future<bool> _persistSchoolName() async {
    try {
      // A name edited while saving must also be persisted before Continue.
      while (true) {
        final schoolName = _schoolNameController.text.trim();
        if (schoolName.isEmpty) throw Exception('School name is required.');
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) throw Exception('No authenticated user.');

        if (_institutionId == null || _institutionId!.isEmpty) {
          final result = await SupabaseService.client.rpc(
            'bootstrap_institution',
            params: {'p_name': schoolName},
          );
          if (result is! String ||
              !RegExp(
                r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
              ).hasMatch(result)) {
            throw Exception('Bootstrap returned an invalid institution ID.');
          }
          final relation = await SupabaseService.client
              .from('institution_admins')
              .select('id')
              .eq('user_id', user.id)
              .eq('institution_id', result)
              .eq('is_active', true)
              .single();
          // Do not expose an unverified/partially loaded relation to next steps.
          _institutionId = result;
          _institutionAdminId = relation['id'] as String;
        }

        // Also covers a retry after a committed bootstrap whose response was lost.
        final updated = await SupabaseService.client
            .from('institutions')
            .update({'name': schoolName})
            .eq('id', _institutionId!)
            .select('id, name')
            .maybeSingle();
        if (updated == null) throw Exception('Institution was not updated.');
        if (!mounted) return false;
        if (_schoolNameController.text.trim() == schoolName) return true;
      }
    } catch (e, stackTrace) {
      debugPrint('NAOS: SCHOOL NAME SAVE ERROR: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your school name. Please try again.'),
          ),
        );
      }
      return false;
    }
  }

  // ==========================================================
  // LOGO PICKER
  // ==========================================================

  Future<void> _pickLogo() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    final extension = pickedFile.name.split('.').last.toLowerCase();

    const allowedExtensions = {'png', 'jpg', 'jpeg', 'webp'};

    if (!allowedExtensions.contains(extension)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a PNG, JPG, JPEG, or WebP logo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final bytes = await pickedFile.readAsBytes();

    if (!mounted) return;

    setState(() {
      _selectedLogoBytes = bytes;
      _selectedLogoFileName = pickedFile.name;
    });
  }

  // ==========================================================
  // SAVE IDENTITY
  // ==========================================================

  Future<bool> _saveIdentity() async {
    final institutionId = _institutionId;

    if (institutionId == null || institutionId.isEmpty) {
      _showIdentitySaveError(
        'Please save your school name before adding its identity.',
      );
      return false;
    }

    if (_savingIdentity) {
      return false;
    }

    _savingIdentity = true;

    try {
      String? logoUrl;

      if (_selectedLogoBytes != null && _selectedLogoFileName != null) {
        final extension = _selectedLogoFileName!.split('.').last.toLowerCase();
        final logoPath = '$institutionId/logo.$extension';

        await SupabaseService.client.storage
            .from('institution-logos')
            .uploadBinary(
              logoPath,
              _selectedLogoBytes!,
              fileOptions: FileOptions(
                contentType: _logoContentType(extension),
                upsert: true,
                cacheControl: '0',
              ),
            );

        final publicUrl = SupabaseService.client.storage
            .from('institution-logos')
            .getPublicUrl(logoPath);
        logoUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      }

      final identity = <String, dynamic>{
        'slogan': _sloganController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      if (logoUrl != null) {
        identity['logo_url'] = logoUrl;
        _savedLogoUrl = logoUrl;
      }

      final updatedInstitution = await SupabaseService.client
          .from('institutions')
          .update(identity)
          .eq('id', institutionId)
          .select('id')
          .maybeSingle();

      if (updatedInstitution == null) {
        throw Exception('Institution identity was not updated.');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('NAOS: IDENTITY SAVE ERROR: $e');
      debugPrint('$stackTrace');
      _showIdentitySaveError('Could not save your school identity.');
      return false;
    } finally {
      _savingIdentity = false;
    }
  }

  String _logoContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  void _showIdentitySaveError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================================
  // SAVE LOCATION
  // ==========================================================

  Future<bool> _saveLocation() async {
    final institutionId = _institutionId;

    if (institutionId == null || institutionId.isEmpty) {
      _showLocationSaveError('Could not find your institution.');
      return false;
    }

    try {
      final updatedInstitution = await SupabaseService.client
          .from('institutions')
          .update({
            'country': _countryController.text.trim(),
            'city': _cityController.text.trim(),
            'address': _addressController.text.trim(),
          })
          .eq('id', institutionId)
          .select('id')
          .maybeSingle();

      if (updatedInstitution == null) {
        throw Exception('Institution location was not updated.');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('NAOS: LOCATION SAVE ERROR: $e');
      debugPrint('$stackTrace');
      _showLocationSaveError('Could not save your school location.');
      return false;
    }
  }

  void _showLocationSaveError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================================
  // NEXT
  // ==========================================================

  Future<void> _next() async {
    if (_advancing) return;
    _advancing = true;
    try {
      // --------------------------------------------------------
      // STEP 3 — SCHOOL NAME
      // --------------------------------------------------------

      if (_step == 3 && !await _saveSchoolName()) {
        return;
      }

      // --------------------------------------------------------
      // STEP 4 — IDENTITY
      // --------------------------------------------------------

      if (_step == 4 && !await _saveIdentity()) {
        return;
      }

      // --------------------------------------------------------
      // STEP 5 — LOCATION
      // --------------------------------------------------------

      if (_step == 5 && !await _saveLocation()) {
        return;
      }
      if (_step == 6 &&
          (_institutionId == null ||
              !await _structure.save(
                SupabaseService.client,
                _institutionId!,
              ))) {
        return;
      }

      if (_step == 8) {
        await _finish();
        return;
      }

      // --------------------------------------------------------
      // FINISH
      // --------------------------------------------------------

      if (_step >= _lastStep) {
        await _finish();
        return;
      }

      // --------------------------------------------------------
      // SAVE NEXT STEP
      // --------------------------------------------------------

      final nextStep = _step == 0 ? 2 : _step + 1;

      if (!await _saveOnboardingStep(nextStep)) {
        return;
      }

      if (!mounted) return;

      _changeStep(nextStep);
    } finally {
      _advancing = false;
    }
  }

  // ==========================================================
  // SAVE ONBOARDING STEP
  // ==========================================================

  Future<bool> _saveOnboardingStep(int step) async {
    final institutionId = _institutionId;

    if (institutionId == null || institutionId.isEmpty) {
      // A newly approved administrator reaches School name before the
      // institution exists. Those introductory transitions are local only.
      if (step <= 3) {
        return true;
      }
      _showProgressSaveError();
      return false;
    }

    // A fully completed school may revisit previous screens to edit its data.
    // Navigating inside that editor must not downgrade completion or step 9.
    if (_onboardingWasValidlyCompleted) {
      return true;
    }

    try {
      final updated = await SupabaseService.client
          .from('institutions')
          .update({'onboarding_step': step, 'onboarding_completed': false})
          .eq('id', institutionId)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw Exception('The onboarding progress was not updated.');
      }

      debugPrint('Onboarding step saved: $step');
      return true;
    } catch (e, stackTrace) {
      debugPrint('ONBOARDING STEP SAVE ERROR: $e');
      debugPrint('$stackTrace');
      _showProgressSaveError();
      return false;
    }
  }

  void _showProgressSaveError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not save your onboarding progress. Please try again.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // CHANGE STEP
  // ==========================================================

  void _changeStep(int nextStep) {
    if (nextStep == 1) nextStep = 0;
    if (nextStep < 0 || nextStep > _lastStep || nextStep == _step) {
      return;
    }

    _contentController.reset();

    setState(() {
      _step = nextStep;
    });

    _contentController.forward();
    if (nextStep == 6 && _institutionId != null) {
      unawaited(_structure.load(SupabaseService.client, _institutionId!));
    }
  }

  // ==========================================================
  // BACK
  // ==========================================================

  void _back() {
    if (_advancing || _schoolNameSave != null) return;
    if (_step <= 0) {
      return;
    }

    _changeStep(_step == 2 ? 0 : _step - 1);
  }

  // ==========================================================
  // FINISH
  // ==========================================================

  Future<void> _finish() async {
    final institutionId = _institutionId;
    final service = _appearanceFinishService;
    final active = _activeAppearance;
    if (_savingSetup ||
        institutionId == null ||
        institutionId.isEmpty ||
        service == null ||
        active == null) {
      return;
    }
    setState(() {
      _savingSetup = true;
      _finishSetupError = null;
      _uploadedAppearanceFiles = 0;
      _totalAppearanceFiles = 0;
    });
    try {
      final localFiles = <LocalAppearanceUpload>[];
      String? retainedBackgroundId;
      final retainedElementIds = <int, String>{};
      if (_brandDraft.ambience == InstitutionAmbience.my) {
        final background = _brandDraft.myBackground;
        if (background != null &&
            _activeBackgroundAssetId != null &&
            listEquals(background.bytes, _activeBackgroundBytes)) {
          retainedBackgroundId = _activeBackgroundAssetId;
        } else if (background != null) {
          localFiles.add(
            LocalAppearanceUpload(
              kind: 'background',
              slot: 0,
              fileName: background.name,
              bytes: background.bytes,
              width: background.width,
              height: background.height,
              format: background.format,
            ),
          );
        }
        for (final entry in _brandDraft.myElements.entries) {
          final activeBytes = _activeElementBytes[entry.key];
          final activeId = _activeElementAssetIds[entry.key];
          if (activeId != null && listEquals(entry.value.bytes, activeBytes)) {
            retainedElementIds[entry.key] = activeId;
          } else {
            localFiles.add(
              LocalAppearanceUpload(
                kind: 'element',
                slot: entry.key,
                fileName: entry.value.name,
                bytes: entry.value.bytes,
                width: entry.value.width,
                height: entry.value.height,
                format: entry.value.format,
              ),
            );
          }
        }
      }
      final result = await service.finish(
        expectedInstitutionId: institutionId,
        expectedRevision: active.revision,
        localFiles: localFiles,
        buildConfig: (backgroundId, elementIds) =>
            InstitutionBrandConfigMapper.encode(
              _brandDraft,
              customBackgroundAssetId: backgroundId ?? retainedBackgroundId,
              customElementAssetIds: {...retainedElementIds, ...elementIds},
            ),
        onUploadProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _uploadedAppearanceFiles = completed;
            _totalAppearanceFiles = total;
          });
        },
      );
      _activeAppearance = result.appearance;
      _pendingAppearanceRequest = null;
      _onboardingWasValidlyCompleted = true;
      debugPrint('ONBOARDING COMPLETED');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your NAOS setup is ready. ✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      openInstitutionDashboardAfterSetup(context);
    } on InstitutionAppearanceFinishException catch (e) {
      debugPrint('ONBOARDING FINISH ERROR: $e');
      if (!mounted) return;
      setState(() {
        _pendingAppearanceRequest = _appearancePendingStore?.load(
          institutionId,
        );
        _finishSetupError = e.cleanupPending
            ? '${e.message} File cleanup will resume next time.'
            : e.message;
      });
    } catch (e, stackTrace) {
      debugPrint('ONBOARDING FINISH ERROR: $e');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() {
          _finishSetupError =
              'Your school could not be saved. Your draft is safe.';
        });
      }
    } finally {
      if (mounted) setState(() => _savingSetup = false);
    }
  }

  // ==========================================================
  // BUTTON LABEL
  // ==========================================================

  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'Begin the journey';

      case 1:
        return 'Continue';

      case 2:
        return "Let's build it";

      case 3:
      case 4:
        return 'Continue';

      case 5:
        return 'Build my school';

      case 6:
        return 'Continue';

      case 7:
        return 'Make it yours';

      case 8:
        return 'Finish setup';

      case 9:
        return 'Enter NAOS';

      default:
        return 'Continue';
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_savingSetup,
      child: Scaffold(
        backgroundColor: const Color(0xFF020514),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ----------------------------------------------------
            // COSMIC BACKGROUND
            // ----------------------------------------------------
            const Positioned.fill(child: InstitutionOnboardingBackground()),

            // ----------------------------------------------------
            // CONTENT
            // ----------------------------------------------------
            SafeArea(
              child: AbsorbPointer(
                absorbing: _savingSetup,
                child: AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    final value = Curves.easeOutCubic.transform(
                      _contentController.value,
                    );

                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide =
                          Tween<Offset>(
                            begin: const Offset(0, 0.025),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_step),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------
            // BACK BUTTON
            // ----------------------------------------------------
            if (!_loadingInstitution &&
                _institutionContextError == null &&
                _step > 0 &&
                !_savingSetup)
              Positioned(
                top: 14,
                left: 14,
                child: SafeArea(child: _buildBackButton()),
              ),

            // ----------------------------------------------------
            // STEP INDICATOR
            // ----------------------------------------------------
            if (!_loadingInstitution && _institutionContextError == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: SafeArea(child: _buildStepIndicator()),
              ),
            if (_savingSetup)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xCC020514),
                  child: Center(
                    child: Container(
                      width: 360,
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10173D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF7770FF)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF8077FF),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Saving your school…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_totalAppearanceFiles > 0) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Uploading $_uploadedAppearanceFiles of '
                              '$_totalAppearanceFiles files',
                              style: const TextStyle(color: Color(0xFFC5C9EE)),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value:
                                  _uploadedAppearanceFiles /
                                  _totalAppearanceFiles,
                              color: const Color(0xFF8077FF),
                              backgroundColor: Colors.white12,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CURRENT STEP
  // ==========================================================

  Widget _buildCurrentStep() {
    if (_loadingInstitution) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8077FF)),
      );
    }

    final contextError = _institutionContextError;
    if (contextError != null) {
      return _contentShell(
        maxWidth: 680,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xE60B1235),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B86FF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFFB4AB),
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Institution link needs review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                contextError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD5D8F5),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No institution was selected or changed automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAEB4D8), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    switch (_step) {
      case 0:
        return _buildWelcome();

      case 1:
        return _buildWelcome();

      case 2:
        return _buildWhatIsNaos();

      case 3:
        return _buildSchoolName();

      case 4:
        return _buildIdentity();

      case 5:
        return _buildLocation();

      case 6:
        return _buildBuildSchool();

      case 7:
        return _buildTools();

      case 8:
        return _buildMakeItYours();

      case 9:
        return _buildReady();

      default:
        return _buildWelcome();
    }
  }

  // ==========================================================
  // STEP 0 — WELCOME
  // ==========================================================

  Widget _buildWelcome() {
    return _contentShell(
      maxWidth: 820,
      child: AnimatedWelcome(
        children: [
          const Text(
            'WELCOME, ADMINISTRATOR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAEB5FF),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.3,
            ),
          ),

          const SizedBox(height: 16),

          _buildNaosLogo(size: 112),

          const SizedBox(height: 18),

          const Text(
            'NAOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 7,
              height: 1,
            ),
          ),

          const SizedBox(height: 10),

          _mutedText(
            'Your school is about to become a universe.',
            fontSize: 16,
            weight: FontWeight.w600,
          ),

          const SizedBox(height: 28),

          _buildGlassCard(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B82FF), Color(0xFF5B58FF)],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Today you’re taking a big step',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'toward building your school.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB7BDFF),
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'NAOS will guide you through the foundations '
                  'of your academy, one step at a time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.43),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11183B).withOpacity(0.52),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6975E8).withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildSmallIcon(Icons.rocket_launch_rounded, size: 42),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your journey starts here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'School identity • Location • Structure • Design',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.38),
                                fontSize: 10.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _buildPrimaryButton(
            label: _buttonLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),

          const SizedBox(height: 12),

          Text(
            'Let’s build something extraordinary.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.26),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 2 — WHAT IS NAOS
  // ==========================================================

  Widget _buildWhatIsNaos() {
    return _contentShell(
      maxWidth: 820,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNaosLogo(size: 82),

          const SizedBox(height: 18),

          const Text(
            'WHAT IS NAOS?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 37,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              height: 1.05,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'NAOS is your school’s\nvirtual universe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB8BEFF),
              fontSize: 25,
              height: 1.22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: _mutedText(
              'A single place where your academy can grow, '
              'connect people, organize learning and bring '
              'everything together.',
              fontSize: 13.5,
            ),
          ),

          const SizedBox(height: 27),

          _buildGlassCard(
            child: Column(
              children: [
                _buildConcept(
                  Icons.school_rounded,
                  'Your school',
                  'Your academy becomes the center.',
                ),

                const SizedBox(height: 12),

                _buildConcept(
                  Icons.people_alt_rounded,
                  'Your community',
                  'Students, teachers and administrators.',
                ),

                const SizedBox(height: 12),

                _buildConcept(
                  Icons.auto_graph_rounded,
                  'Your growth',
                  'Everything connected in one universe.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 27),

          _buildPrimaryButton(
            label: _buttonLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 3 — SCHOOL NAME
  // ==========================================================

  Widget _buildSchoolName() {
    return _formShell(
      eyebrow: 'LET’S BUILD IT',
      title: 'What is your school called?',
      subtitle: 'Start by giving your school a name.',
      child: _buildInput(
        controller: _schoolNameController,
        label: 'School name',
        hint: 'Enter your institution name',
        icon: Icons.school_rounded,
      ),
      buttonLabel: _buttonLabel,
    );
  }

  // ==========================================================
  // STEP 4 — IDENTITY
  // ==========================================================

  Widget _buildIdentity() {
    return _formShell(
      eyebrow: 'GIVE IT AN IDENTITY',
      title: 'Make it feel like your school.',
      subtitle: 'Add the details that define your academy.',
      child: Column(
        children: [
          _buildInput(
            controller: _sloganController,
            label: 'Slogan',
            hint: 'Learn. Grow. Connect.',
            icon: Icons.format_quote_rounded,
          ),

          const SizedBox(height: 12),

          _buildInput(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Tell students what makes your school special.',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          _buildLogoPicker(),
        ],
      ),
      buttonLabel: _buttonLabel,
    );
  }

  // ==========================================================
  // LOGO PICKER
  // ==========================================================

  Widget _buildLogoPicker() {
    final hasLogo = _selectedLogoBytes != null;
    final savedLogoUrl = _savedLogoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo',
          style: TextStyle(color: Color(0xFF9EA5D6), fontSize: 13),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0x6610183C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3C478B).withOpacity(0.5)),
          ),
          child: hasLogo
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.memory(_selectedLogoBytes!, fit: BoxFit.contain),
                )
              : savedLogoUrl != null && savedLogoUrl.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    savedLogoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildEmptyLogoPlaceholder(),
                  ),
                )
              : _buildEmptyLogoPlaceholder(),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _pickLogo,
          icon: Icon(
            hasLogo || (savedLogoUrl != null && savedLogoUrl.isNotEmpty)
                ? Icons.swap_horiz_rounded
                : Icons.upload_rounded,
          ),
          label: Text(
            hasLogo || (savedLogoUrl != null && savedLogoUrl.isNotEmpty)
                ? 'Change logo'
                : 'Upload logo',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB9BFFF),
            side: const BorderSide(color: Color(0xFF6570D8)),
          ),
        ),

        if (_selectedLogoFileName != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedLogoFileName!,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyLogoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: Color(0xFF9FA7FF),
          size: 34,
        ),
        SizedBox(height: 8),
        Text(
          'PNG, JPG, or WebP',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  // ==========================================================
  // STEP 5 — LOCATION
  // ==========================================================

  Widget _buildLocation() {
    return _formShell(
      eyebrow: 'WHERE IS IT?',
      title: 'Where is your school located?',
      subtitle: 'Add your academy’s location.',
      child: Column(
        children: [
          _buildInput(
            controller: _countryController,
            label: 'Country',
            hint: 'Australia',
            icon: Icons.public_rounded,
          ),

          const SizedBox(height: 12),

          _buildInput(
            controller: _cityController,
            label: 'City',
            hint: 'Sydney',
            icon: Icons.location_city_rounded,
          ),

          const SizedBox(height: 12),

          _buildInput(
            controller: _addressController,
            label: 'Address',
            hint: 'School address',
            icon: Icons.place_outlined,
          ),
        ],
      ),
      buttonLabel: _buttonLabel,
    );
  }

  // ==========================================================
  // STEP 6 — BUILD YOUR SCHOOL
  // ==========================================================

  Widget _buildBuildSchool() {
    return ListenableBuilder(
      listenable: _structure,
      builder: (context, _) => _contentShell(
        maxWidth: 820,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNaosLogo(size: 72),

            const SizedBox(height: 14),

            const Text(
              'BUILD YOUR SCHOOL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            _mutedText(
              'Create the learning structure your academy will use.',
              fontSize: 14,
            ),

            const SizedBox(height: 24),

            if (_structure.busy) const LinearProgressIndicator(),
            if (_structure.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _structure.error!,
                  style: const TextStyle(color: Colors.amberAccent),
                ),
              ),
            if (_structure.error != null &&
                _structure.loaded &&
                !_structure.busy)
              TextButton(
                onPressed: () async {
                  final discard = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reload saved structure?'),
                      content: const Text(
                        'This discards your unsaved draft only after the saved structure loads successfully.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep draft'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reload'),
                        ),
                      ],
                    ),
                  );
                  if (discard == true && mounted && _institutionId != null) {
                    await _structure.load(
                      SupabaseService.client,
                      _institutionId!,
                      discardConfirmed: true,
                    );
                  }
                },
                child: const Text('Reload saved version…'),
              ),
            if (!_structure.loaded && !_structure.busy)
              TextButton(
                onPressed: () {
                  if (_institutionId != null)
                    _structure.load(SupabaseService.client, _institutionId!);
                },
                child: const Text('Retry loading structure'),
              ),
            if (_structure.loaded)
              AbsorbPointer(
                absorbing: _structure.busy,
                child: _buildGlassCard(
                  child: Column(
                    children: [
                      _buildProgressRow(
                        number: '01',
                        title: 'English Levels',
                        description:
                            'Define the levels your students can take.',
                      ),

                      const SizedBox(height: 16),
                      EnglishLevelsEditor(
                        draft: _englishLevelsDraft,
                        connected: true,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: Color(0x336D67BA), height: 1),
                      ),

                      _buildProgressRow(
                        number: '02',
                        title: 'Courses',
                        description: 'Organize your academy into courses.',
                      ),

                      const SizedBox(height: 16),
                      CoursesEditor(draft: _coursesDraft, connected: true),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: Color(0x336D67BA), height: 1),
                      ),

                      _buildProgressRow(
                        number: '03',
                        title: 'Classes',
                        description:
                            'Create the classes that deliver each course.',
                      ),
                      const SizedBox(height: 16),
                      ClassesEditor(draft: _structure),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 26),

            _buildPrimaryButton(
              label: _buttonLabel,
              icon: Icons.arrow_forward_rounded,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STEP 7 — TOOLS
  // ==========================================================

  Widget _buildTools() {
    return _contentShell(
      maxWidth: 920,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'YOUR NAOS TOOLS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          _mutedText(
            'Everything you need to manage your academy.',
            fontSize: 14,
          ),

          const SizedBox(height: 24),

          _buildGlassCard(child: const NaosToolsShowcase()),

          const SizedBox(height: 26),

          _buildPrimaryButton(
            label: _buttonLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 8 — MAKE IT YOURS
  // ==========================================================

  Widget _buildMakeItYours() {
    return _contentShell(
      maxWidth: 1120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNaosLogo(size: 70),

          const SizedBox(height: 14),

          const Text(
            'MAKE IT YOURS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          _mutedText(
            'Choose the visual language of your academy.',
            fontSize: 14,
          ),

          const SizedBox(height: 24),

          AbsorbPointer(
            absorbing: _pendingAppearanceRequest != null,
            child: InstitutionBrandEditor(
              draft: _brandDraft,
              institutionName: _schoolNameController.text,
              logoBytes: _selectedLogoBytes,
              logoUrl: _savedLogoUrl,
            ),
          ),

          const SizedBox(height: 26),

          if (_finishSetupError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x33FF6B7A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x99FF8792)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFFB4BA)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _finishSetupError!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: _savingSetup ? null : _finish,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          _buildPrimaryButton(
            label: _savingSetup ? 'Saving your school…' : _buttonLabel,
            icon: Icons.check_rounded,
            onPressed: _savingSetup ? null : _next,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 9 — READY
  // ==========================================================

  Widget _buildReady() {
    return _contentShell(
      maxWidth: 760,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNaosLogo(size: 104),

          const SizedBox(height: 22),

          const Text(
            'YOUR SCHOOL IS READY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'This is just the beginning.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB8BEFF),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          _mutedText(
            'Your academy has a universe. Now it is time to build it.',
            fontSize: 14,
          ),

          const SizedBox(height: 24),

          _buildGlassCard(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  color: Color(0xFFB8BEFF),
                  size: 24,
                ),

                SizedBox(width: 12),

                Text(
                  'Here begins the adventure.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          _buildPrimaryButton(
            label: _buttonLabel,
            icon: Icons.rocket_launch_rounded,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SHARED CONTENT
  // ==========================================================

  Widget _contentShell({required double maxWidth, required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 58, 24, 84),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }

  // ==========================================================
  // FORM SHELL
  // ==========================================================

  Widget _formShell({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
    required String buttonLabel,
  }) {
    return _contentShell(
      maxWidth: 760,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNaosLogo(size: 70),

          const SizedBox(height: 16),

          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFAEB5FF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 10),

          _mutedText(subtitle, fontSize: 14),

          const SizedBox(height: 24),

          _buildGlassCard(child: child),

          const SizedBox(height: 24),

          _buildPrimaryButton(
            label: buttonLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // NAOS LOGO
  // ==========================================================

  Widget _buildNaosLogo({double size = 82}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF8B82FF), Color(0xFF5147D9), Color(0xFF24225D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6860FF).withOpacity(0.40),
            blurRadius: size * 0.55,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  // ==========================================================
  // GLASS CARD
  // ==========================================================

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xCC080F2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5B65D9).withOpacity(0.38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  // ==========================================================
  // MESSAGE CARD
  // ==========================================================

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF242A68),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6C73FF).withOpacity(0.5),
              ),
            ),
            child: Icon(icon, color: const Color(0xFFB9BFFF), size: 26),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFAEB5FF),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CONCEPT
  // ==========================================================

  Widget _buildConcept(IconData icon, String title, String description) {
    return Row(
      children: [
        _buildSmallIcon(icon),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                description,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PROGRESS ROW
  // ==========================================================

  Widget _buildProgressRow({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B245A),
            border: Border.all(
              color: const Color(0xFF6972FF).withOpacity(0.45),
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFFB8BEFF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                description,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TOOL CARD
  // ==========================================================

  Widget _buildToolCard(IconData icon, String title) {
    return Container(
      width: 190,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0x66131B46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B4488).withOpacity(0.45)),
      ),
      child: Row(
        children: [
          _buildSmallIcon(icon, size: 40),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INPUT
  // ==========================================================

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: const Color(0xFF8A83FF),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF9EA5D6)),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: const Color(0xFF9FA7FF), size: 21),
        filled: true,
        fillColor: const Color(0x6610183C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF3C478B).withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF3C478B).withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF747BFF), width: 1.4),
        ),
      ),
    );
  }

  // ==========================================================
  // PILL
  // ==========================================================

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x66151E4C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF414B92).withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFABB1FF), size: 17),

          const SizedBox(width: 7),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WELCOME FEATURE
  // ==========================================================

  Widget _buildWelcomeFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF11183B).withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6975E8).withOpacity(0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallIcon(icon, size: 42),

          const SizedBox(height: 9),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.40),
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SMALL ICON
  // ==========================================================

  Widget _buildSmallIcon(IconData icon, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF202960),
        border: Border.all(color: const Color(0xFF6570D8).withOpacity(0.4)),
      ),
      child: Icon(icon, color: const Color(0xFFB5BBFF), size: size * 0.48),
    );
  }

  // ==========================================================
  // PRIMARY BUTTON
  // ==========================================================

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 285,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8077FF), Color(0xFF5B58FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF665FFF).withOpacity(0.35),
                blurRadius: 26,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(width: 12),

              Icon(icon, color: Colors.white, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BACK BUTTON
  // ==========================================================

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _back,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xAA0A1130),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF414B92).withOpacity(0.55),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 18),

              SizedBox(width: 6),

              Text(
                'Back',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STEP INDICATOR
  // ==========================================================

  Widget _buildStepIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final i in _visibleSteps) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == _step ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _step ? const Color(0xFF8077FF) : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              if (i != _lastStep) const SizedBox(width: 6),
            ],
          ],
        ),

        const SizedBox(height: 7),

        Text(
          'Step ${_visibleSteps.indexOf(_step) + 1} of ${_visibleSteps.length}',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // MUTED TEXT
  // ==========================================================

  Widget _mutedText(
    String text, {
    double fontSize = 14,
    FontWeight weight = FontWeight.w500,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFFADB4D5),
        fontSize: fontSize,
        height: 1.45,
        fontWeight: weight,
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _appearanceAssetGateway?.close();
    _structure.dispose();
    _brandDraft.dispose();
    _englishLevelsDraft.dispose();
    _coursesDraft.dispose();
    _schoolNameSaveTimer?.cancel();

    _schoolNameController.removeListener(_onSchoolNameChanged);

    _contentController.dispose();

    _schoolNameController.dispose();
    _sloganController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();

    super.dispose();
  }
}
