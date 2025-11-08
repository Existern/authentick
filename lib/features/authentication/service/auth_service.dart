import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/auth_request.dart';
import '../model/auth_response.dart';

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
}
