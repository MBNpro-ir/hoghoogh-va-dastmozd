import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const serverUrlPrefsKey = 'hvm_server_url';
  static const defaultServerUrl = 'https://payroll.mbnpro.ir';
  static const accessTokenKey = 'hvm_access_token';
  static const refreshTokenKey = 'hvm_refresh_token';
  static const userKey = 'hvm_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String> getServerUrl() async => defaultServerUrl;

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverUrlPrefsKey, _normalizeUrl(defaultServerUrl));
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async {
    final url = _normalizeUrl(serverUrl ?? defaultServerUrl);
    await setServerUrl(url);
    final response = await _safeRequest(
      () => http
          .post(
            Uri.parse('$url/api/auth/login'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 20)),
    );
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _friendlyApiMessage(body['error']?.toString(), response.statusCode),
        response.statusCode,
      );
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

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getAccessToken();
    final serverUrl = await getServerUrl();
    final response = await _safeRequest(
      () => http
          .post(
            Uri.parse('$serverUrl/api/auth/change-password'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _friendlyApiMessage(body['error']?.toString(), response.statusCode),
        response.statusCode,
      );
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
      throw ApiException('نشست منقضی شده است', 401);
    }
    final serverUrl = await getServerUrl();
    final response = await _safeRequest(
      () => http
          .post(
            Uri.parse('$serverUrl/api/auth/refresh'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 20)),
    );
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await clearSession();
      throw ApiException(
        _friendlyApiMessage(body['error']?.toString(), response.statusCode),
        response.statusCode,
      );
    }
    await _storage.write(
      key: accessTokenKey,
      value: body['access_token'] as String,
    );
    await _storage.write(
      key: refreshTokenKey,
      value: body['refresh_token'] as String,
    );
    if (body['user'] is Map) {
      await _storage.write(key: userKey, value: jsonEncode(body['user']));
    }
    return body;
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: refreshTokenKey);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await post('/api/auth/logout', {'refresh_token': refreshToken});
      } catch (_) {}
    }
    await clearSession();
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

  Future<http.Response> get(String path) {
    return _sendWithRefresh(() async {
      final token = await getAccessToken();
      return http
          .get(
            Uri.parse('${await getServerUrl()}$path'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) {
    return _sendWithRefresh(() async {
      final token = await getAccessToken();
      return http
          .post(
            Uri.parse('${await getServerUrl()}$path'),
            headers: _authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) {
    return _sendWithRefresh(() async {
      final token = await getAccessToken();
      return http
          .patch(
            Uri.parse('${await getServerUrl()}$path'),
            headers: _authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function() send,
  ) async {
    var response = await send();
    if (response.statusCode != 401) return response;
    try {
      await refresh();
      response = await send();
    } catch (_) {
      await clearSession();
    }
    return response;
  }

  Map<String, String> _authHeaders(String? token) => {
    'content-type': 'application/json',
    if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
  };

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      throw ApiException(
        'ارتباط با سرور زمان‌بر شد. اینترنت یا وضعیت سرور را بررسی کنید.',
      );
    } on HandshakeException {
      throw ApiException(
        'ارتباط امن با سرور برقرار نشد. تاریخ و ساعت دستگاه یا گواهی سرور را بررسی کنید.',
      );
    } on SocketException {
      throw ApiException(
        'ارتباط با سرور برقرار نشد. اتصال اینترنت، VPN یا DNS را بررسی کنید.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(_friendlyNetworkMessage(e.message));
    } catch (_) {
      throw ApiException('خطا در ارتباط با سرور. دوباره تلاش کنید.');
    }
  }

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
            ? _friendlyApiMessage(null, response.statusCode)
            : response.body,
      };
    }
  }

  String _friendlyApiMessage(String? rawMessage, int statusCode) {
    final message = rawMessage?.trim() ?? '';
    final lower = message.toLowerCase();
    if (lower.contains('invalid credentials')) {
      return 'نام کاربری یا رمز عبور اشتباه است';
    }
    if (lower.contains('username and password')) {
      return 'نام کاربری و رمز عبور الزامی است';
    }
    if (lower.contains('company is inactive')) {
      return 'شرکت غیرفعال یا حذف شده است. با مدیر سیستم تماس بگیرید.';
    }
    if (lower.contains('account is temporarily locked')) {
      return 'حساب به‌صورت موقت قفل شده است. کمی بعد دوباره تلاش کنید.';
    }
    if (lower.contains('password must be at least')) {
      return 'رمز باید حداقل ۱۲ کاراکتر و شامل حرف بزرگ، حرف کوچک، عدد و نماد باشد';
    }
    if (lower.contains('unauthorized') ||
        lower.contains('session required') ||
        lower.contains('refresh_token')) {
      return 'نشست شما منقضی شده است. دوباره وارد شوید.';
    }
    if (lower.contains('forbidden')) {
      return 'شما به این بخش دسترسی ندارید.';
    }
    if (message.isNotEmpty) return message;
    if (statusCode == 401) return 'نام کاربری یا رمز عبور اشتباه است';
    if (statusCode == 423) return 'حساب یا شرکت شما در حال حاضر فعال نیست';
    if (statusCode >= 500) {
      return 'خطای داخلی سرور رخ داد. کمی بعد دوباره تلاش کنید.';
    }
    return 'خطا در ارتباط با سرور';
  }

  String _friendlyNetworkMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('connection') && lower.contains('aborted')) {
      return 'ارتباط با سرور قطع شد. اینترنت، VPN یا وضعیت سرور را بررسی کنید.';
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('nodename') ||
        lower.contains('getaddrinfo')) {
      return 'آدرس سرور پیدا نشد. DNS یا اتصال اینترنت را بررسی کنید.';
    }
    if (lower.contains('connection refused')) {
      return 'سرور در دسترس نیست یا سرویس آن متوقف شده است.';
    }
    return 'ارتباط با سرور برقرار نشد. اینترنت یا وضعیت سرور را بررسی کنید.';
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 0]);

  @override
  String toString() => message;
}

String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();
