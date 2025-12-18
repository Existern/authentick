import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '../../../services/sentry_service.dart';
import '../../common/remote/api_client.dart';
import '../../common/service/secure_storage_service.dart';
import '../../common/service/session_manager.dart';
import '../../onboarding/model/onboarding_step_response.dart'
    as onboarding_model;
import '../model/auth_request.dart';
import '../model/auth_response.dart';
import '../model/refresh_request.dart';
import '../service/auth_service.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthenticationRepository(authService);
}

class AuthenticationRepository {
  final AuthService _authService;
  final SecureStorageService _secureStorage = const SecureStorageService();

  const AuthenticationRepository(this._authService);

  /// Authenticate user with Google token
  /// Calls the /auth/authenticate endpoint
  Future<AuthResponse> authenticate({String? googleToken}) async {
    try {
      // If googleToken is not provided, try to read it from SharedPreferences
      String? finalGoogleToken = googleToken;
      if (finalGoogleToken == null) {
        finalGoogleToken = await getGoogleIdToken();
        if (finalGoogleToken != null) {
          debugPrint(
            '${Constants.tag} [AuthenticationRepository] 🔑 Found saved Google ID token: ${finalGoogleToken.substring(0, 20)}...',
          );
        } else {
          debugPrint(
            '${Constants.tag} [AuthenticationRepository] ⚠️ No Google ID token found in storage',
          );
        }
      }

      final request = AuthRequest(googleToken: finalGoogleToken);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🔄 Calling API service...',
      );
      final response = await _authService.authenticate(request);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 📦 Response received',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] Success: ${response.success}',
      );

