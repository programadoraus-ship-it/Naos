import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase/supabase_service.dart';

class InstitutionAppearanceAssetGatewayException implements Exception {
  const InstitutionAppearanceAssetGatewayException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PreparedAppearanceAsset {
  const PreparedAppearanceAsset({
    required this.id,
    required this.kind,
    required this.slot,
    required this.storagePath,
  });
  final String id;
  final String kind;
  final int slot;
  final String storagePath;

  factory PreparedAppearanceAsset.fromJson(Map<String, dynamic> json) =>
      PreparedAppearanceAsset(
        id: json['id'] as String,
        kind: json['kind'] as String,
        slot: (json['slot'] as num).toInt(),
        storagePath: json['storage_path'] as String,
      );
}

class InstitutionAppearanceAssetGateway {
  InstitutionAppearanceAssetGateway({
    SupabaseClient? client,
    http.Client? httpClient,
    String? supabaseUrl,
  }) : _client = client ?? SupabaseService.client,
       _http = httpClient ?? http.Client(),
       _supabaseUrl = supabaseUrl ?? SupabaseService.supabaseUrl;

  final SupabaseClient _client;
  final http.Client _http;
  final String _supabaseUrl;

  Uri get _endpoint =>
      Uri.parse('$_supabaseUrl/functions/v1/institution-appearance-assets');

  Future<PreparedAppearanceAsset> upload({
    required String institutionId,
    required String requestId,
    required String assetId,
    required String kind,
    required int slot,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) {
      throw const InstitutionAppearanceAssetGatewayException(
        'Your session expired. Sign in again before uploading.',
      );
    }
    final request = http.MultipartRequest('POST', _endpoint)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll({
        'institution_id': institutionId,
        'request_id': requestId,
        'asset_id': assetId,
        'kind': kind,
        'slot': '$slot',
      })
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    final body = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InstitutionAppearanceAssetGatewayException(
        body['error']?.toString() ??
            'The appearance file could not be uploaded.',
      );
    }
    return PreparedAppearanceAsset.fromJson(
      Map<String, dynamic>.from(body['asset'] as Map),
    );
  }

  Future<void> cleanup(String assetId) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) {
      throw const InstitutionAppearanceAssetGatewayException(
        'Your session expired. Sign in again before cleaning up files.',
      );
    }
    final response = await _http.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': 'cleanup', 'asset_id': assetId}),
    );
    final body = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InstitutionAppearanceAssetGatewayException(
        body['error']?.toString() ?? 'File cleanup is still pending.',
      );
    }
  }

  Future<Uint8List> download(String signedUrl) async {
    final response = await _http.get(Uri.parse(signedUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const InstitutionAppearanceAssetGatewayException(
        'A saved appearance file could not be downloaded.',
      );
    }
    return response.bodyBytes;
  }

  Map<String, dynamic> _decode(String value) {
    try {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (_) {
      return {'error': 'The appearance service returned an invalid response.'};
    }
  }

  void close() => _http.close();
}
