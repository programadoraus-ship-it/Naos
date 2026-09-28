import 'dart:typed_data';

import 'package:app/core/appearance/institution_appearance_config.dart';
import 'package:app/core/appearance/institution_appearance_finish_service.dart';
import 'package:app/core/appearance/institution_appearance_pending_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryPendingStore implements InstitutionAppearancePendingRequestStore {
  PendingInstitutionAppearanceRequest? value;

  @override
  Future<void> clear(String institutionId) async => value = null;

  @override
  PendingInstitutionAppearanceRequest? load(String institutionId) =>
      value?.institutionId == institutionId ? value : null;

  @override
  Future<void> save(PendingInstitutionAppearanceRequest request) async {
    value = request;
  }
}

class _MemoryVault implements InstitutionAppearanceFileVault {
  final Map<String, Uint8List> files = {};
  var clearCalls = 0;

  @override
  Future<void> clearRequest(String institutionId, String requestId) async {
    clearCalls++;
    files.clear();
  }

  @override
  Future<Uint8List> read(String localPath) async => files[localPath]!;

  @override
  Future<String> write({
    required String institutionId,
    required String requestId,
    required String assetId,
    required Uint8List bytes,
  }) async {
    final key = '$institutionId/$requestId/$assetId';
    files[key] = bytes;
    return key;
  }
}

class _Backend implements InstitutionAppearanceCompletionBackend {
  var contextInstitution = 'institution-a';
  var membership = 'membership-a';
  var step = 8;
  var completed = false;
  var revision = 0;
  InstitutionAppearanceConfig config =
      InstitutionAppearanceConfig.safeDefault();
  final Map<String, PendingInstitutionAppearanceAsset> uploaded = {};
  final Set<String> active = {};
  String? lastRequest;
  var uploadCalls = 0;
  var activateCalls = 0;
  var cleanupCalls = 0;
  bool failUpload = false;
  bool failActivation = false;
  bool expireSession = false;
  bool responseLostAfterActivation = false;

  @override
  Future<AppearanceCompletionContext> resolveContext() async {
    if (expireSession) {
      throw const InstitutionAppearanceFinishException(
        'Your session expired.',
        code: 'session_expired',
      );
    }
    return AppearanceCompletionContext(
      institutionId: contextInstitution,
      membershipId: membership,
    );
  }

  @override
  Future<AppearanceOnboardingSnapshot> loadOnboarding(
    String institutionId,
  ) async => AppearanceOnboardingSnapshot(step: step, completed: completed);

  @override
  Future<void> upload({
    required String institutionId,
    required String requestId,
    required PendingInstitutionAppearanceAsset asset,
    required Uint8List bytes,
  }) async {
    uploadCalls++;
    if (failUpload) throw Exception('upload unavailable');
    uploaded.putIfAbsent(asset.id, () => asset);
  }

  @override
  Future<int> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required InstitutionAppearanceConfig config,
    required bool completeOnboarding,
  }) async {
    activateCalls++;
    if (lastRequest == requestId) return revision;
    if (failActivation) throw Exception('activation unavailable');
    if (expectedRevision != revision) {
      throw Exception('Appearance changed in another session.');
    }
    revision++;
    this.config = config;
    lastRequest = requestId;
    active
      ..clear()
      ..addAll(
        List<String>.from(config.ambience['custom_element_asset_ids'] as List),
      )
      ..addAll([
        if (config.ambience['custom_background_asset_id'] case final String id)
          id,
      ]);
    if (completeOnboarding) {
      step = 9;
      completed = true;
    }
    if (responseLostAfterActivation) {
      responseLostAfterActivation = false;
      throw Exception('connection lost after response');
    }
    return revision;
  }

  @override
  Future<LoadedInstitutionAppearance> loadAppearance(
    String institutionId,
  ) async => LoadedInstitutionAppearance(
    institutionId: institutionId,
    config: config,
    revision: revision,
    assets: [
      for (final id in active)
        InstitutionAppearanceAsset(
          id: id,
          kind: uploaded[id]?.kind ?? 'element',
          slot: uploaded[id]?.slot ?? 0,
          storagePath: '$institutionId/$id.png',
          mimeType: 'image/png',
          width: 20,
          height: 20,
        ),
    ],
    usesFallback: revision == 0,
  );

  @override
  Future<List<Map<String, dynamic>>> listRecoverable(
    String institutionId,
  ) async => [
    for (final entry in uploaded.entries)
      if (!active.contains(entry.key)) {'id': entry.key, 'status': 'pending'},
  ];

  @override
  Future<void> cleanup(String assetId) async {
    cleanupCalls++;
    if (active.contains(assetId)) throw Exception('active asset');
    uploaded.remove(assetId);
  }
}

