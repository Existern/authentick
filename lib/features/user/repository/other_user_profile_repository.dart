import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/user_profile_response.dart';
import '../service/user_service.dart';

part 'other_user_profile_repository.g.dart';

@riverpod
Future<UserProfileResponse> otherUserProfile(
  Ref ref, {
  required String userId,
}) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserProfileById(userId);
}
