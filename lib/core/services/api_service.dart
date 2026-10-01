import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const _requestTimeout = Duration(seconds: 30);

  ApiService({
    String? baseUrl,
    String? Function()? tokenReader,
    http.Client? client,
  }) : _baseUrl = (baseUrl ?? _configuredBaseUrl).replaceFirst(
         RegExp(r'/$'),
         '',
       ),
       _tokenReader = tokenReader,
       _client = client ?? http.Client();

  final String _baseUrl;
  final String? Function()? _tokenReader;
  final http.Client _client;

  bool get hasToken => (_tokenReader?.call() ?? '').isNotEmpty;

  static const _environmentBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
  );
  static String get _configuredBaseUrl => _environmentBaseUrl.isNotEmpty
      ? _environmentBaseUrl
      : (kIsWeb || defaultTargetPlatform != TargetPlatform.android
            ? 'http://127.0.0.1:8000/api/v1'
            : 'http://10.0.2.2:8000/api/v1');

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    final token = _tokenReader?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
    );

    final streamed = await _client.send(request).timeout(_requestTimeout);
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_tokenReader?.call() case final token? when token.isNotEmpty)
          'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client
        .send(request)
        .timeout(_requestTimeout);
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() {
    try {
      final response = jsonDecode(message) as Map<String, dynamic>;
      final errors = response['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
      return response['message']?.toString() ?? message;
    } on FormatException {
      return message;
    }
  }
}
