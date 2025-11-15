// Request model for POST /posts
class CreatePostRequest {
  final String? content;
  final List<MediaItem>? media;
  final PostMetadata? metadata;
  final String postType;
  final String visibility;

  CreatePostRequest({
    this.content,
    this.media,
    this.metadata,
    required this.postType,
    required this.visibility,
  });

  Map<String, dynamic> toJson() {
    return {
      if (content != null) 'content': content,
      if (media != null) 'media': media!.map((m) => m.toJson()).toList(),
      if (metadata != null) 'metadata': metadata!.toJson(),
      'post_type': postType,
      'visibility': visibility,
    };
  }
}

class MediaItem {
  final String mediaType;
  final String mediaUrl;
  final String mimeType;
  final int order;
  final int? fileSize;
  final int? width;
  final int? height;
  final String? thumbnailUrl;
  final int? duration;

  MediaItem({
    required this.mediaType,
    required this.mediaUrl,
    required this.mimeType,
    required this.order,
    this.fileSize,
    this.width,
    this.height,
    this.thumbnailUrl,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'media_type': mediaType,
      'media_url': mediaUrl,
      'mime_type': mimeType,
      'order': order,
      if (fileSize != null) 'file_size': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (duration != null) 'duration': duration,
    };
  }
}

class PostMetadata {
  final String? location;
  final double? latitude;
  final double? longitude;
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

  Map<String, dynamic> toJson() {
    return {
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeId != null) 'place_id': placeId,
      if (tags != null) 'tags': tags,
      if (mentions != null) 'mentions': mentions,
      if (mood != null) 'mood': mood,
      if (activity != null) 'activity': activity,
      if (custom != null) 'custom': custom,
    };
  }
}
