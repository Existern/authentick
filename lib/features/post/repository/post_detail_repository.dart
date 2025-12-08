import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/post_detail_response.dart';
import '../service/post_service.dart';

part 'post_detail_repository.g.dart';

@riverpod
Future<PostDetailResponse> postDetail(
  Ref ref, {
  required String postId,
}) async {
  final postService = ref.watch(postServiceProvider);
  return await postService.getPostById(postId: postId);
}

