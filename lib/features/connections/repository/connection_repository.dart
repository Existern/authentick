import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';

import '../model/connection_request.dart';
import '../model/connections_response.dart';
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

  /// Get connections
  /// [type] can be: all (default), friends, close_friends, followers, following
  Future<ConnectionsResponse> getConnections({String type = 'all'}) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Fetching connections...',
      );

      final response = await _connectionService.getConnections(type: type);

      debugPrint('${Constants.tag} [ConnectionRepository] ✅ Success');
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Friends: ${response.friends.length}',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Following: ${response.following.length}',
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

  /// Get pending friend requests
  /// [status] can be: pending (default), accepted, rejected, cancelled (comma-separated for multiple)
  Future<List<ConnectionRequest>> getFriendRequests({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Fetching friend requests...',
      );
      debugPrint(
        '${Constants.tag} [ConnectionRepository] Status: $status, Page: $page, Limit: $limit',
      );

      final response = await _connectionService.getFriendRequests(
        status: status,
        page: page,
        limit: limit,
      );

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Success: ${response.length} friend requests',
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

  /// Send a friend request
  Future<ConnectionRequest> sendFriendRequest(String targetUserId) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Sending friend request to: $targetUserId',
      );

      final response = await _connectionService.sendFriendRequest(targetUserId);

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Friend request sent',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ Failed to send friend request',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Error: $error');
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Accepting friend request: $requestId',
      );

      await _connectionService.acceptFriendRequest(requestId);

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Friend request accepted',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ Failed to accept friend request',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Error: $error');
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Rejecting friend request: $requestId',
      );

      await _connectionService.rejectFriendRequest(requestId);

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Friend request rejected',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ Failed to reject friend request',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Error: $error');
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Cancel a friend request
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] 🔄 Cancelling friend request: $requestId',
      );

      await _connectionService.cancelFriendRequest(requestId);

      debugPrint(
        '${Constants.tag} [ConnectionRepository] ✅ Friend request cancelled',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ConnectionRepository] ❌ Failed to cancel friend request',
      );
      debugPrint('${Constants.tag} [ConnectionRepository] Error: $error');
      debugPrint('${Constants.tag} [ConnectionRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  // Legacy methods for backward compatibility
  /// Get pending connection requests (legacy - use getFriendRequests instead)
  @Deprecated('Use getFriendRequests instead')
  Future<List<ConnectionRequest>> getPendingConnections({
    int page = 1,
    int limit = 20,
  }) async {
    return getFriendRequests(status: 'pending', page: page, limit: limit);
  }

  /// Accept a connection request (legacy - use acceptFriendRequest instead)
  @Deprecated('Use acceptFriendRequest instead')
  Future<void> acceptConnection(String requestId) async {
    return acceptFriendRequest(requestId);
  }

  /// Reject a connection request (legacy - use rejectFriendRequest instead)
  @Deprecated('Use rejectFriendRequest instead')
  Future<void> rejectConnection(String requestId) async {
    return rejectFriendRequest(requestId);
  }
}
