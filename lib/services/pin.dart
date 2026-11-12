import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// PIN зберігається тільки як хеш із сіллю в захищеному сховищі (Android Keystore / iOS Keychain).
/// Захищене сховище не потрапляє в резервну копію, тож на новому телефоні PIN треба задати знову.
class PinService {
  static const _key = 'vespr_pin';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static final _auth = LocalAuthentication();

  static String _hash(String salt, String pin) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  static Future<void> setPin(String pin) async {
    final r = Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
    await _storage.write(key: _key, value: '$salt.${_hash(salt, pin)}');
  }

  // Після відновлення копії на новому телефоні ключ шифрування сховища інший, і читання падає.
  // Тоді чистимо сховище: PIN просто доведеться задати знову.
  static Future<String?> _read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  static Future<bool> hasPin() async => (await _read()) != null;

  static Future<bool> check(String pin) async {
    final v = await _read();
    if (v == null) return false;
    final i = v.indexOf('.');
    if (i < 0) return false;
    return _hash(v.substring(0, i), pin) == v.substring(i + 1);
  }

  static Future<void> clear() => _storage.delete(key: _key);

  static Future<bool> biometricAvailable() async {
    if (kIsWeb) return false; // у браузері Face ID і відбитка нема, лишається PIN
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Face ID / відбиток або код самого телефону (для «Забула PIN?»)
  static Future<bool> deviceUnlock() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(localizedReason: 'Підтверди, що це ти, щоб задати новий PIN', options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> biometricUnlock() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Відкрити Vespr',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
