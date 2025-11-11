// Response model for POST /posts
class CreatePostResponse {
  final bool success;
  final PostData data;
  final ResponseMeta meta;

  CreatePostResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    return CreatePostResponse(
      success: json['success'] as bool? ?? false,
      data: PostData.fromJson(json['data'] as Map<String, dynamic>),
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class PostData {
  final String id;
  final String userId;
  final String? content;
  final String postType;
  final String visibility;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String createdAt;
  final String updatedAt;

  PostData({
    required this.id,
    required this.userId,
    this.content,
    required this.postType,
    required this.visibility,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      postType: json['post_type'] as String,
      visibility: json['visibility'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class ResponseMeta {
  final String? requestId;
  final String? timestamp;

  ResponseMeta({
    this.requestId,
    this.timestamp,
  });

  factory ResponseMeta.fromJson(Map<String, dynamic> json) {
    return ResponseMeta(
      requestId: json['request_id'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}
