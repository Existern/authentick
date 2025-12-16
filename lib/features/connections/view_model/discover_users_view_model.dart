import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import '../model/discover_user.dart';
import '../repository/connection_repository.dart';
import 'connections_view_model.dart';

part 'discover_users_view_model.g.dart';

/// Provider for managing discover users with pagination
@riverpod
class DiscoverUsersViewModel extends _$DiscoverUsersViewModel {
  int _currentPage = 1;
  List<DiscoverUser> _allUsers = [];
  bool _hasMore = true;

  @override
  Future<List<DiscoverUser>> build() async {
    _currentPage = 1;
    _allUsers = [];
    _hasMore = true;
    return await _fetchDiscoverUsers();
  }

  Future<List<DiscoverUser>> _fetchDiscoverUsers() async {
    if (!_hasMore) return _allUsers;

    final repository = ref.read(connectionRepositoryProvider);
    final response = await repository.discoverUsers(page: _currentPage);

    _allUsers.addAll(response.data);

    // Check if there are more pages
    final totalPages = response.meta.pagination.totalPages;
    _hasMore = _currentPage < totalPages;

    return _allUsers;
  }

  /// Load next page of discover users
  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    _currentPage++;

    try {
      final newData = await _fetchDiscoverUsers();
      state = AsyncValue.data(newData);
    } catch (error, stack) {
      // Revert page number on error
      _currentPage--;
      rethrow;
    }
  }

  /// Refresh discover users list (reset to page 1)
  Future<void> refresh() async {
    _currentPage = 1;
    _allUsers = [];
    _hasMore = true;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchDiscoverUsers();
    });
  }

  /// Check if there are more pages to load
  bool get hasMore => _hasMore;

  /// Get current page number
  int get currentPage => _currentPage;

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
    final updatedUsers = _allUsers.map((discoverUser) {
      if (discoverUser.user.id == userId) {
        final user = discoverUser.user;
        return DiscoverUser(
          mutualCount: discoverUser.mutualCount,
          user: ConnectionUser(
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
          ),
        );
      }
      return discoverUser;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }

  /// Update user's friend state in local cache
  void _updateUserFriendState(String userId, {required bool isFriend}) {
    final updatedUsers = _allUsers.map((discoverUser) {
      if (discoverUser.user.id == userId) {
        final user = discoverUser.user;
        return DiscoverUser(
          mutualCount: discoverUser.mutualCount,
          user: ConnectionUser(
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
          ),
        );
      }
      return discoverUser;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }

  /// Update user's friend request state in local cache
  void _updateUserFriendRequestState(String userId, {String? friendRequestId}) {
    final updatedUsers = _allUsers.map((discoverUser) {
      if (discoverUser.user.id == userId) {
        final user = discoverUser.user;
        return DiscoverUser(
          mutualCount: discoverUser.mutualCount,
          user: ConnectionUser(
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
          ),
        );
      }
      return discoverUser;
    }).toList();

    _allUsers = updatedUsers;
    state = AsyncValue.data(updatedUsers);
  }
}
