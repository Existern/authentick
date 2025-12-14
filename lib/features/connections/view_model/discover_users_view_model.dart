import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/discover_user.dart';
import '../repository/connection_repository.dart';

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
    await repository.sendFriendRequest(userId);
  }
}
