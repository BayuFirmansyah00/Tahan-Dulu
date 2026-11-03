import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error HTTP API backend (status + pesan server bila ada).
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    Map<String, List<String>>? fieldErrors,
  }) : fieldErrors = fieldErrors ?? const {};

  final String message;
  final int? statusCode;

  /// Rincian validasi per field (mis. {'email': ['...taken.']}).
  final Map<String, List<String>> fieldErrors;

  /// true bila field tertentu memiliki error validasi.
  bool hasFieldError(String field) => fieldErrors[field]?.isNotEmpty ?? false;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Klien JSON tipis untuk API Laravel (format {success, message, data}).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.onUnauthorized,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  /// Dipanggil bila server merespons 401 Unauthorized (token kadaluarsa
  /// atau tidak valid). Digunakan untuk memaksa logout lokal & navigasi ke
  /// halaman login.
  final void Function()? onUnauthorized;

  static const Duration timeout = Duration(seconds: 15);

  Map<String, String> _headers([String? token]) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Decode body JSON; lempar [ApiException] bila status >= 400.
  /// Memanggil [onUnauthorized] bila status 401.
  Map<String, dynamic> _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? {} : jsonDecode(res.body);
    } on FormatException {
      throw ApiException(
        'Respons server tidak valid.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode == 401) {
      onUnauthorized?.call();
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Sesi habis atau tidak valid. Silakan login ulang.';
      throw ApiException(
        message,
        statusCode: res.statusCode,
        fieldErrors: _fieldErrors(body),
      );
    }

    if (res.statusCode >= 400) {
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Permintaan gagal (${res.statusCode}).';
      throw ApiException(
        message,
        statusCode: res.statusCode,
        fieldErrors: _fieldErrors(body),
      );
    }
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        'Format respons tak dikenal.',
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  /// Ambil peta error validasi {"field": ["pesan", ...]} bila ada.
  static Map<String, List<String>> _fieldErrors(dynamic body) {
    if (body is! Map) return const {};
    final errors = body['errors'];
    if (errors is! Map) return const {};
    final result = <String, List<String>>{};
    errors.forEach((key, value) {
      if (value is List) {
        result['$key'] = value.whereType<String>().toList(growable: false);
      } else if (value is String) {
        result['$key'] = [value];
      }
    });
    return result;
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    try {
      final res = await _http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi.');
    } on http.ClientException catch (e) {
      throw ApiException('Tidak dapat menghubungi server: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    try {
      final res = await _http
          .get(Uri.parse('$baseUrl$path'), headers: _headers(token))
          .timeout(timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi.');
    } on http.ClientException catch (e) {
      throw ApiException('Tidak dapat menghubungi server: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    try {
      final res = await _http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi.');
    } on http.ClientException catch (e) {
      throw ApiException('Tidak dapat menghubungi server: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    try {
      final res = await _http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi.');
    } on http.ClientException catch (e) {
      throw ApiException('Tidak dapat menghubungi server: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    try {
      final res = await _http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
          )
          .timeout(timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi.');
    } on http.ClientException catch (e) {
      throw ApiException('Tidak dapat menghubungi server: ${e.message}');
    }
  }

  void close() => _http.close();
}
