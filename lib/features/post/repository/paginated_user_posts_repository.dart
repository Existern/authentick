import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/feed_response.dart';
import '../service/post_service.dart';

part 'paginated_user_posts_repository.g.dart';

/// State for paginated user posts
class PaginatedUserPostsState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PaginatedUserPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  PaginatedUserPostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PaginatedUserPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

/// Notifier for paginated user posts
@riverpod
class PaginatedUserPosts extends _$PaginatedUserPosts {
  static const int _limit = 20;

  @override
  PaginatedUserPostsState build({required String userId}) {
    // Schedule initial load for next frame
    Future.microtask(() => loadMore());
    // Return loading state initially
    return const PaginatedUserPostsState(isLoading: true);
  }

  /// Load more posts
  Future<void> loadMore() async {
    // Don't load if already loading (unless it's the initial load with empty posts)
    if (state.isLoading && state.posts.isNotEmpty) return;
    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final postService = ref.read(postServiceProvider);
      final response = await postService.getUserPosts(
        userId: userId,
        page: state.currentPage,
        limit: _limit,
        mediaMode: 'preview',
      );

      if (response.data != null) {
        final newPosts = response.data!.posts;
        final hasMore =
            response.meta?.pagination != null &&
            response.meta!.pagination!.page <
                response.meta!.pagination!.totalPages;

        state = state.copyWith(
          posts: [...state.posts, ...newPosts],
          currentPage: state.currentPage + 1,
          hasMore: hasMore,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh posts (reset and load from beginning)
  Future<void> refresh() async {
    state = const PaginatedUserPostsState();
    await loadMore();
  }
}
