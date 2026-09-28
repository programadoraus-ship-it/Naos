import 'package:app/core/appearance/institution_appearance_config.dart';
import 'package:app/core/appearance/institution_appearance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Backend implements InstitutionAppearanceBackend {
  _Backend(this.response);
  Map<String, dynamic> response;
  int signedCalls = 0;
  int activationCalls = 0;

  @override
  Future<Map<String, dynamic>> load(String institutionId) async => response;

  @override
  Future<Map<String, dynamic>> activate({
    required String institutionId,
    required int expectedRevision,
    required String requestId,
    required Map<String, dynamic> config,
    required bool completeOnboarding,
  }) async {
    activationCalls++;
    return {'revision': expectedRevision + 1};
  }

  @override
  Future<String> createSignedUrl(
    String storagePath,
    int expiresInSeconds,
  ) async {
    signedCalls++;
    return 'https://signed.invalid/$signedCalls/$storagePath';
  }

  @override
  Future<List<Map<String, dynamic>>> listPending(String institutionId) async =>
      [
        {'id': 'pending', 'status': 'pending'},
      ];
}

void main() {
  test('safe fallback maps compatible legacy columns', () {
    final config = InstitutionAppearanceConfig.safeDefault(
      legacyTemplate: 'academy',
      legacyPrimary: '#123456',
      legacyFont: 'lora',
      legacyButtonStyle: 'pill:outlined',
    );
    expect(config.template, 'academy');
    expect(config.typography, 'lora');
    expect(config.colors['primary']['hex'], '#123456');
    expect(config.buttons, {'shape': 'pill', 'finish': 'outlined'});
    expect(config.ambience['kind'], 'none');
  });

  test('rejects an oversized or structurally invalid configuration', () {
    final valid = InstitutionAppearanceConfig.safeDefault().toJson();
    valid['motion'] = 'continuous-flashing';
    expect(
      () => InstitutionAppearanceConfig.fromJson(valid),
      throwsA(isA<InstitutionAppearanceConfigException>()),
    );
    final huge = InstitutionAppearanceConfig.safeDefault().toJson()
      ..['padding'] = 'x' * institutionAppearanceMaxConfigBytes;
    expect(
      () => InstitutionAppearanceConfig.fromJson(huge),
      throwsA(isA<InstitutionAppearanceConfigException>()),
    );
    final invalidScene = InstitutionAppearanceConfig.safeDefault().toJson();
    invalidScene['ambience']['kind'] = 'ocean';
    invalidScene['ambience']['selected_scene'] = 'unknownReef';
    expect(
      () => InstitutionAppearanceConfig.fromJson(invalidScene),
      throwsA(isA<InstitutionAppearanceConfigException>()),
    );
  });

  test('loads fallback and refreshes signed URLs before expiry', () async {
    var now = DateTime.utc(2026, 1, 1);
    final backend = _Backend({
      'institution_id': 'institution-a',
      'template': 'orbit',
      'theme_color': '#675CFF',
      'font_style': 'inter',
      'button_style': 'rounded:solid',
      'appearance': null,
      'assets': <Object>[],
    });
    final repository = InstitutionAppearanceRepository(
      backend,
      clock: () => now,
    );
    final loaded = await repository.load('institution-a');
    expect(loaded.usesFallback, isTrue);
    expect(loaded.revision, 0);
    final first = await repository.signedUrl('institution-a/path.png');
    final cached = await repository.signedUrl('institution-a/path.png');
    expect(cached, first);
    expect(backend.signedCalls, 1);
    now = now.add(const Duration(minutes: 51));
    final renewed = await repository.signedUrl('institution-a/path.png');
    expect(renewed, isNot(first));
    expect(backend.signedCalls, 2);
  });

  test(
    'activates with revision and retains recoverable pending records',
    () async {
      final backend = _Backend({});
      final repository = InstitutionAppearanceRepository(backend);
      final revision = await repository.activate(
        institutionId: 'institution-a',
        expectedRevision: 4,
        requestId: 'request-a',
        config: InstitutionAppearanceConfig.safeDefault(),
        completeOnboarding: true,
      );
      expect(revision, 5);
      expect(backend.activationCalls, 1);
      expect(await repository.recoverableAssets('institution-a'), hasLength(1));
    },
  );

  test('a new repository instance recovers the persisted appearance', () async {
    final saved = InstitutionAppearanceConfig.safeDefault(
      legacyTemplate: 'heritage',
      legacyFont: 'bitter',
    );
    final backend = _Backend({
      'institution_id': 'institution-a',
      'template': 'heritage',
      'theme_color': '#675CFF',
      'font_style': 'bitter',
      'button_style': 'rounded:solid',
      'appearance': {
        'schema_version': 1,
        'config': saved.toJson(),
        'revision': 7,
      },
      'assets': <Object>[],
    });

    final afterNewSession = InstitutionAppearanceRepository(backend);
    final loaded = await afterNewSession.load('institution-a');

    expect(loaded.usesFallback, isFalse);
    expect(loaded.revision, 7);
    expect(loaded.config.template, 'heritage');
    expect(loaded.config.typography, 'bitter');
  });
}
