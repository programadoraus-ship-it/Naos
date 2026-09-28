import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase/institution_admin_context.dart';
import 'institution_appearance_asset_gateway.dart';
import 'institution_appearance_config.dart';
import 'institution_appearance_pending_store.dart';
import 'institution_appearance_repository.dart';

class AppearanceCompletionContext {
  const AppearanceCompletionContext({
    required this.institutionId,
    required this.membershipId,
  });

  final String institutionId;
  final String membershipId;
}

class AppearanceOnboardingSnapshot {
  const AppearanceOnboardingSnapshot({
    required this.step,
    required this.completed,
  });

  final int step;
  final bool completed;
}

class LocalAppearanceUpload {
  const LocalAppearanceUpload({
    required this.kind,
    required this.slot,
    required this.fileName,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
  });

  final String kind;
  final int slot;
  final String fileName;
  final Uint8List bytes;
  final int width;
  final int height;
  final String format;
}

abstract interface class InstitutionAppearanceCompletionBackend {
  Future<AppearanceCompletionContext> resolveContext();
  Future<AppearanceOnboardingSnapshot> loadOnboarding(String institutionId);
  Future<LoadedInstitutionAppearance> loadAppearance(String institutionId);
  Future<void> upload({
    required String institutionId,
    required String requestId,
    required PendingInstitutionAppearanceAsset asset,
    required Uint8List bytes,
  });
  Future<int> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required InstitutionAppearanceConfig config,
    required bool completeOnboarding,
  });
  Future<List<Map<String, dynamic>>> listRecoverable(String institutionId);
  Future<void> cleanup(String assetId);
}

class SupabaseInstitutionAppearanceCompletionBackend
    implements InstitutionAppearanceCompletionBackend {
  SupabaseInstitutionAppearanceCompletionBackend({
    required this.client,
    required this.repository,
    required this.assets,
  });

  final SupabaseClient client;
  final InstitutionAppearanceRepository repository;
  final InstitutionAppearanceAssetGateway assets;

  @override
  Future<AppearanceCompletionContext> resolveContext() async {
    final user = client.auth.currentUser;
    if (user == null || client.auth.currentSession == null) {
      throw const InstitutionAppearanceFinishException(
        'Your session expired. Sign in again, then retry your setup.',
        code: 'session_expired',
      );
    }
    final context = await InstitutionAdminContextResolver(
      client,
    ).resolve(user.id);
    final institutionId = context.institutionId;
    final membershipId = context.activeMembershipId;
    if (institutionId == null || membershipId == null) {
      throw const InstitutionAppearanceFinishException(
        'Your active administrator link and membership are not ready.',
        code: 'institution_context',
      );
    }
    return AppearanceCompletionContext(
      institutionId: institutionId,
      membershipId: membershipId,
    );
  }

  @override
  Future<AppearanceOnboardingSnapshot> loadOnboarding(
    String institutionId,
  ) async {
    final row = await client
        .from('institutions')
        .select('onboarding_step, onboarding_completed')
        .eq('id', institutionId)
        .maybeSingle();
    if (row == null) {
      throw const InstitutionAppearanceFinishException(
        'The linked institution could not be found.',
        code: 'institution_context',
      );
    }
    return AppearanceOnboardingSnapshot(
      step: (row['onboarding_step'] as num?)?.toInt() ?? 0,
      completed: row['onboarding_completed'] == true,
    );
  }

  @override
  Future<LoadedInstitutionAppearance> loadAppearance(String institutionId) =>
      repository.load(institutionId);

  @override
  Future<void> upload({
    required String institutionId,
    required String requestId,
    required PendingInstitutionAppearanceAsset asset,
    required Uint8List bytes,
  }) async {
    await assets.upload(
      institutionId: institutionId,
      requestId: requestId,
      assetId: asset.id,
      kind: asset.kind,
      slot: asset.slot,
      fileName: asset.fileName,
      bytes: bytes,
    );
  }

  @override
  Future<int> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required InstitutionAppearanceConfig config,
    required bool completeOnboarding,
  }) => repository.activate(
    institutionId: institutionId,
    expectedRevision: expectedRevision,
    requestId: requestId,
    config: config,
    completeOnboarding: completeOnboarding,
  );

  @override
  Future<List<Map<String, dynamic>>> listRecoverable(String institutionId) =>
      repository.recoverableAssets(institutionId);

  @override
  Future<void> cleanup(String assetId) => assets.cleanup(assetId);
}

class InstitutionAppearanceFinishException implements Exception {
  const InstitutionAppearanceFinishException(
    this.message, {
    this.code = 'save_failed',
    this.cleanupPending = false,
  });

  final String message;
  final String code;
  final bool cleanupPending;

  @override
  String toString() => message;
}

