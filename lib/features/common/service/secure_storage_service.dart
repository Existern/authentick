import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing secure storage of sensitive data like tokens
class SecureStorageService {
  const SecureStorageService();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'secure_access_token';
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _tokenExpiryKey = 'secure_token_expiry';

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: _tokenExpiryKey,
      value: expiry.millisecondsSinceEpoch.toString(),
    );
  }

  /// Get token expiry timestamp
  Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString == null) return null;

    final milliseconds = int.tryParse(expiryString);
    if (milliseconds == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  /// Save all tokens at once
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);

    if (expiresIn != null) {
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));
      await saveTokenExpiry(expiry);
    }
  }

  /// Check if access token is expired or about to expire
  /// Returns true if token will expire within the next 5 minutes
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    // Consider token expired if it will expire in the next 5 minutes
    final threshold = DateTime.now().add(const Duration(minutes: 5));
    return expiry.isBefore(threshold);
  }

  /// Check if user has valid tokens stored
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
