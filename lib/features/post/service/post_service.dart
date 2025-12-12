import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/create_post_request.dart';
import '../model/create_post_response.dart';
import '../model/feed_response.dart';
import '../model/like_response.dart';
import '../model/post_detail_response.dart';
import '../model/presigned_media_urls_request.dart';
import '../model/presigned_media_urls_response.dart';

part 'post_service.g.dart';

@riverpod
PostService postService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PostService(apiClient);
}

class PostService {
  final ApiClient _apiClient;

  PostService(this._apiClient);

  /// Get presigned URLs for post media upload
  /// POST /posts/presigned-media-urls
  Future<PresignedMediaUrlsResponse> getPresignedMediaUrls(
    PresignedMediaUrlsRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/posts/presigned-media-urls',
        data: request.toJson(),
      );
      return PresignedMediaUrlsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new post
  /// POST /posts
  Future<CreatePostResponse> createPost(CreatePostRequest request) async {
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

  /// Get personalized feed
  /// GET /feed
  /// Parameters:
  /// - filter: Feed filter type (friends, following, everyone) - defaults to 'everyone'
  /// - page: Page number - defaults to 1
  /// - limit: Items per page - defaults to 20
  /// - mediaMode: Media mode for media URLs ('preview' or 'full') - defaults to 'preview'
  Future<FeedResponse> getFeed({
    String filter = 'all',
    int page = 1,
    int limit = 20,
    String duration = '1w',
    String mediaMode = 'preview',
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/feed',
        queryParameters: {
          'filter': filter,
          'page': page,
          'limit': limit,
          'duration': duration,
          'media_mode': mediaMode,
        },
      );
      print('📥 Feed API Response Type: ${response.runtimeType}');
      print('📥 Feed API Response: $response');
      return FeedResponse.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ Feed API Error: $e');
      print('❌ Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get user's posts
  /// GET /posts/user/{userId}
  /// Parameters:
  /// - userId: User ID
  /// - page: Page number - defaults to 1
  /// - limit: Items per page - defaults to 20
  Future<FeedResponse> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/posts/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return FeedResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Like a post
  /// POST /posts/{id}/like
  /// Parameters:
  /// - postId: Post ID
  Future<LikeResponse> likePost({required String postId}) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/posts/$postId/like',
      );
      return LikeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Unlike a post
  /// DELETE /posts/{id}/like
  /// Parameters:
  /// - postId: Post ID
  Future<LikeResponse> unlikePost({required String postId}) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/posts/$postId/like',
      );
      return LikeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific post by ID
  /// GET /posts/{id}
  /// Parameters:
  /// - postId: Post ID
  Future<PostDetailResponse> getPostById({required String postId}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/posts/$postId',
      );
      return PostDetailResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a post
  /// DELETE /posts/{id}
  /// Parameters:
  /// - postId: Post ID
  Future<LikeResponse> deletePost({required String postId}) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/posts/$postId',
      );
      return LikeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
