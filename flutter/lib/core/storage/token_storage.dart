import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const _kAccessToken  = 'access_token';
const _kRefreshToken = 'refresh_token';

class TokenStorage {
  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: access),
      _storage.write(key: _kRefreshToken, value: refresh),
    ]);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: _kAccessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  static Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
    ]);
  }

  static Future<bool> hasTokens() async {
    final refresh = await _storage.read(key: _kRefreshToken);
    return refresh != null && refresh.isNotEmpty;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
