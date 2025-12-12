import 'package:json_annotation/json_annotation.dart';

part 'feed_response.g.dart';

@JsonSerializable(explicitToJson: true)
class FeedResponse {
  final bool success;
  final FeedData? data;
  final FeedMeta? meta;

  FeedResponse({required this.success, this.data, this.meta});

  factory FeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeedResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FeedData {
  final List<Post> posts;
  @JsonKey(name: 'total_count')
  final int totalCount;

  FeedData({required this.posts, required this.totalCount});

  factory FeedData.fromJson(Map<String, dynamic> json) =>
      _$FeedDataFromJson(json);

  Map<String, dynamic> toJson() => _$FeedDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Post {
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
  final int likesCount;
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final User? user;

  Post({
    required this.id,
    required this.userId,
    this.content,
    required this.postType,
    required this.visibility,
    this.media,
    this.metadata,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MediaItem {
  final String id;
  @JsonKey(name: 'media_type')
  final String mediaType;
  @JsonKey(name: 'media_url')
  final String mediaUrl;
  @JsonKey(name: 'mime_type')
  final String mimeType;
  final int order;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  final int? width;
  final int? height;
  @JsonKey(name: 'preview_url')
  final String? previewUrl;
  final int? duration;

  MediaItem({
    required this.id,
    required this.mediaType,
    required this.mediaUrl,
    required this.mimeType,
    required this.order,
    this.fileSize,
    this.width,
    this.height,
    this.previewUrl,
    this.duration,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PostMetadata {
  final String? location;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'place_id')
  final String? placeId;
  final List<String>? tags;
  final List<String>? mentions;
  final String? mood;
  final String? activity;
  final Map<String, dynamic>? custom;

  PostMetadata({
    this.location,
    this.latitude,
    this.longitude,
    this.placeId,
    this.tags,
    this.mentions,
    this.mood,
    this.activity,
    this.custom,
  });

  factory PostMetadata.fromJson(Map<String, dynamic> json) =>
      _$PostMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$PostMetadataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class User {
  final String id;
  final String? username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;
  @JsonKey(name: 'profile_image_thumbnail')
  final String? profileImage;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final String? bio;
  final String? location;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? gender;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'phone_verified')
  final bool? phoneVerified;
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;
  @JsonKey(name: 'is_verified')
  final bool? isVerified;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  final String? role;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'last_login_at')
  final String? lastLoginAt;

  User({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.profileImage,
    this.coverImage,
    this.bio,
    this.location,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.phoneVerified,
    this.emailVerified,
    this.isVerified,
    this.isActive,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FeedMeta {
  final Pagination? pagination;
  @JsonKey(name: 'request_id')
  final String requestId;
  final String timestamp;

  FeedMeta({this.pagination, required this.requestId, required this.timestamp});

  factory FeedMeta.fromJson(Map<String, dynamic> json) =>
      _$FeedMetaFromJson(json);

  Map<String, dynamic> toJson() => _$FeedMetaToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Pagination {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
