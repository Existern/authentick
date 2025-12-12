import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/feed_response.dart';
import '../service/post_service.dart';

part 'feed_repository.g.dart';

@riverpod
Future<FeedResponse> feed(
  Ref ref, {
  String filter = 'all',
  int page = 1,
  int limit = 20,
  String duration = '1w',
  String mediaMode = 'preview',
}) async {
  final postService = ref.watch(postServiceProvider);
  return await postService.getFeed(
    filter: filter,
    page: page,
    limit: limit,
    duration: duration,
    mediaMode: mediaMode,
  );
}
