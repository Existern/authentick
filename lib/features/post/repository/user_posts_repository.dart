import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/feed_response.dart';
import '../service/post_service.dart';

part 'user_posts_repository.g.dart';

@riverpod
Future<FeedResponse> userPosts(
  Ref ref, {
  required String userId,
  int page = 1,
  int limit = 20,
}) async {
  final postService = ref.watch(postServiceProvider);
  return await postService.getUserPosts(
    userId: userId,
    page: page,
    limit: limit,
  );
}
