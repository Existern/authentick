import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../model/connection.dart';
import '../model/pending_connections_response.dart';
import '../service/connection_service.dart';

part 'connection_repository.g.dart';

@riverpod
ConnectionRepository connectionRepository(Ref ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return ConnectionRepository(connectionService);
}

class ConnectionRepository {
  final ConnectionService _connectionService;

  const ConnectionRepository(this._connectionService);

  /// Get connections with filters
  Future<PendingConnectionsResponse> getConnections({
    List<String>? types,
    List<String>? statuses,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Fetching connections...',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Types: $types, Statuses: $statuses',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Page: $page, Limit: $limit',
      );

      final response = await _connectionService.getConnections(
        types: types,
        statuses: statuses,
        page: page,
        limit: limit,
      );

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Success: ${response.success}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Total connections: ${response.data.totalCount}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Connections in this page: ${response.data.connections.length}',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ EXCEPTION CAUGHT ❌',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Error Details: $error',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Get pending connection requests
  Future<PendingConnectionsResponse> getPendingConnections({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Fetching pending connections...',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Page: $page, Limit: $limit',
      );

      final response = await _connectionService.getPendingConnections(
        page: page,
        limit: limit,
      );

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Success: ${response.success}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Total connections: ${response.data.totalCount}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Connections in this page: ${response.data.connections.length}',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ EXCEPTION CAUGHT ❌',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Error Details: $error',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Accept a connection request
  Future<void> acceptConnection(String connectionId) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Accepting connection: $connectionId',
      );

      await _connectionService.acceptConnection(connectionId);

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Connection accepted',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ Failed to accept connection',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Error: $error',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Reject a connection request
  Future<void> rejectConnection(String connectionId) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Rejecting connection: $connectionId',
      );

      await _connectionService.rejectConnection(connectionId);

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Connection rejected',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ Failed to reject connection',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Error: $error',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
