import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection.dart';
import '../repository/connection_repository.dart';

part 'friends_view_model.g.dart';

/// Provider for managing friends list (accepted friend connections)
@riverpod
class FriendsViewModel extends _$FriendsViewModel {
  @override
  Future<List<Connection>> build() async {
    return await _fetchFriends();
  }

  Future<List<Connection>> _fetchFriends() async {
    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.getConnections(
      types: ['friend'],
      statuses: ['accepted'],
      page: 1,
      limit: 100,
    );
    return response.data.connections;
  }

  /// Refresh friends list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFriends();
    });
  }
}
