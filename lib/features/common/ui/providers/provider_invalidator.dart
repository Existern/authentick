import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants/constants.dart';
import '/features/profile/ui/view_model/profile_view_model.dart';
import '/features/user/repository/user_profile_repository.dart';
import '/features/post/view_model/friends_feed_view_model.dart';
import '/features/post/view_model/all_feed_view_model.dart';
import '/features/post/view_model/following_feed_view_model.dart';
import '/features/post/repository/post_like_repository.dart';
import '/features/hero_list/ui/view_model/hero_list_view_model.dart';

import '/features/post/repository/paginated_my_posts_repository.dart';
import '/features/post/repository/feed_repository.dart';

final providerInvalidatorProvider = Provider((ref) => ProviderInvalidator(ref));

class ProviderInvalidator {
  final Ref ref;
  ProviderInvalidator(this.ref);

  /// Invalidate all user-specific providers on logout to prevent data leaking between accounts
  void invalidateUserProviders() {
    debugPrint(
      '${Constants.tag} [ProviderInvalidator] 🔄 Invalidating user providers...',
    );
    try {
      ref.invalidate(userProfileRepositoryProvider);
      ref.invalidate(profileViewModelProvider);
      ref.invalidate(friendsFeedViewModelProvider);
      ref.invalidate(allFeedViewModelProvider);
      ref.invalidate(followingFeedViewModelProvider);
      ref.invalidate(postLikeManagerProvider);
      ref.invalidate(heroListViewModelProvider);
      ref.invalidate(paginatedMyPostsProvider);
      ref.invalidate(feedProvider);
    } catch (e) {
      debugPrint(
        '${Constants.tag} [ProviderInvalidator] ⚠️ Error during provider invalidation: $e',
      );
    }
  }
}
