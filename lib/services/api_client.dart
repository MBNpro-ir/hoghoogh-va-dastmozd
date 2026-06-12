import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const serverUrlPrefsKey = 'hvm_server_url';
  static const defaultServerUrl = 'https://hvm.local';
  static const accessTokenKey = 'hvm_access_token';
  static const refreshTokenKey = 'hvm_refresh_token';
  static const userKey = 'hvm_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(serverUrlPrefsKey)?.trim() ?? defaultServerUrl;
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverUrlPrefsKey, _normalizeUrl(url));
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async {
    final url = _normalizeUrl(serverUrl ?? await getServerUrl());
    final response = await http
        .post(
          Uri.parse('$url/api/auth/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(body['error']?.toString() ?? 'ورود ناموفق بود');
    }
    await _storage.write(
      key: accessTokenKey,
      value: body['access_token'] as String,
    );
    await _storage.write(
      key: refreshTokenKey,
      value: body['refresh_token'] as String,
    );
    await _storage.write(key: userKey, value: jsonEncode(body['user']));
    return body;
  }

  Future<Map<String, dynamic>> refresh() async {
    final refreshToken = await _storage.read(key: refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException('نشست منقضی شده است');
    }
    final response = await http
        .post(
          Uri.parse('${await getServerUrl()}/api/auth/refresh'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await clearSession();
      throw ApiException(body['error']?.toString() ?? 'تمدید نشست ناموفق بود');
    }
    await _storage.write(
      key: accessTokenKey,
      value: body['access_token'] as String,
    );
    await _storage.write(
      key: refreshTokenKey,
      value: body['refresh_token'] as String,
    );
    return body;
  }

  Future<String?> getAccessToken() => _storage.read(key: accessTokenKey);
  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: userKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> hasSession() async {
    final token = await _storage.read(key: accessTokenKey);
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userKey);
  }

  Future<http.Response> get(String path) async {
    final token = await getAccessToken();
    return http
        .get(
          Uri.parse('${await getServerUrl()}$path'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await getAccessToken();
    return http
        .post(
          Uri.parse('${await getServerUrl()}$path'),
          headers: _authHeaders(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
  }

  Map<String, String> _authHeaders(String? token) => {
    'content-type': 'application/json',
    if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
  };

  String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (normalized.isEmpty) normalized = defaultServerUrl;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'error': response.body.isEmpty
            ? 'خطا در ارتباط با سرور'
            : response.body,
      };
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();
