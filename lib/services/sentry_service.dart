import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../environment/env.dart';

/// Service for managing Sentry error tracking and monitoring
class SentryService {
  SentryService._();

  static final SentryService instance = SentryService._();

  /// Initialize Sentry with proper configuration
  static Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();

    await SentryFlutter.init((options) {
      // Your Sentry DSN (add this to your environment variables)
      options.dsn = Env.sentryDsn;

      // Set the environment (prod, staging, dev)
      options.environment = kReleaseMode ? 'production' : 'development';

      // Set the release version
      options.release = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Sample rate for performance monitoring (1.0 = 100%)
      // Production optimized: 20% to reduce quota usage
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;

      // Enable automatic breadcrumbs
      options.enableAutoSessionTracking = true;

      // Capture failed HTTP requests
      options.captureFailedRequests = true;

      // Send user information
      options.sendDefaultPii =
          false; // Set to true if you want to send user IP, etc.

      // Attach screenshots on errors (mobile only)
      options.attachScreenshot = true;
      options.screenshotQuality = SentryScreenshotQuality.medium;

      // Attach view hierarchy on errors
      options.attachViewHierarchy = true;

      // Enable performance monitoring for database operations
      options.enableAutoPerformanceTracing = true;

      // Set before send callback to filter or modify events
      options.beforeSend = (event, hint) {
        // You can filter events here
        // Return null to not send the event
        // For example, don't send events in debug mode unless explicitly enabled
        if (kDebugMode && !const bool.fromEnvironment('SEND_SENTRY_IN_DEBUG')) {
          return null;
        }
        return event;
      };

      // Set before breadcrumb callback to filter breadcrumbs
      options.beforeBreadcrumb = (breadcrumb, hint) {
        // Filter out sensitive breadcrumbs if needed
        return breadcrumb;
      };

      // Maximum breadcrumbs to keep
      options.maxBreadcrumbs = 100;

      // Enable native crash reporting
      options.enableNativeCrashHandling = true;

      // Debug mode (prints diagnostic information)
      options.debug = kDebugMode;

      // Attach stack trace to messages
      options.attachStacktrace = true;

      // Consider what data you want to send
      options.sendClientReports = true;
    });
  }

  /// Set user information for error tracking
  Future<void> setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(id: id, email: email, username: username, data: extras),
      );
    });
  }

  /// Clear user information (e.g., on logout)
  Future<void> clearUser() async {
    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Add custom context to error reports
  Future<void> setContext(String key, Map<String, dynamic> context) async {
    await Sentry.configureScope((scope) {
      scope.setContexts(key, context);
    });
  }

  /// Add a breadcrumb for tracking user actions
  void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel? level,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level ?? SentryLevel.info,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Capture an exception manually
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    SentryLevel? level,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'hint': hint}) : null,
      withScope: (scope) {
        if (level != null) {
          scope.level = level;
        }
        if (extras != null) {
          extras.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Capture a message manually
  Future<void> captureMessage(
    String message, {
    SentryLevel? level,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureMessage(
      message,
      level: level ?? SentryLevel.info,
      withScope: (scope) {
        if (extras != null) {
          extras.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Start a transaction for performance monitoring
  ISentrySpan startTransaction({
    required String name,
    required String operation,
    String? description,
    Map<String, dynamic>? data,
  }) {
    final transaction = Sentry.startTransaction(
      name,
      operation,
      description: description,
      bindToScope: true,
    );

    if (data != null) {
      data.forEach((key, value) {
        transaction.setData(key, value);
      });
    }

    return transaction;
  }

  /// Create a child span within a transaction
  ISentrySpan startSpan({
    required ISentrySpan parent,
    required String operation,
    String? description,
  }) {
    return parent.startChild(operation, description: description);
  }

  /// Add tags for filtering in Sentry dashboard
  Future<void> setTags(Map<String, String> tags) async {
    await Sentry.configureScope((scope) {
      tags.forEach((key, value) {
        scope.setTag(key, value);
      });
    });
  }

  /// Set a single tag
  Future<void> setTag(String key, String value) async {
    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Close Sentry (typically not needed, called automatically)
  Future<void> close() async {
    await Sentry.close();
  }
}
