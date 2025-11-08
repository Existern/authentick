import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/profile_update_request.dart';
import '../model/profile_update_response.dart';

part 'profile_service.g.dart';

@riverpod
ProfileService profileService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient);
}

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  /// Update user profile
  /// PUT /users/profile
  Future<ProfileUpdateResponse> updateProfile(
    ProfileUpdateRequest request,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/users/profile',
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
