import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection.dart';
import '../repository/connection_repository.dart';

part 'following_view_model.g.dart';

/// Provider for managing following list (users you are following)
@riverpod
class FollowingViewModel extends _$FollowingViewModel {
  @override
  Future<List<Connection>> build() async {
    return await _fetchFollowing();
  }

  Future<List<Connection>> _fetchFollowing() async {
    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.getConnections(
      type: 'following',
      page: 1,
      limit: 100,
    );
    return response.data.connections;
  }

  /// Refresh following list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFollowing();
    });
  }
}
