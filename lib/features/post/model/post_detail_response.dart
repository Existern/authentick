import 'package:json_annotation/json_annotation.dart';
import 'feed_response.dart';

part 'post_detail_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PostDetailResponse {
  final bool success;
  final PostDetailData data;
  final FeedMeta? meta;

  PostDetailResponse({required this.success, required this.data, this.meta});

  factory PostDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PostDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PostDetailResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PostDetailData {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String? content;
  @JsonKey(name: 'post_type')
  final String postType;
  final String visibility;
  final List<MediaItem>? media;
  final PostMetadata? metadata;
  @JsonKey(name: 'likes_count')
  final int? likesCount;
  @JsonKey(name: 'comments_count')
  final int? commentsCount;
  @JsonKey(name: 'is_liked')
  final bool? isLiked;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final User user;

  PostDetailData({
    required this.id,
    required this.userId,
    this.content,
    required this.postType,
    required this.visibility,
    this.media,
    this.metadata,
    this.likesCount,
    this.commentsCount,
    this.isLiked,
    this.createdAt,
    this.updatedAt,
    required this.user,
  });

  factory PostDetailData.fromJson(Map<String, dynamic> json) =>
      _$PostDetailDataFromJson(json);

  Map<String, dynamic> toJson() => _$PostDetailDataToJson(this);
}
