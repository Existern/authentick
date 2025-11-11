import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/create_post_request.dart';
import '../model/create_post_response.dart';
import '../model/file_presigned_url_request.dart';
import '../model/file_presigned_url_response.dart';

part 'post_service.g.dart';

@riverpod
PostService postService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PostService(apiClient);
}

class PostService {
  final ApiClient _apiClient;

  PostService(this._apiClient);

  /// Get presigned URL for file upload
  /// POST /files/presigned-url
  Future<FilePresignedUrlResponse> getPresignedUrl(
    FilePresignedUrlRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/files/presigned-url',
        data: request.toJson(),
      );
      return FilePresignedUrlResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new post
  /// POST /posts
  Future<CreatePostResponse> createPost(
    CreatePostRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/posts',
        data: request.toJson(),
      );
      return CreatePostResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
