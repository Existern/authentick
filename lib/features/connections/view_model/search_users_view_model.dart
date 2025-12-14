import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import '../repository/connection_repository.dart';

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
    await repository.sendFriendRequest(userId);
  }
}
