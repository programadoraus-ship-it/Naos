import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'institution_appearance_config.dart';

class PendingInstitutionAppearanceAsset {
  const PendingInstitutionAppearanceAsset({
    required this.id,
    required this.kind,
    required this.slot,
    required this.fileName,
    required this.localPath,
    required this.width,
    required this.height,
    required this.format,
  });

  final String id;
  final String kind;
  final int slot;
  final String fileName;
  final String localPath;
  final int width;
  final int height;
  final String format;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'slot': slot,
    'file_name': fileName,
    'local_path': localPath,
    'width': width,
    'height': height,
    'format': format,
  };

  factory PendingInstitutionAppearanceAsset.fromJson(
    Map<String, dynamic> json,
  ) => PendingInstitutionAppearanceAsset(
    id: json['id'] as String,
    kind: json['kind'] as String,
    slot: (json['slot'] as num).toInt(),
    fileName: json['file_name'] as String,
    localPath: json['local_path'] as String,
    width: (json['width'] as num).toInt(),
    height: (json['height'] as num).toInt(),
    format: json['format'] as String,
  );
}

class PendingInstitutionAppearanceRequest {
  const PendingInstitutionAppearanceRequest({
    required this.institutionId,
    required this.requestId,
    required this.expectedRevision,
    required this.config,
    required this.assets,
    required this.updatedAt,
    this.completeOnboarding = true,
  });

  final String institutionId;
  final String requestId;
  final int expectedRevision;
  final InstitutionAppearanceConfig config;
  final List<PendingInstitutionAppearanceAsset> assets;
  final DateTime updatedAt;
  final bool completeOnboarding;

  List<String> get assetIds => [for (final asset in assets) asset.id];

  Map<String, dynamic> toJson() => {
    'institution_id': institutionId,
    'request_id': requestId,
    'expected_revision': expectedRevision,
    'config': config.toJson(),
    'assets': [for (final asset in assets) asset.toJson()],
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'complete_onboarding': completeOnboarding,
  };

  factory PendingInstitutionAppearanceRequest.fromJson(
    Map<String, dynamic> json,
  ) => PendingInstitutionAppearanceRequest(
    institutionId: json['institution_id'] as String,
    requestId: json['request_id'] as String,
    expectedRevision: (json['expected_revision'] as num).toInt(),
    config: InstitutionAppearanceConfig.fromJson(
      Map<String, dynamic>.from(json['config'] as Map),
    ),
    assets: [
      for (final raw in json['assets'] as List? ?? const [])
        PendingInstitutionAppearanceAsset.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ),
    ],
    updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    completeOnboarding: json['complete_onboarding'] as bool? ?? true,
  );
}

abstract interface class InstitutionAppearancePendingRequestStore {
  Future<void> save(PendingInstitutionAppearanceRequest request);
  PendingInstitutionAppearanceRequest? load(String institutionId);
  Future<void> clear(String institutionId);
}

class InstitutionAppearancePendingStore
    implements InstitutionAppearancePendingRequestStore {
  InstitutionAppearancePendingStore(this.preferences);
  final SharedPreferences preferences;

  static const _prefix = 'naos.appearance.pending.v1.';

  String _key(String institutionId) => '$_prefix$institutionId';

  @override
  Future<void> save(PendingInstitutionAppearanceRequest request) async {
    await preferences.setString(
      _key(request.institutionId),
      jsonEncode(request.toJson()),
    );
  }

  @override
  PendingInstitutionAppearanceRequest? load(String institutionId) {
    final raw = preferences.getString(_key(institutionId));
    if (raw == null) return null;
    try {
      final request = PendingInstitutionAppearanceRequest.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (request.institutionId != institutionId) return null;
      return request;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear(String institutionId) =>
      preferences.remove(_key(institutionId));
}

abstract interface class InstitutionAppearanceFileVault {
  Future<String> write({
    required String institutionId,
    required String requestId,
    required String assetId,
    required Uint8List bytes,
  });
  Future<Uint8List> read(String localPath);
  Future<void> clearRequest(String institutionId, String requestId);
}
