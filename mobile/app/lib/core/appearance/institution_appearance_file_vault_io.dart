import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'institution_appearance_pending_store.dart';

InstitutionAppearanceFileVault createPlatformInstitutionAppearanceFileVault() =>
    DeviceInstitutionAppearanceFileVault();

class DeviceInstitutionAppearanceFileVault
    implements InstitutionAppearanceFileVault {
  DeviceInstitutionAppearanceFileVault({
    Future<Directory> Function()? rootDirectory,
  }) : _rootDirectory = rootDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _rootDirectory;

  Future<Directory> _requestDirectory(
    String institutionId,
    String requestId,
  ) async {
    final root = await _rootDirectory();
    return Directory(
      path.join(
        root.path,
        'naos',
        'appearance-pending',
        institutionId,
        requestId,
      ),
    );
  }

  @override
  Future<String> write({
    required String institutionId,
    required String requestId,
    required String assetId,
    required Uint8List bytes,
  }) async {
    final directory = await _requestDirectory(institutionId, requestId);
    await directory.create(recursive: true);
    final file = File(path.join(directory.path, '$assetId.bin'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<Uint8List> read(String localPath) => File(localPath).readAsBytes();

  @override
  Future<void> clearRequest(String institutionId, String requestId) async {
    final directory = await _requestDirectory(institutionId, requestId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
