import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connections_response.dart';
import '../repository/connection_repository.dart';

part 'connections_view_model.g.dart';

/// Shared provider for all connections data (friends, followers, following)
/// This prevents multiple API calls by fetching all data once
@riverpod
class ConnectionsViewModel extends _$ConnectionsViewModel {
  @override
  Future<ConnectionsResponse> build() async {
    return await _fetchConnections();
  }

  Future<ConnectionsResponse> _fetchConnections() async {
    final repository = ref.read(connectionRepositoryProvider);
    return await repository.getConnections();
  }

  /// Refresh all connections data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchConnections();
    });
  }

  /// Remove a friendship
  Future<void> removeFriendship(String friendUserId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.removeFriendship(friendUserId);
    // Refresh connections data after removing friend
    await refresh();
  }

  /// Follow a user
  Future<void> followUser(String userId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.followUser(userId);
    // Refresh connections data after following
    await refresh();
  }

  /// Unfollow a user
  Future<void> unfollowUser(String userId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.unfollowUser(userId);
    // Refresh connections data after unfollowing
    await refresh();
  }
}
