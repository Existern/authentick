import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../model/connection_request.dart';
import '../repository/connection_repository.dart';

part 'pending_connections_view_model.g.dart';

@riverpod
class PendingConnectionsViewModel extends _$PendingConnectionsViewModel {
  @override
  Future<List<ConnectionRequest>> build() async {
    return await _fetchPendingConnections();
  }

  Future<List<ConnectionRequest>> _fetchPendingConnections() async {
    try {
      final repository = ref.read(connectionRepositoryProvider);
      final response = await repository.getFriendRequests(
        status: 'pending',
        page: 1,
        limit: 100,
      );

      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Loaded ${response.length} pending friend requests',
      );

      return response;
    } catch (error) {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Error loading pending connections: $error',
      );
      rethrow;
    }
  }

  Future<void> acceptConnection(String requestId) async {
    try {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Accepting friend request: $requestId',
      );

      final repository = ref.read(connectionRepositoryProvider);
      await repository.acceptFriendRequest(requestId);

      // Refresh the list after accepting
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _fetchPendingConnections();
      });

      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Friend request accepted and list refreshed',
      );
    } catch (error) {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Error accepting friend request: $error',
      );
      rethrow;
    }
  }

  Future<void> rejectConnection(String requestId) async {
    try {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Rejecting friend request: $requestId',
      );

      final repository = ref.read(connectionRepositoryProvider);
      await repository.rejectFriendRequest(requestId);

      // Refresh the list after rejecting
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _fetchPendingConnections();
      });

      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Friend request rejected and list refreshed',
      );
    } catch (error) {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Error rejecting friend request: $error',
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchPendingConnections();
    });
  }
}
