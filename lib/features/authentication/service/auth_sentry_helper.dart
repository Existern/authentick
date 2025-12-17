import '../../../services/sentry_service.dart';

/// Helper class for tracking authentication events in Sentry
class AuthSentryHelper {
  /// Call after successful login
  static Future<void> onLoginSuccess({
    required String userId,
    required String email,
    String? username,
    String? loginMethod,
  }) async {
    await SentryService.instance.setUser(
      id: userId,
      email: email,
      username: username,
      extras: {
        'login_time': DateTime.now().toIso8601String(),
        'login_method': loginMethod ?? 'email',
      },
    );

    SentryService.instance.addBreadcrumb(
      message: 'User logged in successfully',
      category: 'auth',
      data: {'user_id': userId, 'method': loginMethod ?? 'email'},
    );

    await SentryService.instance.setTags({
      'authenticated': 'true',
      'login_method': loginMethod ?? 'email',
    });
  }

  /// Call when login fails
  static Future<void> onLoginFailure(
    dynamic error,
    StackTrace? stackTrace, {
    String? email,
    String? reason,
  }) async {
    await SentryService.instance.captureException(
      error,
      stackTrace: stackTrace,
      extras: {
        'operation': 'login',
        'email_prefix': email != null && email.length > 2
            ? '${email.substring(0, 2)}***'
            : 'unknown',
        'failure_reason': reason ?? 'unknown',
      },
    );
  }

  /// Call on logout
  static Future<void> onLogout() async {
    SentryService.instance.addBreadcrumb(
      message: 'User logged out',
      category: 'auth',
    );

    await SentryService.instance.clearUser();

    await SentryService.instance.setTags({'authenticated': 'false'});
  }

  /// Call when registration succeeds
  static Future<void> onRegisterSuccess({
    required String userId,
    required String email,
  }) async {
    SentryService.instance.addBreadcrumb(
      message: 'User registered successfully',
      category: 'auth',
      data: {'user_id': userId},
    );
  }

  /// Call when registration fails
  static Future<void> onRegisterFailure(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    await SentryService.instance.captureException(
      error,
      stackTrace: stackTrace,
      extras: {'operation': 'register', 'failure_reason': reason ?? 'unknown'},
    );
  }
}
