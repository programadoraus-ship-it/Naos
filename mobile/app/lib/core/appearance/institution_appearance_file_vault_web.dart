import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

import 'institution_appearance_pending_store.dart';

InstitutionAppearanceFileVault createPlatformInstitutionAppearanceFileVault() =>
    BrowserInstitutionAppearanceFileVault();

class BrowserInstitutionAppearanceFileVault
    implements InstitutionAppearanceFileVault {
  static const _storeName = 'pending_files';
  static const _databaseName = 'naos_appearance_pending_v1';
  Database? _database;

  Future<Database> _open() async => _database ??= await idbFactoryBrowser.open(
    _databaseName,
    version: 1,
    onUpgradeNeeded: (event) {
      final database = event.database;
      if (!database.objectStoreNames.contains(_storeName)) {
        database.createObjectStore(_storeName);
      }
    },
  );

  String _prefix(String institutionId, String requestId) =>
      '$institutionId/$requestId';

  @override
  Future<String> write({
    required String institutionId,
    required String requestId,
    required String assetId,
    required Uint8List bytes,
  }) async {
    final database = await _open();
    final prefix = _prefix(institutionId, requestId);
    final dataKey = '$prefix/$assetId';
    final manifestKey = '$prefix/__keys';
    final transaction = database.transaction(_storeName, idbModeReadWrite);
    final store = transaction.objectStore(_storeName);
    final existing = await store.getObject(manifestKey);
    final keys = List<String>.from(existing as List? ?? const <String>[]);
    await store.put(bytes, dataKey);
    if (!keys.contains(dataKey)) {
      keys.add(dataKey);
      await store.put(keys, manifestKey);
    }
    await transaction.completed;
    return dataKey;
  }

  @override
  Future<Uint8List> read(String localPath) async {
    final database = await _open();
    final transaction = database.transaction(_storeName, idbModeReadOnly);
    final value = await transaction
        .objectStore(_storeName)
        .getObject(localPath);
    await transaction.completed;
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    throw StateError('The pending appearance file is no longer available.');
  }

  @override
  Future<void> clearRequest(String institutionId, String requestId) async {
    final database = await _open();
    final prefix = _prefix(institutionId, requestId);
    final manifestKey = '$prefix/__keys';
    final transaction = database.transaction(_storeName, idbModeReadWrite);
    final store = transaction.objectStore(_storeName);
    final existing = await store.getObject(manifestKey);
    for (final key in List<String>.from(
      existing as List? ?? const <String>[],
    )) {
      await store.delete(key);
    }
    await store.delete(manifestKey);
    await transaction.completed;
  }
}
