import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import '../repository/connection_repository.dart';

part 'friends_view_model.g.dart';

/// Provider for managing friends list (accepted friend connections)
@riverpod
class FriendsViewModel extends _$FriendsViewModel {
  @override
  Future<List<ConnectionUser>> build() async {
    return await _fetchFriends();
  }

  Future<List<ConnectionUser>> _fetchFriends() async {
    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.getConnections();
    return response.friends;
  }

  /// Refresh friends list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFriends();
    });
  }
}
