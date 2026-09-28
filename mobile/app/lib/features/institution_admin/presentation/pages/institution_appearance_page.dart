import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/appearance/institution_appearance_asset_gateway.dart';
import '../../../../core/appearance/institution_appearance_config.dart';
import '../../../../core/appearance/institution_appearance_file_vault.dart';
import '../../../../core/appearance/institution_appearance_finish_service.dart';
import '../../../../core/appearance/institution_appearance_pending_store.dart';
import '../../../../core/appearance/institution_appearance_repository.dart';
import '../../../../core/services/supabase/institution_admin_context.dart';
import '../../../institution_onboarding/presentation/pages/institution_brand_config_mapper.dart';
import '../../../institution_onboarding/presentation/pages/institution_brand_draft.dart';
import '../../../institution_onboarding/presentation/pages/institution_brand_editor.dart';

class InstitutionAppearancePage extends StatefulWidget {
  const InstitutionAppearancePage({super.key});

  @override
  State<InstitutionAppearancePage> createState() =>
      _InstitutionAppearancePageState();
}

class _InstitutionAppearancePageState extends State<InstitutionAppearancePage> {
  final client = Supabase.instance.client;
  final draft = InstitutionBrandDraft();
  InstitutionAppearanceAssetGateway? gateway;
  InstitutionAppearanceFinishService? service;
  InstitutionAppearancePendingStore? pendingStore;
  LoadedInstitutionAppearance? active;
  String? institutionId;
  String institutionName = 'Institution';
  String? logoUrl;
  String? initialConfig;
  String? error;
  bool loading = true;
  bool saving = false;
  int uploaded = 0, total = 0;
  String? activeBackgroundId;
  Uint8List? activeBackgroundBytes;
  final activeElementIds = <int, String>{};
  final activeElementBytes = <int, Uint8List>{};

  @override
  void initState() {
    super.initState();
    draft.addListener(_draftChanged);
    _load();
  }

