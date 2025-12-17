import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../constants/constants.dart';
import 'sentry_service.dart';

/// Sentry interceptor for Dio to track all API calls, responses, and errors
class SentryDioInterceptor extends Interceptor {
  final bool captureRequestBody;
  final bool captureResponseBody;
  final bool captureHeaders;
  final List<int> captureFailedStatusCodes;

  SentryDioInterceptor({
    this.captureRequestBody = true,
    this.captureResponseBody = true,
    this.captureHeaders = true,
    this.captureFailedStatusCodes = const [400, 401, 403, 404, 500, 502, 503],
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add breadcrumb for the API request
    SentryService.instance.addBreadcrumb(
      message: '${options.method} ${options.path}',
      category: 'http.request',
      level: SentryLevel.info,
      data: {
        'method': options.method,
        'url': options.uri.toString(),
        if (captureHeaders && options.headers.isNotEmpty)
          'headers': _sanitizeHeaders(options.headers),
        if (captureRequestBody && options.data != null)
          'body': _sanitizeBody(options.data),
        if (options.queryParameters.isNotEmpty)
          'query_params': options.queryParameters,
      },
    );

    // Start a transaction for performance tracking
    final transaction = SentryService.instance.startTransaction(
      name: '${options.method} ${options.path}',
      operation: 'http.request',
      description: options.uri.toString(),
      data: {'method': options.method, 'url': options.uri.toString()},
    );

    // Store transaction in request extra for later use
    options.extra['sentry_transaction'] = transaction;
    options.extra['request_start_time'] = DateTime.now();

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestStartTime =
        response.requestOptions.extra['request_start_time'] as DateTime?;
    final duration = requestStartTime != null
        ? DateTime.now().difference(requestStartTime)
        : null;

    // Add breadcrumb for successful response
    SentryService.instance.addBreadcrumb(
      message:
          '${response.requestOptions.method} ${response.requestOptions.path} - ${response.statusCode}',
      category: 'http.response',
      level: SentryLevel.info,
      data: {
        'method': response.requestOptions.method,
        'url': response.requestOptions.uri.toString(),
        'status_code': response.statusCode,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
        if (captureHeaders && response.headers.map.isNotEmpty)
          'headers': _sanitizeHeaders(response.headers.map),
        if (captureResponseBody && response.data != null)
          'body': _sanitizeBody(response.data),
      },
    );

    // Finish the transaction
    final transaction =
        response.requestOptions.extra['sentry_transaction'] as ISentrySpan?;
    if (transaction != null) {
      transaction.status = SpanStatus.ok();
      transaction.finish();
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestStartTime =
        err.requestOptions.extra['request_start_time'] as DateTime?;
    final duration = requestStartTime != null
        ? DateTime.now().difference(requestStartTime)
        : null;

    final statusCode = err.response?.statusCode;
    final shouldCaptureError =
        statusCode == null || captureFailedStatusCodes.contains(statusCode);

    // Add breadcrumb for error
    SentryService.instance.addBreadcrumb(
      message:
          '${err.requestOptions.method} ${err.requestOptions.path} - ${err.type.name}',
      category: 'http.error',
      level: SentryLevel.error,
      data: {
        'method': err.requestOptions.method,
        'url': err.requestOptions.uri.toString(),
        'error_type': err.type.name,
        if (statusCode != null) 'status_code': statusCode,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
        if (err.message != null) 'error_message': err.message,
        if (captureResponseBody && err.response?.data != null)
          'response_body': _sanitizeBody(err.response!.data),
      },
    );

    // Capture the error in Sentry
    if (shouldCaptureError) {
      SentryService.instance.captureException(
        err,
        stackTrace: err.stackTrace,
        level: _getSentryLevel(statusCode),
        extras: {
          'method': err.requestOptions.method,
          'url': err.requestOptions.uri.toString(),
          'error_type': err.type.name,
          if (statusCode != null) 'status_code': statusCode,
          if (duration != null) 'duration_ms': duration.inMilliseconds,
          if (captureHeaders && err.requestOptions.headers.isNotEmpty)
            'request_headers': _sanitizeHeaders(err.requestOptions.headers),
          if (captureRequestBody && err.requestOptions.data != null)
            'request_body': _sanitizeBody(err.requestOptions.data),
          if (captureHeaders && err.response?.headers.map.isNotEmpty == true)
            'response_headers': _sanitizeHeaders(err.response!.headers.map),
          if (captureResponseBody && err.response?.data != null)
            'response_body': _sanitizeBody(err.response!.data),
        },
      );
    }

    // Finish the transaction with error status
    final transaction =
        err.requestOptions.extra['sentry_transaction'] as ISentrySpan?;
    if (transaction != null) {
      transaction.status = _getSpanStatus(statusCode);
      transaction.finish();
    }

    if (kDebugMode) {
      debugPrint(
        '${Constants.tag} [SentryDioInterceptor] Error captured: ${err.type.name}',
      );
    }

    handler.next(err);
  }

  /// Sanitize headers to remove sensitive information
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    // List of sensitive header keys to redact
    const sensitiveKeys = [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'api-key',
      'api_key',
      'token',
      'access-token',
      'refresh-token',
      'password',
      'secret',
    ];

    for (final key in sanitized.keys.toList()) {
      if (sensitiveKeys.any(
        (sensitive) => key.toLowerCase().contains(sensitive),
      )) {
        sanitized[key] = '[REDACTED]';
      }
    }

    return sanitized;
  }

  /// Sanitize request/response body to remove sensitive information
  dynamic _sanitizeBody(dynamic body) {
    try {
      if (body is Map) {
        // Create a DEEP copy using JSON encoding/decoding to avoid modifying original
        final sanitized =
            json.decode(json.encode(body)) as Map<String, dynamic>;

        // List of sensitive field keys to redact
        const sensitiveKeys = [
          'password',
          'password_confirmation',
          'current_password',
          'new_password',
          'old_password',
          'token',
          'tokens', // Added to catch the tokens object
          'access_token',
          'refresh_token',
          'api_key',
          'secret',
          'private_key',
          'card_number',
          'cvv',
          'ssn',
          'social_security',
        ];

        void sanitizeMap(Map<String, dynamic> map) {
          for (final key in map.keys.toList()) {
            if (sensitiveKeys.any(
              (sensitive) => key.toLowerCase().contains(sensitive),
            )) {
              map[key] = '[REDACTED]';
            } else if (map[key] is Map) {
              sanitizeMap(map[key] as Map<String, dynamic>);
            } else if (map[key] is List) {
              for (var i = 0; i < (map[key] as List).length; i++) {
                if (map[key][i] is Map) {
                  sanitizeMap(map[key][i] as Map<String, dynamic>);
                }
              }
            }
          }
        }

        sanitizeMap(sanitized);
        return sanitized;
      }

      // If body is too large, truncate it
      final bodyString = body.toString();
      if (bodyString.length > 10000) {
        return '${bodyString.substring(0, 10000)}... [TRUNCATED]';
      }

      return body;
    } catch (e) {
      return '[ERROR SANITIZING BODY]';
    }
  }

  /// Get Sentry level based on status code
  SentryLevel _getSentryLevel(int? statusCode) {
    if (statusCode == null) return SentryLevel.error;

    if (statusCode >= 500) return SentryLevel.error;
    if (statusCode >= 400) return SentryLevel.warning;
    return SentryLevel.info;
  }

  /// Get Span status based on HTTP status code
  SpanStatus _getSpanStatus(int? statusCode) {
    if (statusCode == null) return SpanStatus.unknownError();

    if (statusCode >= 200 && statusCode < 300) return SpanStatus.ok();
    if (statusCode == 400) return SpanStatus.invalidArgument();
    if (statusCode == 401) return SpanStatus.unauthenticated();
    if (statusCode == 403) return SpanStatus.permissionDenied();
    if (statusCode == 404) return SpanStatus.notFound();
    if (statusCode == 409) return SpanStatus.alreadyExists();
    if (statusCode == 429) return SpanStatus.resourceExhausted();
    if (statusCode == 499) return SpanStatus.cancelled();
    if (statusCode >= 500 && statusCode < 600)
      return SpanStatus.internalError();

    return SpanStatus.unknownError();
  }
}
