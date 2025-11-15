import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/feed_response.dart';
import '../service/post_service.dart';

part 'feed_repository.g.dart';

@riverpod
Future<FeedResponse> feed(
  Ref ref, {
  String filter = 'everyone',
  int page = 1,
  int limit = 20,
}) async {
  final postService = ref.watch(postServiceProvider);
  return await postService.getFeed(
    filter: filter,
    page: page,
    limit: limit,
  );
}
