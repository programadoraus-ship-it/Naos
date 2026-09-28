import 'package:app/core/appearance/institution_appearance_config.dart';
import 'package:app/core/appearance/institution_appearance_pending_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'recovers and clears a pending request without signed URLs or bytes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = InstitutionAppearancePendingStore(
        await SharedPreferences.getInstance(),
      );
      final request = PendingInstitutionAppearanceRequest(
        institutionId: 'institution-a',
        requestId: 'request-a',
        expectedRevision: 3,
        config: InstitutionAppearanceConfig.safeDefault(),
        assets: const [
          PendingInstitutionAppearanceAsset(
            id: 'asset-a',
            kind: 'background',
            slot: 0,
            fileName: 'background.png',
            localPath: 'local/background.bin',
            width: 100,
            height: 80,
            format: 'png',
          ),
          PendingInstitutionAppearanceAsset(
            id: 'asset-b',
            kind: 'element',
            slot: 1,
            fileName: 'element.png',
            localPath: 'local/element.bin',
            width: 40,
            height: 40,
            format: 'png',
          ),
        ],
        updatedAt: DateTime.utc(2026, 9, 21),
      );
      await store.save(request);
      final restored = store.load('institution-a');
      expect(restored?.requestId, 'request-a');
      expect(restored?.expectedRevision, 3);
      expect(restored?.assetIds, ['asset-a', 'asset-b']);
      expect(restored?.config.template, 'orbit');
      expect(store.load('institution-b'), isNull);
      await store.clear('institution-a');
      expect(store.load('institution-a'), isNull);
    },
  );
}
