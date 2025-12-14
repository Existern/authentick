import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/connection_request.dart';
import '../model/connections_response.dart';
import '../model/friendship.dart';
import '../model/discover_users_response.dart';
import '../model/search_users_response.dart';

part 'connection_service.g.dart';

@riverpod
ConnectionService connectionService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConnectionService(apiClient);
}

class ConnectionService {
  final ApiClient _apiClient;

  ConnectionService(this._apiClient);

  /// Get connections (friends, following, close friends)
  /// GET /connections/users
  /// [type] can be: all (default), friends, close_friends, followers, following
  Future<ConnectionsResponse> getConnections({String type = 'all'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/connections/users',
        queryParameters: {'type': type},
      );
      // Response is wrapped in success/data/meta structure
      final data = response['data'] as Map<String, dynamic>;
      return ConnectionsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// List friend requests
  /// GET /connections/friend-requests
  /// [status] can be: pending (default), accepted, rejected, cancelled (comma-separated for multiple)
  Future<List<ConnectionRequest>> getFriendRequests({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/connections/friend-requests',
        queryParameters: {'status': status, 'page': page, 'limit': limit},
      );
      // Response is wrapped in success/data/meta structure
      final data = response['data'] as List<dynamic>;
      return data
          .map(
            (json) => ConnectionRequest.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Send a friend request
  /// POST /connections/friend-requests
  Future<ConnectionRequest> sendFriendRequest(String targetUserId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/connections/friend-requests',
        data: {'target_user_id': targetUserId},
      );
      // Response is wrapped in success/data/meta structure
      final data = response['data'] as Map<String, dynamic>;
      return ConnectionRequest.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Accept or reject a friend request
  /// POST /connections/friend-requests/{id}
  Future<void> respondToFriendRequest(
    String requestId, {
    required String action, // 'accept' or 'reject'
  }) async {
    try {
      await _apiClient.post<void>(
        '/connections/friend-requests/$requestId',
        data: {'action': action},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Accept a friend request
  /// POST /connections/friend-requests/{id}
  Future<void> acceptFriendRequest(String requestId) async {
    return respondToFriendRequest(requestId, action: 'accept');
  }

  /// Reject a friend request
  /// POST /connections/friend-requests/{id}
  Future<void> rejectFriendRequest(String requestId) async {
    return respondToFriendRequest(requestId, action: 'reject');
  }

  /// Cancel a friend request sent by the authenticated user
  /// DELETE /connections/friend-requests/{id}
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _apiClient.delete<void>('/connections/friend-requests/$requestId');
    } catch (e) {
      rethrow;
    }
  }

  /// List friendships for the authenticated user
  /// GET /connections/friends
  Future<List<Friendship>> getFriendships({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/connections/friends',
        queryParameters: {'page': page, 'limit': limit},
      );
      // Response is wrapped in success/data/meta structure
      final data = response['data'] as List<dynamic>;
      return data
          .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a friendship
  /// DELETE /connections/friends/{id}
  Future<void> removeFriendship(String friendUserId) async {
    try {
      await _apiClient.delete<void>('/connections/friends/$friendUserId');
    } catch (e) {
      rethrow;
    }
  }

  /// Follow a user
  /// POST /connections/follow/{id}
  Future<void> followUser(String userId) async {
    try {
      await _apiClient.post<void>('/connections/follow/$userId');
    } catch (e) {
      rethrow;
    }
  }

  /// Unfollow a user
  /// DELETE /connections/follow/{id}
  Future<void> unfollowUser(String userId) async {
    try {
      await _apiClient.delete<void>('/connections/follow/$userId');
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a friend as a close friend
  /// POST /connections/close-friends/{id}
  Future<void> addCloseFriend(String userId) async {
    try {
      await _apiClient.post<void>('/connections/close-friends/$userId');
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a user from close friends
  /// DELETE /connections/close-friends/{id}
  Future<void> removeCloseFriend(String userId) async {
    try {
      await _apiClient.delete<void>('/connections/close-friends/$userId');
    } catch (e) {
      rethrow;
    }
  }

  /// Discover new users
  /// GET /discover/users
  /// Returns up to 10 users per page you are not already friends with, following, close friends with, or blocking/blocked by.
  Future<DiscoverUsersResponse> discoverUsers({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/discover/users',
        queryParameters: {'page': page},
      );
      return DiscoverUsersResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Search users
  /// GET /users/search
  /// Searches users by username, first name, or last name using case-insensitive partial matching.
  Future<SearchUsersResponse> searchUsers({
    required String query,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/users/search',
        queryParameters: {'q': query, 'page': page, 'limit': limit},
      );
      return SearchUsersResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