      // Check if authentication was successful
      if (!response.success) {
        debugPrint(
          '${Constants.tag} [AuthenticationRepository] ❌ API returned success=false',
        );
        throw Exception('Authentication failed: API returned success=false');
      }

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 💾 Saving auth tokens to secure storage...',
      );
      // Store authentication tokens in secure storage
      await _secureStorage.saveTokens(
        accessToken: response.data.tokens.accessToken,
        refreshToken: response.data.tokens.refreshToken,
        expiresIn: response.data.tokens.expiresIn,
      );
      // Also save to SharedPreferences for backward compatibility with interceptor
      await _saveAuthToken(response.data.tokens.accessToken);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 💾 Saving user data...',
      );
      // Store user data
      await _saveUserData(response.data.user);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 💾 Saving auth response...',
      );
      // Store the complete auth response including onboarding data
      await saveAuthResponse(response);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🗑️ Clearing old profile caches...',
      );
      // Clear old profile caches to force reload with new data
      await _clearProfileCaches();

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ✅ Marking user as logged in...',
      );
      // Mark as logged in
      await setIsLogin(true);
      await setIsExistAccount(true);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ✅ Authentication complete! User: ${response.data.user.username}',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ❌❌❌ EXCEPTION CAUGHT ❌❌❌',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] Error Details: $error',
      );
      debugPrint('${Constants.tag} [AuthenticationRepository] Stack Trace:');
      debugPrint('$stackTrace');

      // Send error to Sentry
      await SentryService.instance.captureException(
        error,
        stackTrace: stackTrace,
        extras: {
          'operation': 'authenticate',
          'has_google_token': googleToken != null,
        },
      );

      // Handle authentication-related errors
      await handleAuthenticationError(error);

      rethrow;
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    // TODO: Implement with your own backend
    throw Exception('Magic link authentication not implemented yet');
  }

  // Helper methods for storing auth data
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.authTokenKey);
  }

  Future<String?> getGoogleIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.googleIdTokenKey);
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.userIdKey, user.id);
    if (user.username != null) {
      await prefs.setString(Constants.usernameKey, user.username!);
    }

    if (user.dateOfBirth != null) {
      await prefs.setString(Constants.birthdayKey, user.dateOfBirth!);
    }
    if (user.firstName != null) {
      await prefs.setString('first_name_key', user.firstName!);
    }
    if (user.lastName != null) {
      await prefs.setString('last_name_key', user.lastName!);
    }
    if (user.email != null) {
      await prefs.setString('email_key', user.email!);
    }
    if (user.profileImageThumbnail != null) {
      await prefs.setString('profile_image_key', user.profileImageThumbnail!);
    }
  }

  Future<void> saveAuthResponse(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert the entire auth response to JSON and save it
    await prefs.setString(
      'auth_response',
      jsonEncode({
        'success': authResponse.success,
        'data': {
          'tokens': authResponse.data.tokens.toJson(),
          'user': authResponse.data.user.toJson(),
          if (authResponse.data.onboarding != null)
            'onboarding': authResponse.data.onboarding!.toJson(),
        },
        if (authResponse.meta != null)
          'meta': {
            'request_id': authResponse.meta!.requestId,
            'timestamp': authResponse.meta!.timestamp,
          },
      }),
    );
  }

  Future<AuthResponse?> getAuthResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('auth_response');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } catch (e) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] Error parsing auth response: $e',
      );
      return null;
    }
  }

  /// Update only the onboarding data in the stored auth response
  /// This is useful when we fetch fresh onboarding progress from API
  Future<void> updateOnboardingInAuthResponse(
    onboarding_model.OnboardingData onboardingData,
  ) async {
    final authResponse = await getAuthResponse();
    if (authResponse == null) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] No auth response to update',
      );
      return;
    }

    // Convert OnboardingData to Onboarding format
    final onboarding = Onboarding(
      completed: onboardingData.completed,
      completedAt: onboardingData.completedAt,
      userId: onboardingData.userId,
      steps: onboardingData.steps
          .map(
            (step) => OnboardingStep(
              step: step.step,
              displayName: step.displayName,
              status: step.status,
              skippable: step.skippable,
              completedAt: step.completedAt,
            ),
          )
          .toList(),
    );

    // Create updated auth response with new onboarding data
    final updatedAuthResponse = AuthResponse(
      success: authResponse.success,
      data: AuthData(
        tokens: authResponse.data.tokens,
        user: authResponse.data.user,
        onboarding: onboarding,
      ),
      meta: authResponse.meta,
    );

    // Save the updated auth response
    await saveAuthResponse(updatedAuthResponse);

    debugPrint(
      '${Constants.tag} [AuthenticationRepository] Updated onboarding data in stored auth response',
    );
  }

  Future<void> _clearProfileCaches() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear profile repository cache
    await prefs.remove('profile');
    // Clear user profile repository cache
    await prefs.remove('user_profile_cache');
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdKey);
    if (userId == null) return null;

    return User(
      id: userId,
      username: prefs.getString(Constants.usernameKey),
      dateOfBirth: prefs.getString(Constants.birthdayKey),
      firstName: prefs.getString('first_name_key'),
      lastName: prefs.getString('last_name_key'),
      email: prefs.getString('email_key'),
      profileImage: prefs.getString('profile_image_key'),
      createdAt: '',
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    // TODO: Implement with your own backend
    // Return a mock user object for now
    return {
      'user': {
        'id': 'mock_user_id',
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize with server client ID (required for Android)
      await googleSignIn.initialize();

      // Authenticate the user
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('id_token_not_found'.tr());
      }

      // Save the Google ID token for later use in the authentication flow
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.googleIdTokenKey, idToken);
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Google ID token saved: ${idToken.substring(0, 20)}...',
      );

      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] 🚀 Calling authenticate API...',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Google Token: ${idToken.substring(0, 20)}...',
      );

      // Call the authenticate API with google_token
      final authResponse = await authenticate(googleToken: idToken);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] ✅ API Response received!',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Success: ${authResponse.success}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Access Token: ${authResponse.data.tokens.accessToken}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] User JSON: ${authResponse.data.user.toJson()}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] User ID: ${authResponse.data.user.id}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Username: ${authResponse.data.user.username}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Email: ${authResponse.data.user.email}',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Request ID: ${authResponse.meta?.requestId ?? "N/A"}',
      );

      // Return the response in the expected format
      return {
        'user': {
          'id': authResponse.data.user.id,
          'email': authResponse.data.user.email,
          'name': googleUser.displayName,
          'avatar_url': googleUser.photoUrl,
          'created_at': authResponse.data.user.createdAt,
        },
      };
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Error: $error',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] StackTrace: $stackTrace',
      );
      throw Exception('$error');
    }
  }

  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('id_token_not_found'.tr());
      }

      // TODO: Send the ID token to your own backend for verification
      // For now, return a mock response
      return {
        'user': {
          'id': credential.userIdentifier ?? 'apple_user_id',
          'email': credential.email ?? 'user@apple.com',
          'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
              .trim(),
          'created_at': DateTime.now().toIso8601String(),
        },
      };
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  /// Refresh access token using refresh token
  Future<AuthResponse> refreshAccessToken() async {
    try {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🔄 Refreshing access token...',
      );

      // Get both access and refresh tokens from secure storage
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final request = RefreshRequest(
        refreshToken: refreshToken,
        accessToken: accessToken,
      );
      final response = await _authService.refreshToken(request);

      if (!response.success) {
        throw Exception('Token refresh failed: API returned success=false');
      }

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 💾 Saving refreshed tokens...',
      );
      // Save new tokens
      await _secureStorage.saveTokens(
        accessToken: response.data.tokens.accessToken,
        refreshToken: response.data.tokens.refreshToken,
        expiresIn: response.data.tokens.expiresIn,
      );
      // Also update SharedPreferences
      await _saveAuthToken(response.data.tokens.accessToken);

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ✅ Token refresh complete!',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ❌ Token refresh failed: $error',
      );
      debugPrint('$stackTrace');

      // Clear tokens and trigger complete logout when refresh fails
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🚪 Token refresh failed, triggering complete logout...',
      );
      await _secureStorage.clearTokens();
      await setIsLogin(false);

      // Use session manager for complete logout flow including navigation
      SessionManager.instance.handleUnauthorized();

      rethrow;
    }
  }

  /// Check if user has stored tokens (for auto-login)
  /// Checks both secure storage and SharedPreferences fallback
  Future<bool> hasStoredTokens() async {
    final hasSecureTokens = await _secureStorage.hasValidTokens();
    if (hasSecureTokens) return true;

    // Fallback check in SharedPreferences
    final authResponse = await getAuthResponse();
    final hasFallbackTokens = authResponse != null &&
        authResponse.data.tokens.accessToken.isNotEmpty &&
        authResponse.data.tokens.refreshToken.isNotEmpty;

    if (hasFallbackTokens) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ⚠️ Tokens missing in secure storage but found in SharedPreferences fallback',
      );
    }

    return hasFallbackTokens;
  }

  /// Try to auto-login using stored refresh token
  /// Simply checks if tokens exist - actual token validation happens via onboarding API call
  Future<bool> tryAutoLogin() async {
    try {
      // First try secure storage
      bool hasTokens = await _secureStorage.hasValidTokens();

      if (!hasTokens) {
        debugPrint(
          '${Constants.tag} [AuthenticationRepository] ⚠️ No tokens in secure storage, checking fallback...',
        );

        // Try fallback from SharedPreferences (auth_response)
        final authResponse = await getAuthResponse();
        if (authResponse != null &&
            authResponse.data.tokens.accessToken.isNotEmpty &&
            authResponse.data.tokens.refreshToken.isNotEmpty) {
          debugPrint(
            '${Constants.tag} [AuthenticationRepository] 🔄 Recovering tokens from SharedPreferences to secure storage...',
          );

          // Restore to secure storage
          await _secureStorage.saveTokens(
            accessToken: authResponse.data.tokens.accessToken,
            refreshToken: authResponse.data.tokens.refreshToken,
            expiresIn: authResponse.data.tokens.expiresIn,
          );

          hasTokens = true;
        }
      }

      if (!hasTokens) {
        debugPrint(
          '${Constants.tag} [AuthenticationRepository] ⚠️ No stored tokens found anywhere for auto-login',
        );
        // Clear login state since we have no tokens
        await setIsLogin(false);
        return false;
      }

      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ✅ Tokens found, proceeding with auto-login',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] Token validation will be handled by onboarding API call',
      );

      // Mark as logged in - actual token validation will happen when onboarding API is called
      await setIsLogin(true);
      return true;
    } catch (error) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] ❌ Auto-login failed: $error',
      );
      // Use session manager for complete logout flow when auto-login fails
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🚪 Auto-login failed, triggering complete logout...',
      );
      SessionManager.instance.handleUnauthorized();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear secure storage tokens
      await _secureStorage.clearTokens();
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Constants.authTokenKey);
      await prefs.remove(Constants.googleIdTokenKey);
      await prefs.remove('auth_response');
      // Clear login state
      setIsLogin(false);
      Purchases.logOut();
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isLoginKey) ?? false;
  }

  Future<void> setIsLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isLoginKey, value);
  }

  Future<bool> isExistAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isExistAccountKey) ?? false;
  }

  Future<void> setIsExistAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isExistAccountKey, value);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.hasCompletedOnboardingKey) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.hasCompletedOnboardingKey, value);
    // Clear current step when onboarding is completed
    if (value) {
      await prefs.remove('current_onboarding_step');
    }
  }

  /// Set flag to show first moment popup
  Future<void> setShouldShowFirstMomentPopup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.shouldShowFirstMomentPopupKey, value);
  }

  /// Save the current onboarding step
  Future<void> saveCurrentOnboardingStep(String step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_onboarding_step', step);
    debugPrint(
      '${Constants.tag} [AuthenticationRepository] Saved current onboarding step: $step',
    );
  }

  /// Get the saved current onboarding step
  Future<String?> getCurrentOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_onboarding_step');
  }

  /// Clear the saved current onboarding step
  Future<void> clearCurrentOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_onboarding_step');
    await prefs.remove('intro_page_index');
  }

  /// Save the intro page index
  Future<void> saveIntroPageIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intro_page_index', index);
    debugPrint(
      '${Constants.tag} [AuthenticationRepository] Saved intro page index: $index',
    );
  }

  /// Get the saved intro page index
  Future<int?> getIntroPageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('intro_page_index');
  }

  /// Helper method to handle authentication-related errors
  /// Automatically logs out user and clears all authentication data
  Future<void> handleAuthenticationError(Object? error) async {
    if (error == null) return;

    final errorString = error.toString().toLowerCase();
    final isAuthError =
        errorString.contains('unauthorized') ||
        errorString.contains('token') ||
        errorString.contains('401') ||
        errorString.contains('authentication failed') ||
        errorString.contains('invalid token') ||
        errorString.contains('expired token');

    if (isAuthError) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🚪 Authentication error detected: $error',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository] 🚪 Triggering complete logout...',
      );

      // Use session manager for complete logout flow
      SessionManager.instance.handleUnauthorized();
    }
  }
}
