import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import '../repository/connection_repository.dart';

part 'followers_view_model.g.dart';

/// Provider for managing followers list (accepted follower connections)
@riverpod
class FollowersViewModel extends _$FollowersViewModel {
  @override
  Future<List<ConnectionUser>> build() async {
    return await _fetchFollowers();
  }

  Future<List<ConnectionUser>> _fetchFollowers() async {
    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.getConnections();
    return response.followers;
  }

  /// Refresh followers list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFollowers();
    });
  }
}
