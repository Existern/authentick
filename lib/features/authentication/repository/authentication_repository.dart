import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '/environment/env.dart';
import '../model/auth_request.dart';
import '../model/auth_response.dart';
import '../service/auth_service.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthenticationRepository(authService);
}

class AuthenticationRepository {
  final AuthService _authService;

  const AuthenticationRepository(this._authService);

  /// Authenticate user with username and optional fields
  /// Calls the /auth/authenticate endpoint
  Future<AuthResponse> authenticate({
    required String username,
    String? dateOfBirth,
    String? inviteCode,
    String? firstName,
    String? lastName,
    String? bio,
    String? gender,
    String? location,
    String? phoneNumber,
    String? googleToken,
  }) async {
    try {
      // If googleToken is not provided, try to read it from SharedPreferences
      String? finalGoogleToken = googleToken;
      if (finalGoogleToken == null) {
        finalGoogleToken = await getGoogleIdToken();
        if (finalGoogleToken != null) {
          debugPrint('${Constants.tag} [AuthenticationRepository] 🔑 Found saved Google ID token: ${finalGoogleToken.substring(0, 20)}...');
        } else {
          debugPrint('${Constants.tag} [AuthenticationRepository] ⚠️ No Google ID token found in storage');
        }
      }

      final request = AuthRequest(
        username: username,
        dateOfBirth: dateOfBirth,
        inviteCode: inviteCode,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        gender: gender,
        location: location,
        phoneNumber: phoneNumber,
        googleToken: finalGoogleToken,
      );

      debugPrint('${Constants.tag} [AuthenticationRepository] 🔄 Calling API service...');
      final response = await _authService.authenticate(request);

      debugPrint('${Constants.tag} [AuthenticationRepository] 📦 Response received');
      debugPrint('${Constants.tag} [AuthenticationRepository] Success: ${response.success}');

      // Check if authentication was successful
      if (!response.success) {
        debugPrint('${Constants.tag} [AuthenticationRepository] ❌ API returned success=false');
        throw Exception('Authentication failed: API returned success=false');
      }

      debugPrint('${Constants.tag} [AuthenticationRepository] 💾 Saving auth token...');
      // Store authentication token
      await _saveAuthToken(response.data.token);

      debugPrint('${Constants.tag} [AuthenticationRepository] 💾 Saving user data...');
      // Store user data
      await _saveUserData(response.data.user);

      debugPrint('${Constants.tag} [AuthenticationRepository] ✅ Marking user as logged in...');
      // Mark as logged in
      await setIsLogin(true);
      await setIsExistAccount(true);

      debugPrint('${Constants.tag} [AuthenticationRepository] ✅ Authentication complete! User: ${response.data.user.username}');

      return response;
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [AuthenticationRepository] ❌❌❌ EXCEPTION CAUGHT ❌❌❌');
      debugPrint('${Constants.tag} [AuthenticationRepository] Error Type: ${error.runtimeType}');
      debugPrint('${Constants.tag} [AuthenticationRepository] Error Details: $error');
      debugPrint('${Constants.tag} [AuthenticationRepository] Stack Trace:');
      debugPrint('$stackTrace');
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
    await prefs.setString(Constants.usernameKey, user.username);

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
    if (user.profileImage != null) {
      await prefs.setString('profile_image_key', user.profileImage!);
    }
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdKey);
    if (userId == null) return null;

    return User(
      id: userId,
      username: prefs.getString(Constants.usernameKey) ?? '',
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

      // TODO: Send the ID token to your own backend for verification
      // For now, return a mock response
      return {
        'user': {
          'id': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'avatar_url': googleUser.photoUrl,
          'created_at': DateTime.now().toIso8601String(),
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

  Future<void> signOut() async {
    try {
      // TODO: Implement with your own backend
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
  }
}
