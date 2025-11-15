import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../model/connection.dart';
import '../repository/connection_repository.dart';

part 'pending_connections_view_model.g.dart';

@riverpod
class PendingConnectionsViewModel extends _$PendingConnectionsViewModel {
  @override
  Future<List<Connection>> build() async {
    return await _fetchPendingConnections();
  }

  Future<List<Connection>> _fetchPendingConnections() async {
    try {
      final repository = ref.read(connectionRepositoryProvider);
      final response = await repository.getPendingConnections(
        page: 1,
        limit: 100,
      );

      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Loaded ${response.data.connections.length} pending connections',
      );

      return response.data.connections;
    } catch (error) {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Error loading pending connections: $error',
      );
      rethrow;
    }
  }

  Future<void> acceptConnection(String connectionId) async {
    try {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Accepting connection: $connectionId',
      );

      final repository = ref.read(connectionRepositoryProvider);
      await repository.acceptConnection(connectionId);

      // Refresh the list after accepting
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _fetchPendingConnections();
      });

      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Connection accepted and list refreshed',
      );
    } catch (error) {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Error accepting connection: $error',
      );
      rethrow;
    }
  }

  Future<void> rejectConnection(String connectionId) async {
    try {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Rejecting connection: $connectionId',
      );

      final repository = ref.read(connectionRepositoryProvider);
      await repository.rejectConnection(connectionId);

      // Refresh the list after rejecting
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _fetchPendingConnections();
      });

      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Connection rejected and list refreshed',
      );
    } catch (error) {
      debugPrint(
        '${Constants.tag} [PendingConnectionsViewModel] Error rejecting connection: $error',
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
