import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'institution_appearance_config.dart';

abstract interface class InstitutionAppearanceBackend {
  Future<Map<String, dynamic>> load(String institutionId);
  Future<Map<String, dynamic>> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required Map<String, dynamic> config,
    required bool completeOnboarding,
  });
  Future<String> createSignedUrl(String storagePath, int expiresInSeconds);
  Future<List<Map<String, dynamic>>> listPending(String institutionId);
}

class SupabaseInstitutionAppearanceBackend
    implements InstitutionAppearanceBackend {
  SupabaseInstitutionAppearanceBackend(this.client);
  final SupabaseClient client;

  @override
  Future<Map<String, dynamic>> load(String institutionId) async =>
      Map<String, dynamic>.from(
        await client.rpc(
              'get_institution_appearance',
              params: {'p_institution_id': institutionId},
            )
            as Map,
      );

  @override
  Future<Map<String, dynamic>> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required Map<String, dynamic> config,
    required bool completeOnboarding,
  }) async => Map<String, dynamic>.from(
    await client.rpc(
          'activate_institution_appearance',
          params: {
            'p_institution_id': institutionId,
            'p_expected_revision': expectedRevision,
            'p_request_id': requestId,
            'p_config': config,
            'p_complete_onboarding': completeOnboarding,
          },
        )
        as Map,
  );

  @override
  Future<String> createSignedUrl(String storagePath, int expiresInSeconds) =>
      client.storage
          .from('institution-appearance')
          .createSignedUrl(storagePath, expiresInSeconds);

  @override
  Future<List<Map<String, dynamic>>> listPending(String institutionId) async =>
      List<Map<String, dynamic>>.from(
        await client.rpc(
              'list_pending_institution_appearance_assets',
              params: {'p_institution_id': institutionId},
            )
            as List,
      );
}

class _SignedUrlEntry {
  const _SignedUrlEntry(this.url, this.refreshAt);
  final String url;
  final DateTime refreshAt;
}

class InstitutionAppearanceRepository {
  InstitutionAppearanceRepository(this.backend, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final InstitutionAppearanceBackend backend;
  final DateTime Function() _clock;
  final Map<String, _SignedUrlEntry> _signedUrls = {};

  static const signedUrlLifetime = Duration(hours: 1);
  static const signedUrlRefreshAfter = Duration(minutes: 50);

  Future<LoadedInstitutionAppearance> load(String institutionId) async {
    final response = await backend.load(institutionId);
    final appearance = response['appearance'];
    final usesFallback = appearance == null;
    final config = usesFallback
        ? InstitutionAppearanceConfig.safeDefault(
            legacyTemplate: response['template'] as String?,
            legacyPrimary: response['theme_color'] as String?,
            legacyFont: response['font_style'] as String?,
            legacyButtonStyle: response['button_style'] as String?,
          )
        : InstitutionAppearanceConfig.fromJson(
            Map<String, dynamic>.from((appearance as Map)['config'] as Map),
          );
    final assets = <InstitutionAppearanceAsset>[];
    for (final raw in (response['assets'] as List? ?? const [])) {
      final asset = InstitutionAppearanceAsset.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      assets.add(asset.withSignedUrl(await signedUrl(asset.storagePath)));
    }
    return LoadedInstitutionAppearance(
      institutionId: institutionId,
      config: config,
      revision: usesFallback
          ? 0
          : ((appearance as Map)['revision'] as num).toInt(),
      assets: assets,
      usesFallback: usesFallback,
    );
  }

  Future<String> signedUrl(String storagePath) async {
    final now = _clock();
    final cached = _signedUrls[storagePath];
    if (cached != null && now.isBefore(cached.refreshAt)) return cached.url;
    final url = await backend.createSignedUrl(
      storagePath,
      signedUrlLifetime.inSeconds,
    );
    _signedUrls[storagePath] = _SignedUrlEntry(
      url,
      now.add(signedUrlRefreshAfter),
    );
    return url;
  }

  Future<int> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required InstitutionAppearanceConfig config,
    bool completeOnboarding = false,
  }) async {
    config.validate();
    final result = await backend.activate(
      institutionId: institutionId,
      expectedRevision: expectedRevision,
      requestId: requestId,
      config: config.toJson(),
      completeOnboarding: completeOnboarding,
    );
    return (result['revision'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> recoverableAssets(String institutionId) =>
      backend.listPending(institutionId);

  void clearSignedUrlCache() => _signedUrls.clear();
}
