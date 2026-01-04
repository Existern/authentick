import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/feed_response.dart';
import '../service/post_service.dart';

part 'following_feed_view_model.g.dart';

/// Provider for managing following feed with pagination
@Riverpod(keepAlive: true)
class FollowingFeedViewModel extends _$FollowingFeedViewModel {
  int _currentPage = 1;
  List<Post> _allPosts = [];
  bool _hasMore = true;

  @override
  Future<List<Post>> build() async {
    _currentPage = 1;
    _allPosts = [];
    _hasMore = true;
    return await _fetchFeed();
  }

  Future<List<Post>> _fetchFeed() async {
    if (!_hasMore) return _allPosts;

    final postService = ref.read(postServiceProvider);
    final feedResponse = await postService.getFeed(
      filter: 'following',
      page: _currentPage,
      limit: 20,
      mediaMode: 'preview',
    );

    if (feedResponse.data != null) {
      _allPosts.addAll(feedResponse.data!.posts);

      // Check if there are more pages
      final pagination = feedResponse.meta?.pagination;
      if (pagination != null) {
        _hasMore = _currentPage < pagination.totalPages;
      } else {
        _hasMore = false;
      }
    } else {
      _hasMore = false;
    }

    return _allPosts;
  }

  /// Load next page of feed
  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    _currentPage++;

    try {
      final newData = await _fetchFeed();
      state = AsyncValue.data(newData);
    } catch (error) {
      // Revert page number on error
      _currentPage--;
      rethrow;
    }
  }

  /// Refresh feed list (reset to page 1)
  Future<void> refresh() async {
    _currentPage = 1;
    _allPosts = [];
    _hasMore = true;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFeed();
    });
  }

  /// Check if there are more pages to load
  bool get hasMore => _hasMore;

  /// Get current page number
  int get currentPage => _currentPage;
}