InstitutionAppearanceConfig _config(
  String? background,
  Map<int, String> elements,
) {
  final json = InstitutionAppearanceConfig.safeDefault().toJson();
  if (background != null || elements.isNotEmpty) {
    final ambience = json['ambience'] as Map<String, dynamic>;
    ambience['kind'] = 'my';
    ambience['custom_background_asset_id'] = background;
    ambience['custom_element_asset_ids'] = [
      for (final entry
          in elements.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        entry.value,
    ];
    ambience['custom_element_slots'] = {
      for (final entry in elements.entries) '${entry.key}': entry.value,
    };
  }
  return InstitutionAppearanceConfig.fromJson(json);
}

LocalAppearanceUpload _file(String kind, int slot) => LocalAppearanceUpload(
  kind: kind,
  slot: slot,
  fileName: '$kind-$slot.png',
  bytes: Uint8List.fromList([137, 80, 78, 71, slot]),
  width: 20,
  height: 20,
  format: 'png',
);

void main() {
  late _Backend backend;
  late _MemoryPendingStore pending;
  late _MemoryVault vault;
  late InstitutionAppearanceFinishService service;
  var sequence = 0;

  setUp(() {
    backend = _Backend();
    pending = _MemoryPendingStore();
    vault = _MemoryVault();
    service = InstitutionAppearanceFinishService(
      backend: backend,
      pendingStore: pending,
      fileVault: vault,
      uuid: () =>
          '10000000-0000-4000-8000-${(++sequence).toString().padLeft(12, '0')}',
      clock: () => DateTime.utc(2026, 9, 25),
    );
  });

  test('finishes onboarding without custom files', () async {
    final result = await service.finish(
      expectedInstitutionId: 'institution-a',
      expectedRevision: 0,
      localFiles: const [],
      buildConfig: _config,
    );
    expect(result.revision, 1);
    expect(backend.completed, isTrue);
    expect(backend.step, 9);
    expect(pending.value, isNull);
  });

  test('uploads background and elements then verifies activation', () async {
    final progress = <String>[];
    final result = await service.finish(
      expectedInstitutionId: 'institution-a',
      expectedRevision: 0,
      localFiles: [_file('background', 0), _file('element', 2)],
      buildConfig: _config,
      onUploadProgress: (done, total) => progress.add('$done/$total'),
    );
    expect(result.appearance.assets, hasLength(2));
    expect(backend.uploadCalls, 2);
    expect(progress, ['0/2', '1/2', '2/2']);
    expect(vault.files, isEmpty);
  });

  test('edits appearance without changing completed onboarding', () async {
    backend
      ..step = 9
      ..completed = true
      ..revision = 1;
    final result = await service.finish(
      expectedInstitutionId: 'institution-a',
      expectedRevision: 1,
      localFiles: const [],
      buildConfig: _config,
      completeOnboarding: false,
    );
    expect(result.revision, 2);
    expect(backend.step, 9);
    expect(backend.completed, isTrue);
    expect(pending.value, isNull);
  });

  test('upload failure preserves request and local bytes', () async {
    backend.failUpload = true;
    await expectLater(
      service.finish(
        expectedInstitutionId: 'institution-a',
        expectedRevision: 0,
        localFiles: [_file('background', 0)],
        buildConfig: _config,
      ),
      throwsA(isA<InstitutionAppearanceFinishException>()),
    );
    expect(pending.value, isNotNull);
    expect(vault.files, isNotEmpty);
    expect(backend.completed, isFalse);
  });

  test('activation failure preserves draft and does not complete', () async {
    backend.failActivation = true;
    await expectLater(
      service.finish(
        expectedInstitutionId: 'institution-a',
        expectedRevision: 0,
        localFiles: [_file('element', 0)],
        buildConfig: _config,
      ),
      throwsA(isA<InstitutionAppearanceFinishException>()),
    );
    expect(pending.value, isNotNull);
    expect(backend.completed, isFalse);
  });

  test(
    'lost activation response recovers idempotently without reupload',
    () async {
      backend.responseLostAfterActivation = true;
      await expectLater(
        service.finish(
          expectedInstitutionId: 'institution-a',
          expectedRevision: 0,
          localFiles: [_file('background', 0)],
          buildConfig: _config,
        ),
        throwsA(isA<InstitutionAppearanceFinishException>()),
      );
      final uploads = backend.uploadCalls;
      final result = await service.finish(
        expectedInstitutionId: 'institution-a',
        expectedRevision: 1,
        localFiles: const [],
        buildConfig: _config,
      );
      expect(result.revision, 1);
      expect(backend.uploadCalls, uploads);
      expect(pending.value, isNull);
    },
  );

  test(
    'recovers pending request and cleans unrelated remote attempts',
    () async {
      backend.failActivation = true;
      await expectLater(
        service.finish(
          expectedInstitutionId: 'institution-a',
          expectedRevision: 0,
          localFiles: [_file('element', 1)],
          buildConfig: _config,
        ),
        throwsA(anything),
      );
      backend.uploaded['unrelated'] = PendingInstitutionAppearanceAsset(
        id: 'unrelated',
        kind: 'element',
        slot: 4,
        fileName: 'old.png',
        localPath: 'old',
        width: 1,
        height: 1,
        format: 'png',
      );
      final recovered = await service.recover('institution-a');
      expect(recovered.request?.requestId, pending.value?.requestId);
      expect(backend.uploaded, isNot(contains('unrelated')));
    },
  );

  test('revision conflict and session expiry remain retryable', () async {
    backend.revision = 2;
    await expectLater(
      service.finish(
        expectedInstitutionId: 'institution-a',
        expectedRevision: 0,
        localFiles: const [],
        buildConfig: _config,
      ),
      throwsA(
        isA<InstitutionAppearanceFinishException>().having(
          (error) => error.code,
          'code',
          'revision_conflict',
        ),
      ),
    );
    backend.expireSession = true;
    await expectLater(
      service.finish(
        expectedInstitutionId: 'institution-a',
        expectedRevision: 2,
        localFiles: const [],
        buildConfig: _config,
      ),
      throwsA(
        isA<InstitutionAppearanceFinishException>().having(
          (error) => error.code,
          'code',
          'session_expired',
        ),
      ),
    );
  });

  test('rejects a contradictory institution before any upload', () async {
    backend.contextInstitution = 'institution-b';
    await expectLater(
      service.finish(
        expectedInstitutionId: 'institution-a',
        expectedRevision: 0,
        localFiles: [_file('background', 0)],
        buildConfig: _config,
      ),
      throwsA(
        isA<InstitutionAppearanceFinishException>().having(
          (error) => error.code,
          'code',
          'institution_context',
        ),
      ),
    );
    expect(backend.uploadCalls, 0);
  });
}
