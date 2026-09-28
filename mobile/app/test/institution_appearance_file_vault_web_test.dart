import 'dart:typed_data';

import 'package:app/core/appearance/institution_appearance_file_vault_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'browser vault persists and clears pending bytes in IndexedDB',
    () async {
      final vault = BrowserInstitutionAppearanceFileVault();
      const institutionId = '11111111-1111-4111-8111-111111111111';
      const requestId = '22222222-2222-4222-8222-222222222222';
      const assetId = '33333333-3333-4333-8333-333333333333';
      final bytes = Uint8List.fromList([1, 3, 5, 7, 9]);

      final key = await vault.write(
        institutionId: institutionId,
        requestId: requestId,
        assetId: assetId,
        bytes: bytes,
      );
      expect(await vault.read(key), bytes);

      await vault.clearRequest(institutionId, requestId);
      await expectLater(vault.read(key), throwsStateError);
    },
  );
}
