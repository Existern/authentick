import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection.dart';
import '../repository/connection_repository.dart';

part 'followers_view_model.g.dart';

/// Provider for managing followers list (accepted follower connections)
@riverpod
class FollowersViewModel extends _$FollowersViewModel {
  @override
  Future<List<Connection>> build() async {
    return await _fetchFollowers();
  }

  Future<List<Connection>> _fetchFollowers() async {
    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.getConnections(
      types: ['follower'],
      statuses: ['accepted'],
      page: 1,
      limit: 100,
    );
    return response.data.connections;
  }

  /// Refresh followers list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFollowers();
    });
  }
}
