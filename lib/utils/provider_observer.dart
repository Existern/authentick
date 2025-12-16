import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../constants/constants.dart';
import '../services/sentry_service.dart';

base class AppObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    debugPrint(
      '${Constants.tag} Provider ${context.provider.name} was initialized with $value',
    );
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    debugPrint(
      '${Constants.tag} Provider ${context.provider.name} was disposed',
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    debugPrint(
      '${Constants.tag} Provider ${context.provider.name} updated from $previousValue to $newValue',
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '${Constants.tag} Provider ${context.provider.name} threw $error at $stackTrace',
    );

    // Capture provider errors in Sentry for production debugging
    SentryService.instance.captureException(
      error,
      stackTrace: stackTrace,
      level: SentryLevel.error,
      extras: {
        'provider':
            context.provider.name ?? context.provider.runtimeType.toString(),
        'error_source': 'riverpod_provider',
      },
    );
  }
}
