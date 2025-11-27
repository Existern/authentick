import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import '../repository/connection_repository.dart';

part 'following_view_model.g.dart';

/// Provider for managing following list (users you are following)
@riverpod
class FollowingViewModel extends _$FollowingViewModel {
  @override
  Future<List<ConnectionUser>> build() async {
    return await _fetchFollowing();
  }

  Future<List<ConnectionUser>> _fetchFollowing() async {
    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.getConnections();
    return response.following;
  }

  /// Refresh following list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFollowing();
    });
  }
}
