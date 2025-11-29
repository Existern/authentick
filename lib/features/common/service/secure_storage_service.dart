import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../constants/constants.dart';

/// Service for managing secure storage of sensitive data like tokens
class SecureStorageService {
  const SecureStorageService();

  // resetOnError helps recover from corrupted storage on problematic devices
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
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
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token == null || token.isEmpty) {
        debugPrint(
          '${Constants.tag} [SecureStorage] ⚠️ No access token found in secure storage',
        );
      }
      return token;
    } catch (e) {
      debugPrint(
        '${Constants.tag} [SecureStorage] ❌ Error reading access token: $e',
      );
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (token == null || token.isEmpty) {
        debugPrint(
          '${Constants.tag} [SecureStorage] ⚠️ No refresh token found in secure storage',
        );
      }
      return token;
    } catch (e) {
      debugPrint(
        '${Constants.tag} [SecureStorage] ❌ Error reading refresh token: $e',
      );
      return null;
    }
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

  /// Save all tokens at once with retry logic for device compatibility
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) async {
    debugPrint('${Constants.tag} [SecureStorage] 💾 Saving tokens...');

    try {
      // Save access token with retry
      await _saveWithRetry(_accessTokenKey, accessToken, 'access token');

      // Verify access token was saved
      final savedAccessToken = await getAccessToken();
      if (savedAccessToken != accessToken) {
        debugPrint(
          '${Constants.tag} [SecureStorage] ⚠️ Access token verification failed, retrying...',
        );
        await _saveWithRetry(_accessTokenKey, accessToken, 'access token');
      }

      // Save refresh token with retry
      await _saveWithRetry(_refreshTokenKey, refreshToken, 'refresh token');

      // Verify refresh token was saved
      final savedRefreshToken = await getRefreshToken();
      if (savedRefreshToken != refreshToken) {
        debugPrint(
          '${Constants.tag} [SecureStorage] ⚠️ Refresh token verification failed, retrying...',
        );
        await _saveWithRetry(_refreshTokenKey, refreshToken, 'refresh token');
      }

      if (expiresIn != null) {
        final expiry = DateTime.now().add(Duration(seconds: expiresIn));
        await saveTokenExpiry(expiry);
      }

      debugPrint(
        '${Constants.tag} [SecureStorage] ✅ All tokens saved successfully',
      );
    } catch (e, stackTrace) {
      debugPrint('${Constants.tag} [SecureStorage] ❌ Error saving tokens: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Save with retry logic for better reliability on problematic devices
  Future<void> _saveWithRetry(
    String key,
    String value,
    String tokenName, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _storage.write(key: key, value: value);

        // Verify the write was successful
        final savedValue = await _storage.read(key: key);
        if (savedValue == value) {
          debugPrint(
            '${Constants.tag} [SecureStorage] ✅ $tokenName saved (attempt $attempt)',
          );
          return;
        } else {
          debugPrint(
            '${Constants.tag} [SecureStorage] ⚠️ $tokenName save verification failed (attempt $attempt)',
          );
        }
      } catch (e) {
        debugPrint(
          '${Constants.tag} [SecureStorage] ⚠️ Error saving $tokenName (attempt $attempt): $e',
        );
        if (attempt == maxRetries) {
          rethrow;
        }
        // Small delay before retry
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
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
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final hasTokens =
          accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty;

      debugPrint(
        '${Constants.tag} [SecureStorage] hasValidTokens: $hasTokens (access: ${accessToken != null && accessToken.isNotEmpty}, refresh: ${refreshToken != null && refreshToken.isNotEmpty})',
      );
      return hasTokens;
    } catch (e) {
      debugPrint(
        '${Constants.tag} [SecureStorage] ❌ Error checking tokens: $e',
      );
      return false;
    }
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
