import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import 'secure_storage_service.dart';

/// Global session manager to handle authentication state and 401 errors
class SessionManager {
  SessionManager._();

  static final SessionManager _instance = SessionManager._();
  static SessionManager get instance => _instance;

  /// Global navigator key for navigation from anywhere in the app
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Flag to prevent multiple simultaneous logout operations
  bool _isLoggingOut = false;

  /// Handle 401 unauthorized error - clears all storage and redirects to login
  Future<void> handleUnauthorized() async {
    // Prevent multiple simultaneous logout operations
    if (_isLoggingOut) {
      debugPrint(
        '${Constants.tag} [SessionManager] ⚠️ Already logging out, skipping...',
      );
      return;
    }

    _isLoggingOut = true;

    try {
      debugPrint(
        '${Constants.tag} [SessionManager] 🚪 Handling 401 - Logging out user...',
      );

      // Clear all storage
      await _clearAllStorage();

      debugPrint(
        '${Constants.tag} [SessionManager] ✅ Storage cleared, redirecting to login...',
      );

      // Navigate to register/login screen
      _navigateToLogin();
    } catch (e, stackTrace) {
      debugPrint('${Constants.tag} [SessionManager] ❌ Error during logout: $e');
      debugPrint('$stackTrace');
    } finally {
      _isLoggingOut = false;
    }
  }

  /// Clear all stored authentication data
  Future<void> _clearAllStorage() async {
    // Clear secure storage
    const secureStorage = SecureStorageService();
    await secureStorage.clearTokens();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.authTokenKey);
    await prefs.remove(Constants.googleIdTokenKey);
    await prefs.remove(Constants.isLoginKey);
    await prefs.remove(Constants.isExistAccountKey);
    await prefs.remove(Constants.hasCompletedOnboardingKey);
    await prefs.remove(Constants.userIdKey);
    await prefs.remove(Constants.usernameKey);
    await prefs.remove(Constants.birthdayKey);
    await prefs.remove('auth_response');
    await prefs.remove('current_onboarding_step');
    await prefs.remove('first_name_key');
    await prefs.remove('last_name_key');
    await prefs.remove('email_key');
    await prefs.remove('profile_image_key');
    await prefs.remove('profile');
    await prefs.remove('user_profile_cache');

    debugPrint('${Constants.tag} [SessionManager] 🗑️ All storage cleared');
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Clear the navigation stack and go to register screen
      navigator.pushNamedAndRemoveUntil(Routes.register, (route) => false);
    } else {
      debugPrint(
        '${Constants.tag} [SessionManager] ⚠️ Navigator not available',
      );
    }
  }
}
