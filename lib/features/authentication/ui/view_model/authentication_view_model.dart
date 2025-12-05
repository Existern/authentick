import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/constants/constants.dart';
import '/extensions/string_extension.dart';
import '/features/profile/ui/view_model/profile_view_model.dart';
import '../../repository/authentication_repository.dart';
import '../../ui/state/authentication_state.dart';

part 'authentication_view_model.g.dart';

@riverpod
class AuthenticationViewModel extends _$AuthenticationViewModel {
  @override
  FutureOr<AuthenticationState> build() async {
    return const AuthenticationState();
  }

  Future<void> signInWithMagicLink(String email) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(
      () => authRepo.signInWithMagicLink(email),
    );

    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    state = const AsyncData(AuthenticationState());
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(
      () => authRepo.verifyOtp(
        email: email,
        token: token,
        isRegister: isRegister,
      ),
    );
    handleResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signInWithGoogle);

    // Handle authentication errors specifically
    if (result is AsyncError && _isAuthenticationError(result.error)) {
      await _handleAuthenticationError(result.error);
    }

    handleResult(result);
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signInWithApple);

    // Handle authentication errors specifically
    if (result is AsyncError && _isAuthenticationError(result.error)) {
      await _handleAuthenticationError(result.error);
    }

    handleResult(result);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signOut);

    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    state = const AsyncData(AuthenticationState());
  }

  /// Helper method to check if an error is authentication-related
  bool _isAuthenticationError(Object? error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
        errorString.contains('token') ||
        errorString.contains('401') ||
        errorString.contains('authentication failed') ||
        errorString.contains('invalid token') ||
        errorString.contains('expired token');
  }

  /// Handle authentication-related errors by logging out the user
  Future<void> _handleAuthenticationError(Object? error) async {
    if (error == null) return;

    debugPrint(
      '${Constants.tag} [AuthenticationViewModel] 🚪 Auth error detected: $error',
    );

    try {
      final authRepo = ref.read(authenticationRepositoryProvider);
      await authRepo.signOut();
      debugPrint(
        '${Constants.tag} [AuthenticationViewModel] ✅ User logged out due to auth error',
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [AuthenticationViewModel] ⚠️ Error during logout: $e',
      );
    }
  }

  void handleResult(AsyncValue result) async {
    debugPrint(
      '${Constants.tag} [AuthenticationViewModel.handleResult] result: $result',
    );
    if (result is AsyncError) {
      // Check if it's an authentication/token related error
      if (_isAuthenticationError(result.error)) {
        debugPrint(
          '${Constants.tag} [AuthenticationViewModel.handleResult] 🚪 Token/auth error detected, triggering logout...',
        );

        // Handle authentication error asynchronously
        _handleAuthenticationError(result.error);
      }

      state = AsyncError(
        result.error?.toString() ?? 'Unknown error',
        StackTrace.current,
      );
      return;
    }

    final Map<String, dynamic>? authResponse = result.value;
    debugPrint(
      '${Constants.tag} [AuthenticationViewModel.handleResult] authResponse: $authResponse',
    );
    if (authResponse == null) {
      state = AsyncError('unexpected_error_occurred'.tr(), StackTrace.current);
      return;
    }

    final isExistAccount = await ref
        .read(authenticationRepositoryProvider)
        .isExistAccount();
    if (!isExistAccount) {
      ref.read(authenticationRepositoryProvider).setIsExistAccount(true);
    }

    final userData = authResponse['user'] as Map<String, dynamic>?;
    String? name = userData?['name'];
    String? avatar = userData?['avatar_url'];
    String? email = userData?['email'];

    ref.read(authenticationRepositoryProvider).setIsLogin(true);
    ref
        .read(profileViewModelProvider.notifier)
        .updateProfile(
          email: email?.orEmpty() ?? '',
          name: name,
          avatar: avatar,
        );

    state = AsyncData(
      AuthenticationState(
        authResponse: authResponse,
        isRegisterSuccessfully: !isExistAccount,
        isSignInSuccessfully: true,
      ),
    );
  }
}
