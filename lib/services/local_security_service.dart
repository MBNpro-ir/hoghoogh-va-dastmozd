import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSecurityService {
  static const _hashKey = 'hvm_local_hash_v1';
  static const _saltKey = 'hvm_local_salt_v1';
  static const _iterationsKey = 'hvm_local_iterations_v1';
  static const _methodKey = 'hvm_local_method_v1';
  static const _biometricKey = 'hvm_biometric_enabled_v1';
  static const _requiresUnlockKey = 'hvm_requires_unlock_v1';
  static const _hashIterations = 120000;
  static const _legacyHashIterations = 250000;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> hasCredential() async =>
      (await _storage.read(key: _hashKey)) != null;

  Future<bool> biometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) == true;
  }

  Future<bool> canUseBiometrics() async {
    final available = await _localAuth.canCheckBiometrics;
    final supported = await _localAuth.isDeviceSupported();
    return available && supported;
  }

  Future<void> setRequiresUnlock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requiresUnlockKey, value);
  }

  Future<bool> requiresUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_requiresUnlockKey) ?? true;
  }

  Future<void> createCredential({
    required String value,
    required LocalCredentialMethod method,
    bool enableBiometrics = false,
  }) async {
    final salt = _randomBytes(16);
    final saltRaw = base64Encode(salt);
    final hash = await compute(
      _hashCredential,
      _LocalHashJob(value, saltRaw, _hashIterations),
    );
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _methodKey, value: method.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iterationsKey, _hashIterations);
    await prefs.setBool(
      _biometricKey,
      enableBiometrics && await canUseBiometrics(),
    );
  }

  Future<bool> verifyCredential(String value) async {
    final saltRaw = await _storage.read(key: _saltKey);
    final expected = await _storage.read(key: _hashKey);
    if (saltRaw == null || expected == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final iterations = prefs.getInt(_iterationsKey) ?? _legacyHashIterations;
    final actual = await compute(
      _hashCredential,
      _LocalHashJob(value, saltRaw, iterations),
    );
    if (_safeEquals(actual, expected)) return true;
    if (iterations == _legacyHashIterations) return false;
    final legacyActual = await compute(
      _hashCredential,
      _LocalHashJob(value, saltRaw, _legacyHashIterations),
    );
    return _safeEquals(legacyActual, expected);
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await biometricsEnabled() || !await canUseBiometrics()) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason:
            'برای باز کردن HvM اثر انگشت یا تشخیص چهره را تأیید کنید',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> clearCredential() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _methodKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_iterationsKey);
    await prefs.setBool(_biometricKey, false);
  }

  Future<LocalCredentialMethod?> getMethod() async {
    final raw = await _storage.read(key: _methodKey);
    return LocalCredentialMethod.values
        .cast<LocalCredentialMethod?>()
        .firstWhere((method) => method?.name == raw, orElse: () => null);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  bool _safeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    if (aBytes.length != bBytes.length) return false;
    var diff = 0;
    for (var i = 0; i < aBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
  }
}

enum LocalCredentialMethod { pin, password }

class _LocalHashJob {
  final String value;
  final String saltBase64;
  final int iterations;

  const _LocalHashJob(this.value, this.saltBase64, this.iterations);
}

String _hashCredential(_LocalHashJob job) {
  final digest = _pbkdf2Sha256(
    Uint8List.fromList(utf8.encode(job.value)),
    base64Decode(job.saltBase64),
    job.iterations,
    32,
  );
  return base64Encode(digest);
}

Uint8List _pbkdf2Sha256(
  Uint8List password,
  Uint8List salt,
  int iterations,
  int dkLen,
) {
  final hmacLen = sha256.convert(const <int>[]).bytes.length;
  final blocks = (dkLen / hmacLen).ceil();
  final output = Uint8List(blocks * hmacLen);
  var blockIndex = 1;

  for (var block = 0; block < blocks; block++) {
    final saltBlock = Uint8List(salt.length + 4);
    saltBlock.setRange(0, salt.length, salt);
    saltBlock[salt.length] = blockIndex >> 24;
    saltBlock[salt.length + 1] = blockIndex >> 16;
    saltBlock[salt.length + 2] = blockIndex >> 8;
    saltBlock[salt.length + 3] = blockIndex;

    final first = Uint8List.fromList(
      Hmac(sha256, password).convert(saltBlock).bytes,
    );
    final blockHash = Uint8List.fromList(first);

    for (var i = 1; i < iterations; i++) {
      final next = Uint8List.fromList(
        Hmac(sha256, password).convert(blockHash).bytes,
      );
      for (var j = 0; j < hmacLen; j++) {
        blockHash[j] ^= next[j];
      }
    }

    output.setRange(block * hmacLen, (block + 1) * hmacLen, blockHash);
    blockIndex++;
  }

  return output.sublist(0, dkLen);
}
