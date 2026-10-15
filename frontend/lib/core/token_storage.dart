import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT lives in the platform keystore (Android Keystore / iOS Keychain), never in SharedPreferences.
class TokenStorage {
  static const _key = 'mamacare_jwt';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> clear() => _storage.delete(key: _key);
}
