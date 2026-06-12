import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSecurityService {
  static const _hashKey = 'hvm_local_hash_v1';
  static const _saltKey = 'hvm_local_salt_v1';
  static const _methodKey = 'hvm_local_method_v1';
  static const _biometricKey = 'hvm_biometric_enabled_v1';
  static const _requiresUnlockKey = 'hvm_requires_unlock_v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
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
    final hash = _hash(value, salt);
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _methodKey, value: method.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _biometricKey,
      enableBiometrics && await canUseBiometrics(),
    );
  }

  Future<bool> verifyCredential(String value) async {
    final saltRaw = await _storage.read(key: _saltKey);
    final expected = await _storage.read(key: _hashKey);
    if (saltRaw == null || expected == null) return false;
    final actual = _hash(value, base64Decode(saltRaw));
    return _safeEquals(actual, expected);
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await biometricsEnabled() || !await canUseBiometrics()) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason:
            'برای باز کردن HvM اثر انگشت یا تشخیص چهره را تأیید کنید',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
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
    await prefs.setBool(_biometricKey, false);
  }

  Future<LocalCredentialMethod?> getMethod() async {
    final raw = await _storage.read(key: _methodKey);
    return LocalCredentialMethod.values
        .cast<LocalCredentialMethod?>()
        .firstWhere((method) => method?.name == raw, orElse: () => null);
  }

  String _hash(String value, Uint8List salt) {
    final digest = _pbkdf2Sha256(utf8.encode(value), salt, 250000, 32);
    return base64Encode(digest);
  }

  Uint8List _pbkdf2Sha256(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int dkLen,
  ) {
    final blockLen = sha256.blockSize;
    final blocks = (dkLen / blockLen).ceil();
    final output = Uint8List(blocks * blockLen);
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
        for (var j = 0; j < blockLen; j++) {
          blockHash[j] ^= next[j];
        }
      }

      output.setRange(block * blockLen, (block + 1) * blockLen, blockHash);
      blockIndex++;
    }

    return output.sublist(0, dkLen);
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
