import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/auth_request.dart';
import '../model/auth_response.dart';
import '../model/refresh_request.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
}

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Authenticate user with username, birthday, and optional invite code
  /// POST /auth/authenticate
  Future<AuthResponse> authenticate(AuthRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/authenticate',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  /// POST /auth/refresh
  Future<AuthResponse> refreshToken(RefreshRequest request) async {
    try {
      // Include Authorization header if access token is provided
      final options = request.accessToken != null
          ? Options(headers: {'Authorization': 'Bearer ${request.accessToken}'})
          : null;

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: request.toJson(),
        options: options,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