class AppearanceRecoveryResult {
  const AppearanceRecoveryResult({this.request, this.cleanupFailures = 0});

  final PendingInstitutionAppearanceRequest? request;
  final int cleanupFailures;
}

class AppearanceFinishResult {
  const AppearanceFinishResult({
    required this.appearance,
    required this.revision,
    required this.cleanupFailures,
  });

  final LoadedInstitutionAppearance appearance;
  final int revision;
  final int cleanupFailures;
}

typedef AppearanceConfigBuilder =
    InstitutionAppearanceConfig Function(
      String? backgroundAssetId,
      Map<int, String> elementAssetIds,
    );

class InstitutionAppearanceFinishService {
  InstitutionAppearanceFinishService({
    required this.backend,
    required this.pendingStore,
    required this.fileVault,
    String Function()? uuid,
    DateTime Function()? clock,
  }) : _uuid = uuid ?? _newUuid,
       _clock = clock ?? DateTime.now;

  final InstitutionAppearanceCompletionBackend backend;
  final InstitutionAppearancePendingRequestStore pendingStore;
  final InstitutionAppearanceFileVault fileVault;
  final String Function() _uuid;
  final DateTime Function() _clock;

  Future<AppearanceRecoveryResult> recover(String institutionId) async {
    final request = pendingStore.load(institutionId);
    final remote = await backend.listRecoverable(institutionId);
    final retained = request?.assetIds.toSet() ?? const <String>{};
    var failures = 0;
    for (final row in remote) {
      final id = row['id']?.toString();
      if (id == null || retained.contains(id)) continue;
      try {
        await backend.cleanup(id);
      } catch (_) {
        failures++;
      }
    }
    return AppearanceRecoveryResult(
      request: request,
      cleanupFailures: failures,
    );
  }

  Future<AppearanceFinishResult> finish({
    required String expectedInstitutionId,
    required int expectedRevision,
    required List<LocalAppearanceUpload> localFiles,
    required AppearanceConfigBuilder buildConfig,
    void Function(int completed, int total)? onUploadProgress,
    bool completeOnboarding = true,
  }) async {
    final context = await backend.resolveContext();
    if (context.institutionId != expectedInstitutionId) {
      throw const InstitutionAppearanceFinishException(
        'Your institution changed while setup was open. Nothing was saved.',
        code: 'institution_context',
      );
    }
    var request = pendingStore.load(context.institutionId);
    if (request != null && request.completeOnboarding != completeOnboarding) {
      throw const InstitutionAppearanceFinishException(
        'A different appearance save is still pending. Recover it before continuing.',
        code: 'pending_request',
      );
    }
    final before = await backend.loadOnboarding(context.institutionId);
    if (completeOnboarding &&
        before.completed &&
        before.step == 9 &&
        request != null) {
      final revision = await backend.activate(
        institutionId: request.institutionId,
        expectedRevision: request.expectedRevision,
        requestId: request.requestId,
        config: request.config,
        completeOnboarding: request.completeOnboarding,
      );
      final loaded = await backend.loadAppearance(request.institutionId);
      if (loaded.revision != revision ||
          !_deepEquals(loaded.config.toJson(), request.config.toJson())) {
        throw const InstitutionAppearanceFinishException(
          'The completed setup could not be verified. Reload before retrying.',
          code: 'verification_failed',
        );
      }
      await pendingStore.clear(request.institutionId);
      await fileVault.clearRequest(request.institutionId, request.requestId);
      return AppearanceFinishResult(
        appearance: loaded,
        revision: revision,
        cleanupFailures: await _cleanupUnreferenced(
          request.institutionId,
          activeIds: loaded.assets.map((asset) => asset.id).toSet(),
        ),
      );
    }
    if (completeOnboarding && (before.completed || before.step != 8)) {
      throw InstitutionAppearanceFinishException(
        before.completed
            ? 'This institution onboarding is already complete.'
            : 'Setup is no longer at Make it yours. Reload before retrying.',
        code: 'onboarding_state',
      );
    }
    if (!completeOnboarding && !before.completed) {
      throw const InstitutionAppearanceFinishException(
        'Appearance can be edited after onboarding is complete.',
        code: 'onboarding_state',
      );
    }

    if (request != null && request.expectedRevision != expectedRevision) {
      throw const InstitutionAppearanceFinishException(
        'Appearance changed in another session. Reload before saving.',
        code: 'revision_conflict',
      );
    }
    request ??= await _prepare(
      institutionId: context.institutionId,
      expectedRevision: expectedRevision,
      localFiles: localFiles,
      buildConfig: buildConfig,
      completeOnboarding: completeOnboarding,
    );

    try {
      var completed = 0;
      onUploadProgress?.call(completed, request.assets.length);
      for (final asset in request.assets) {
        final bytes = await fileVault.read(asset.localPath);
        await backend.upload(
          institutionId: request.institutionId,
          requestId: request.requestId,
          asset: asset,
          bytes: bytes,
        );
        completed++;
        onUploadProgress?.call(completed, request.assets.length);
      }
      final revision = await backend.activate(
        institutionId: request.institutionId,
        expectedRevision: request.expectedRevision,
        requestId: request.requestId,
        config: request.config,
        completeOnboarding: request.completeOnboarding,
      );
      final loaded = await backend.loadAppearance(request.institutionId);
      final after = await backend.loadOnboarding(request.institutionId);
      if ((request.completeOnboarding &&
              (!after.completed || after.step != 9)) ||
          (!request.completeOnboarding &&
              (after.completed != before.completed ||
                  after.step != before.step)) ||
          loaded.revision != revision ||
          !_deepEquals(loaded.config.toJson(), request.config.toJson())) {
        throw const InstitutionAppearanceFinishException(
          'The server did not confirm the completed setup. Retry safely.',
          code: 'verification_failed',
        );
      }

      await pendingStore.clear(request.institutionId);
      await fileVault.clearRequest(request.institutionId, request.requestId);
      final cleanupFailures = await _cleanupUnreferenced(
        request.institutionId,
        activeIds: loaded.assets.map((asset) => asset.id).toSet(),
      );
      return AppearanceFinishResult(
        appearance: loaded,
        revision: revision,
        cleanupFailures: cleanupFailures,
      );
    } catch (error) {
      final cleanupFailures = await _cleanupRequestAssets(request);
      if (error is InstitutionAppearanceFinishException) {
        throw InstitutionAppearanceFinishException(
          error.message,
          code: error.code,
          cleanupPending: cleanupFailures > 0,
        );
      }
      final text = error.toString().toLowerCase();
      final conflict =
          text.contains('another session') ||
          text.contains('40001') ||
          text.contains('revision');
      final session =
          text.contains('jwt') ||
          text.contains('session') ||
          text.contains('401');
      throw InstitutionAppearanceFinishException(
        conflict
            ? 'Appearance changed in another session. Reload before saving.'
            : session
            ? 'Your session expired. Sign in again, then retry your setup.'
            : 'Your appearance could not be saved. Your draft is safe.',
        code: conflict
            ? 'revision_conflict'
            : session
            ? 'session_expired'
            : 'save_failed',
        cleanupPending: cleanupFailures > 0,
      );
    }
  }

