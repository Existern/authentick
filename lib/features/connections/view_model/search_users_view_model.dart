import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import '../repository/connection_repository.dart';
import 'connections_view_model.dart';
import 'pending_connections_view_model.dart';

part 'search_users_view_model.g.dart';

/// Provider for searching users
@riverpod
class SearchUsersViewModel extends _$SearchUsersViewModel {
  String _lastQuery = '';
  int _currentPage = 1;
  List<ConnectionUser> _allUsers = [];
  bool _hasMore = true;
  int _totalCount = 0;

  @override
  Future<List<ConnectionUser>> build() async {
    // Return empty list initially
    return [];
  }

  /// Search users with a query
  Future<void> search(String query, {int limit = 5}) async {
    // Query must be at least 3 characters
    if (query.length < 3) {
      state = const AsyncValue.data([]);
      return;
    }

    // If it's a new query, reset pagination
    if (query != _lastQuery) {
      _lastQuery = query;
      _currentPage = 1;
      _allUsers = [];
      _hasMore = true;
      _totalCount = 0;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _performSearch(query, limit);
    });
  }

  Future<List<ConnectionUser>> _performSearch(String query, int limit) async {
    if (!_hasMore) return _allUsers;

    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.searchUsers(
      query: query,
      page: _currentPage,
      limit: limit,
    );

    _allUsers.addAll(response.data.users);
    _totalCount = response.data.totalCount;

    // Check if there are more pages
    final totalPages = response.meta.pagination.totalPages;
    _hasMore = _currentPage < totalPages;

    return _allUsers;
  }

  /// Load next page of search results
  Future<void> loadMore({int limit = 5}) async {
    if (!_hasMore || state.isLoading || _lastQuery.isEmpty) return;

    _currentPage++;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _performSearch(_lastQuery, limit);
    });
  }

  /// Clear search results
  void clear() {
    _lastQuery = '';
    _currentPage = 1;
    _allUsers = [];
    _hasMore = true;
    _totalCount = 0;
    state = const AsyncValue.data([]);
  }

  /// Check if there are more pages to load
  bool get hasMore => _hasMore;

  /// Get current page number
  int get currentPage => _currentPage;

  /// Get total count of search results
  int get totalCount => _totalCount;

  /// Get last search query
  String get lastQuery => _lastQuery;

  /// Send friend request to a user
  Future<void> sendFriendRequest(String userId) async {
    final repository = ref.read(connectionRepositoryProvider);
    final request = await repository.sendFriendRequest(userId);
    // Update local state with the friend request ID
    _updateUserFriendRequestState(userId, friendRequestId: request.id);
  }

  /// Cancel a friend request
  Future<void> cancelFriendRequest(String userId, String requestId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.cancelFriendRequest(requestId);
    // Update local state to remove the friend request ID
    _updateUserFriendRequestState(userId, friendRequestId: null);
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String userId, String requestId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.acceptConnection(requestId);
    // Update local state to set as friend and remove pending status
    _updateUserAfterAccept(userId);
    // Refresh connections data and pending requests
    ref.invalidate(connectionsViewModelProvider);
    ref.invalidate(pendingConnectionsViewModelProvider);
  }

  /// Follow a user and update local state
  Future<void> followUser(String userId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.followUser(userId);

    // Update local state to reflect the change
    _updateUserFollowState(userId, isFollowing: true);

    // Refresh connections data to update Following page and counts
    ref.invalidate(connectionsViewModelProvider);
  }

  /// Unfollow a user and update local state
  Future<void> unfollowUser(String userId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.unfollowUser(userId);

    // Update local state to reflect the change
    _updateUserFollowState(userId, isFollowing: false);

    // Refresh connections data to update Following page and counts
    ref.invalidate(connectionsViewModelProvider);
  }

  /// Remove friendship and update local state
  Future<void> removeFriendship(String userId) async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.removeFriendship(userId);

    // Update local state to reflect the change
    _updateUserFriendState(userId, isFriend: false);
  }

  /// Update user's follow state in local cache
  void _updateUserFollowState(String userId, {required bool isFollowing}) {
    final updatedUsers = _allUsers.map((user) {
      if (user.id == userId) {
        return ConnectionUser(
          id: user.id,
          username: user.username,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          emailVerified: user.emailVerified,
          profileImage: user.profileImage,
          coverImage: user.coverImage,
          bio: user.bio,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          location: user.location,
          phoneNumber: user.phoneNumber,
          phoneVerified: user.phoneVerified,
          isVerified: user.isVerified,
          isActive: user.isActive,
          role: user.role,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          lastLoginAt: user.lastLoginAt,
          isFriend: user.isFriend,
          isCloseFriend: user.isCloseFriend,
          isFollowing: isFollowing,
          friendRequestId: user.friendRequestId,
          connectionRequestId: user.connectionRequestId,
          hasPendingRequest: user.hasPendingRequest,
          hasIncomingRequest: user.hasIncomingRequest,
        );
      }
      return user;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }

  /// Update user's friend state in local cache
  void _updateUserFriendState(String userId, {required bool isFriend}) {
    final updatedUsers = _allUsers.map((user) {
      if (user.id == userId) {
        return ConnectionUser(
          id: user.id,
          username: user.username,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          emailVerified: user.emailVerified,
          profileImage: user.profileImage,
          coverImage: user.coverImage,
          bio: user.bio,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          location: user.location,
          phoneNumber: user.phoneNumber,
          phoneVerified: user.phoneVerified,
          isVerified: user.isVerified,
          isActive: user.isActive,
          role: user.role,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          lastLoginAt: user.lastLoginAt,
          isFriend: isFriend,
          isCloseFriend: user.isCloseFriend,
          isFollowing: user.isFollowing,
          friendRequestId: user.friendRequestId,
          connectionRequestId: user.connectionRequestId,
          hasPendingRequest: user.hasPendingRequest,
          hasIncomingRequest: user.hasIncomingRequest,
        );
      }
      return user;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }

  /// Update user's friend request state in local cache
  void _updateUserFriendRequestState(String userId, {String? friendRequestId}) {
    final updatedUsers = _allUsers.map((user) {
      if (user.id == userId) {
        return ConnectionUser(
          id: user.id,
          username: user.username,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          emailVerified: user.emailVerified,
          profileImage: user.profileImage,
          coverImage: user.coverImage,
          bio: user.bio,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          location: user.location,
          phoneNumber: user.phoneNumber,
          phoneVerified: user.phoneVerified,
          isVerified: user.isVerified,
          isActive: user.isActive,
          role: user.role,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          lastLoginAt: user.lastLoginAt,
          isFriend: user.isFriend,
          isCloseFriend: user.isCloseFriend,
          isFollowing: user.isFollowing,
          friendRequestId: friendRequestId,
          connectionRequestId: user.connectionRequestId,
          hasPendingRequest: friendRequestId != null ? true : null,
          hasIncomingRequest: user.hasIncomingRequest,
        );
      }
      return user;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }

  /// Update user state after accepting friend request
  void _updateUserAfterAccept(String userId) {
    final updatedUsers = _allUsers.map((user) {
      if (user.id == userId) {
        return ConnectionUser(
          id: user.id,
          username: user.username,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          emailVerified: user.emailVerified,
          profileImage: user.profileImage,
          coverImage: user.coverImage,
          bio: user.bio,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          location: user.location,
          phoneNumber: user.phoneNumber,
          phoneVerified: user.phoneVerified,
          isVerified: user.isVerified,
          isActive: user.isActive,
          role: user.role,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          lastLoginAt: user.lastLoginAt,
          isFriend: true,
          isCloseFriend: user.isCloseFriend,
          isFollowing: user.isFollowing,
          friendRequestId: null,
          connectionRequestId: null,
          hasPendingRequest: null,
          hasIncomingRequest: null,
        );
      }
      return user;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }
}