  @override
  void dispose() {
    draft.removeListener(_draftChanged);
    draft.dispose();
    gateway?.close();
    super.dispose();
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  bool get dirty {
    if (initialConfig == null) return false;
    try {
      return _currentConfigJson() != initialConfig;
    } catch (_) {
      return true;
    }
  }

  String _currentConfigJson() {
    String? backgroundId;
    final elementIds = <int, String>{};
    if (draft.ambience == InstitutionAmbience.my) {
      final background = draft.myBackground;
      if (background != null) {
        backgroundId =
            activeBackgroundId != null &&
                listEquals(background.bytes, activeBackgroundBytes)
            ? activeBackgroundId
            : 'local-background-draft';
      }
      for (final entry in draft.myElements.entries) {
        final activeBytes = activeElementBytes[entry.key];
        elementIds[entry.key] =
            activeElementIds[entry.key] != null &&
                listEquals(entry.value.bytes, activeBytes)
            ? activeElementIds[entry.key]!
            : 'local-element-draft-${entry.key}';
      }
    }
    return jsonEncode(
      InstitutionBrandConfigMapper.encode(
        draft,
        customBackgroundAssetId: backgroundId,
        customElementAssetIds: elementIds,
      ).toJson(),
    );
  }

  Future<void> _load() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Your session expired. Sign in again.');
      final admin = await InstitutionAdminContextResolver(
        client,
      ).resolve(user.id);
      final id = admin.institutionId;
      if (id == null) {
        throw Exception('No institution is linked to this administrator.');
      }
      final institution = await client
          .from('institutions')
          .select('name, logo_url')
          .eq('id', id)
          .maybeSingle();
      if (institution == null) throw Exception('Institution not found.');
      institutionId = id;
      institutionName = institution['name']?.toString() ?? 'Institution';
      logoUrl = institution['logo_url']?.toString();
      final repository = InstitutionAppearanceRepository(
        SupabaseInstitutionAppearanceBackend(client),
      );
      gateway = InstitutionAppearanceAssetGateway(client: client);
      pendingStore = InstitutionAppearancePendingStore(
        await SharedPreferences.getInstance(),
      );
      final vault = createInstitutionAppearanceFileVault();
      service = InstitutionAppearanceFinishService(
        backend: SupabaseInstitutionAppearanceCompletionBackend(
          client: client,
          repository: repository,
          assets: gateway!,
        ),
        pendingStore: pendingStore!,
        fileVault: vault,
      );
      final recovery = await service!.recover(id);
      final loaded = await repository.load(id);
      active = loaded;
      final selection = InstitutionBrandConfigMapper.restore(
        draft,
        loaded.config,
      );
      await _restoreActiveFiles(loaded, selection);
      final pending = recovery.request;
      if (pending != null && !pending.completeOnboarding) {
        final pendingSelection = InstitutionBrandConfigMapper.restore(
          draft,
          pending.config,
        );
        await _restorePendingFiles(pending, pendingSelection, vault);
        error = 'A previous appearance save is ready to retry.';
      }
      initialConfig = pending == null
          ? _currentConfigJson()
          : jsonEncode(pending.config.toJson());
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _restoreActiveFiles(
    LoadedInstitutionAppearance loaded,
    RecoveredCustomAssetSelection selection,
  ) async {
    if (loaded.config.ambience['kind'] != 'my') return;
    final byId = {for (final asset in loaded.assets) asset.id: asset};
    final background = byId[selection.backgroundAssetId];
    if (background?.signedUrl != null) {
      final bytes = await gateway!.download(background!.signedUrl!);
      activeBackgroundId = background.id;
      activeBackgroundBytes = bytes;
      draft.myBackground = _file(background, bytes);
    }
    for (final entry in selection.elementAssetIds.entries) {
      final asset = byId[entry.value];
      if (asset?.signedUrl == null) continue;
      final bytes = await gateway!.download(asset!.signedUrl!);
      activeElementIds[entry.key] = asset.id;
      activeElementBytes[entry.key] = bytes;
      draft.myElements[entry.key] = _file(asset, bytes);
    }
  }

  Future<void> _restorePendingFiles(
    PendingInstitutionAppearanceRequest request,
    RecoveredCustomAssetSelection selection,
    InstitutionAppearanceFileVault vault,
  ) async {
    final pendingById = {for (final asset in request.assets) asset.id: asset};
    final backgroundId = selection.backgroundAssetId;
    if (backgroundId != null && backgroundId != activeBackgroundId) {
      final item = pendingById[backgroundId];
      if (item != null) {
        draft.myBackground = _pendingFile(
          item,
          await vault.read(item.localPath),
        );
      }
    }
    for (final entry in selection.elementAssetIds.entries) {
      if (activeElementIds[entry.key] == entry.value) continue;
      final item = pendingById[entry.value];
      if (item != null) {
        draft.myElements[entry.key] = _pendingFile(
          item,
          await vault.read(item.localPath),
        );
      }
    }
  }

  MyAmbienceFile _file(InstitutionAppearanceAsset asset, Uint8List bytes) =>
      MyAmbienceFile(
        name: asset.storagePath.split('/').last,
        bytes: bytes,
        width: asset.width,
        height: asset.height,
        format: _format(asset.mimeType),
      );
  MyAmbienceFile _pendingFile(
    PendingInstitutionAppearanceAsset asset,
    Uint8List bytes,
  ) => MyAmbienceFile(
    name: asset.fileName,
    bytes: bytes,
    width: asset.width,
    height: asset.height,
    format: asset.format,
  );
  String _format(String mime) => switch (mime) {
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    _ => 'png',
  };

  Future<void> _save() async {
    if (saving || active == null || institutionId == null || service == null) {
      return;
    }
    setState(() {
      saving = true;
      error = null;
      uploaded = 0;
      total = 0;
    });
    try {
      final files = <LocalAppearanceUpload>[];
      String? retainedBackground;
      final retainedElements = <int, String>{};
      if (draft.ambience == InstitutionAmbience.my) {
        final background = draft.myBackground;
        if (background != null &&
            activeBackgroundId != null &&
            listEquals(background.bytes, activeBackgroundBytes)) {
          retainedBackground = activeBackgroundId;
        } else if (background != null) {
          files.add(
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
        for (final entry in draft.myElements.entries) {
          if (activeElementIds[entry.key] != null &&
              listEquals(entry.value.bytes, activeElementBytes[entry.key])) {
            retainedElements[entry.key] = activeElementIds[entry.key]!;
          } else {
            final file = entry.value;
            files.add(
              LocalAppearanceUpload(
                kind: 'element',
                slot: entry.key,
                fileName: file.name,
                bytes: file.bytes,
                width: file.width,
                height: file.height,
                format: file.format,
              ),
            );
          }
        }
      }
      final result = await service!.finish(
        expectedInstitutionId: institutionId!,
        expectedRevision: active!.revision,
        localFiles: files,
        completeOnboarding: false,
        buildConfig: (backgroundId, elementIds) =>
            InstitutionBrandConfigMapper.encode(
              draft,
              customBackgroundAssetId: backgroundId ?? retainedBackground,
              customElementAssetIds: {...retainedElements, ...elementIds},
            ),
        onUploadProgress: (done, count) {
          if (mounted) {
            setState(() {
              uploaded = done;
              total = count;
            });
          }
        },
      );
      active = result.appearance;
      initialConfig = jsonEncode(result.appearance.config.toJson());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appearance saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } on InstitutionAppearanceFinishException catch (e) {
      if (mounted) {
        setState(
          () => error = e.cleanupPending
              ? '${e.message} Cleanup will resume next time.'
              : e.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Appearance could not be saved. Your draft is safe.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard unsaved changes?'),
            content: const Text(
              'Your active appearance will remain unchanged.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty || saving,
    onPopInvokedWithResult: (didPop, _) async {
      final navigator = Navigator.of(context);
      if (!didPop && await _confirmDiscard() && mounted) {
        navigator.pop();
      }
    },
    child: Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: const Color(0xFF080D24),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    if (await _confirmDiscard() && mounted) {
                      navigator.pop();
                    }
                  },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: loading || saving || !dirty ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save changes'),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null && active == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          loading = true;
                          error = null;
                        });
                        _load();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                  child: Column(
                    children: [
                      if (error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Preview changes here. Nothing becomes active until Save changes.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InstitutionBrandEditor(
                        draft: draft,
                        institutionName: institutionName,
                        logoUrl: logoUrl,
                      ),
                    ],
                  ),
                ),
                if (saving)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: .72),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              total > 0
                                  ? 'Uploading $uploaded of $total…'
                                  : 'Saving appearance…',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
