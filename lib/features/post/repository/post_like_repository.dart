import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_like_repository.g.dart';

/// Holds the like state for a single post
class PostLikeState {
  final bool isLiked;
  final int likesCount;

  const PostLikeState({required this.isLiked, required this.likesCount});

  PostLikeState copyWith({bool? isLiked, int? likesCount}) {
    return PostLikeState(
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}

/// Manages like states for all posts globally
/// This ensures like states persist even when widgets are rebuilt during scrolling
@Riverpod(keepAlive: true)
class PostLikeManager extends _$PostLikeManager {
  @override
  Map<String, PostLikeState> build() {
    return {};
  }

  /// Initialize or update the like state for a post from feed data
  void initializePost(String postId, bool isLiked, int likesCount) {
    // Only initialize if not already tracked (prevents overwriting user actions)
    if (!state.containsKey(postId)) {
      state = {
        ...state,
        postId: PostLikeState(isLiked: isLiked, likesCount: likesCount),
      };
    }
  }

  /// Get the current like state for a post, or create a default one
  PostLikeState getPostState(
    String postId,
    bool defaultIsLiked,
    int defaultLikesCount,
  ) {
    return state[postId] ??
        PostLikeState(isLiked: defaultIsLiked, likesCount: defaultLikesCount);
  }

  /// Toggle the like state for a post (optimistic update)
  void toggleLike(String postId) {
    final currentState = state[postId];
    if (currentState == null) return;

    final wasLiked = currentState.isLiked;
    state = {
      ...state,
      postId: PostLikeState(
        isLiked: !wasLiked,
        likesCount: wasLiked
            ? (currentState.likesCount - 1).clamp(0, double.infinity).toInt()
            : currentState.likesCount + 1,
      ),
    };
  }

  /// Revert like state on error
  void revertLike(String postId, bool previousIsLiked, int previousLikesCount) {
    state = {
      ...state,
      postId: PostLikeState(
        isLiked: previousIsLiked,
        likesCount: previousLikesCount,
      ),
    };
  }
}
