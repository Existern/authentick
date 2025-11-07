import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../../../environment/env.dart';

part 'api_client.g.dart';

@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient();
}

class ApiClient {
  static final String _baseUrl = '${Env.apiBaseUrl}${Env.apiVersion}';
  static const int _timeout = 30000; // 30 seconds

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: _timeout),
        receiveTimeout: const Duration(milliseconds: _timeout),
        sendTimeout: const Duration(milliseconds: _timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return RequestCancelledException();
      case DioExceptionType.connectionError:
        return NoInternetException();
      default:
        return UnknownException();
    }
  }

  Exception _handleResponseError(Response? response) {
    if (response == null) return UnknownException();

    // Try to extract error message from response
    String? errorMessage;
    try {
      final data = response.data;
      if (data is Map) {
        // Check for error object in response
        if (data['error'] != null && data['error'] is Map) {
          final error = data['error'] as Map;
          errorMessage = error['message'] as String? ?? error['details'] as String?;
        } else {
          errorMessage = data['message'] as String?;
        }
      }
    } catch (e) {
      debugPrint('${Constants.tag} [ApiClient] Error parsing error message: $e');
    }

    switch (response.statusCode) {
      case 400:
        return BadRequestException(errorMessage ?? 'Bad request');
      case 401:
        return UnauthorizedException();
      case 403:
        return ForbiddenException();
      case 404:
        return NotFoundException();
      case 500:
        return ServerException();
      default:
        return UnknownException();
    }
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('${Constants.tag} ┌────────────────────────────────────────────────────────');
    debugPrint('${Constants.tag} │ 📤 REQUEST [${options.method}]');
    debugPrint('${Constants.tag} │ URL: ${options.baseUrl}${options.path}');
    debugPrint('${Constants.tag} │ Headers: ${options.headers}');
    debugPrint('${Constants.tag} │ Body: ${options.data}');
    debugPrint('${Constants.tag} └────────────────────────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('${Constants.tag} ┌────────────────────────────────────────────────────────');
    debugPrint('${Constants.tag} │ 📥 RESPONSE [${response.statusCode}]');
    debugPrint('${Constants.tag} │ URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
    debugPrint('${Constants.tag} │ Data: ${response.data}');
    debugPrint('${Constants.tag} └────────────────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('${Constants.tag} ┌────────────────────────────────────────────────────────');
    debugPrint('${Constants.tag} │ ⚠️ ERROR [${err.response?.statusCode ?? "NO STATUS"}]');
    debugPrint('${Constants.tag} │ URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}');
    debugPrint('${Constants.tag} │ Type: ${err.type}');
    debugPrint('${Constants.tag} │ Message: ${err.message}');
    debugPrint('${Constants.tag} │ Response Data: ${err.response?.data}');
    debugPrint('${Constants.tag} └────────────────────────────────────────────────────────');
    super.onError(err, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Add any global error handling logic here
    super.onError(err, handler);
  }
}

// Custom Exceptions
class TimeoutException implements Exception {
  final String message = 'Connection timeout';
}

class NoInternetException implements Exception {
  final String message = 'No internet connection';
}

class RequestCancelledException implements Exception {
  final String message = 'Request cancelled';
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
}

class UnauthorizedException implements Exception {
  final String message = 'Unauthorized access';
}

class ForbiddenException implements Exception {
  final String message = 'Access forbidden';
}

class NotFoundException implements Exception {
  final String message = 'Resource not found';
}

class ServerException implements Exception {
  final String message = 'Internal server error';
}

class UnknownException implements Exception {
  final String message = 'An unknown error occurred';
}
