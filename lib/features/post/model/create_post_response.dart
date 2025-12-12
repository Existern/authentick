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
  final List<PostMediaItem> media;

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
    this.media = const [],
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    final mediaList = json['media'] as List<dynamic>? ?? [];
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
      media: mediaList
          .map((item) => PostMediaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PostMediaItem {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String mimeType;
  final int order;

  PostMediaItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.mimeType,
    required this.order,
  });

  factory PostMediaItem.fromJson(Map<String, dynamic> json) {
    return PostMediaItem(
      id: json['id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      mimeType: json['mime_type'] as String,
      order: json['order'] as int,
    );
  }
}

class ResponseMeta {
  final String? requestId;
  final String? timestamp;

  ResponseMeta({this.requestId, this.timestamp});

  factory ResponseMeta.fromJson(Map<String, dynamic> json) {
    return ResponseMeta(
      requestId: json['request_id'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}
