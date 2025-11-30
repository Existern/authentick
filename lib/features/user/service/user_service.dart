import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/bulk_lookup_request.dart';
import '../model/bulk_lookup_response.dart';
import '../model/update_profile_request.dart';
import '../model/user_profile_response.dart';

part 'user_service.g.dart';

@riverpod
UserService userService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserService(apiClient);
}

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  /// Get authenticated user profile
  /// GET /users/profile
  Future<UserProfileResponse> getProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/users/profile',
      );
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update authenticated user profile
  /// PUT /users/profile
  /// Only include fields you want to update in the request
  Future<UserProfileResponse> updateProfile(
    UpdateProfileRequest request,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/users/profile',
        data: request.toJson(),
      );
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk lookup users by email addresses
  /// POST /users/bulk-lookup
  Future<BulkLookupResponse> bulkLookupUsers(BulkLookupRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/users/bulk-lookup',
        data: request.toJson(),
      );
      return BulkLookupResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