  Future<PendingInstitutionAppearanceRequest> _prepare({
    required String institutionId,
    required int expectedRevision,
    required List<LocalAppearanceUpload> localFiles,
    required AppearanceConfigBuilder buildConfig,
    required bool completeOnboarding,
  }) async {
    final requestId = _uuid();
    final pendingAssets = <PendingInstitutionAppearanceAsset>[];
    String? backgroundId;
    final elementIds = <int, String>{};
    for (final file in localFiles) {
      final assetId = _uuid();
      final localPath = await fileVault.write(
        institutionId: institutionId,
        requestId: requestId,
        assetId: assetId,
        bytes: file.bytes,
      );
      pendingAssets.add(
        PendingInstitutionAppearanceAsset(
          id: assetId,
          kind: file.kind,
          slot: file.slot,
          fileName: file.fileName,
          localPath: localPath,
          width: file.width,
          height: file.height,
          format: file.format,
        ),
      );
      if (file.kind == 'background') {
        backgroundId = assetId;
      } else {
        elementIds[file.slot] = assetId;
      }
    }
    final config = buildConfig(backgroundId, elementIds)..validate();
    final request = PendingInstitutionAppearanceRequest(
      institutionId: institutionId,
      requestId: requestId,
      expectedRevision: expectedRevision,
      config: config,
      assets: pendingAssets,
      updatedAt: _clock().toUtc(),
      completeOnboarding: completeOnboarding,
    );
    await pendingStore.save(request);
    return request;
  }

  Future<int> _cleanupRequestAssets(
    PendingInstitutionAppearanceRequest request,
  ) async {
    var failures = 0;
    for (final id in request.assetIds) {
      try {
        await backend.cleanup(id);
      } catch (_) {
        failures++;
      }
    }
    return failures;
  }

  Future<int> _cleanupUnreferenced(
    String institutionId, {
    required Set<String> activeIds,
  }) async {
    var failures = 0;
    for (final row in await backend.listRecoverable(institutionId)) {
      final id = row['id']?.toString();
      if (id == null || activeIds.contains(id)) continue;
      try {
        await backend.cleanup(id);
      } catch (_) {
        failures++;
      }
    }
    return failures;
  }

  static String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  static bool _deepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_deepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_deepEquals(left[index], right[index])) return false;
      }
      return true;
    }
    return left == right;
  }
}
