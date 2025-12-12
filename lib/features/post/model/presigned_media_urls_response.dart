// Response model for POST /posts/presigned-media-urls
class PresignedMediaUrlsResponse {
  final bool success;
  final PresignedMediaUrlsData data;

  PresignedMediaUrlsResponse({required this.success, required this.data});

  factory PresignedMediaUrlsResponse.fromJson(Map<String, dynamic> json) {
    return PresignedMediaUrlsResponse(
      success: json['success'] as bool? ?? false,
      data: PresignedMediaUrlsData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}

class PresignedMediaUrlsData {
  final List<MediaUrlInfo> mediaUrls;

  PresignedMediaUrlsData({required this.mediaUrls});

  factory PresignedMediaUrlsData.fromJson(Map<String, dynamic> json) {
    final mediaUrlsList = json['media_urls'] as List<dynamic>? ?? [];
    return PresignedMediaUrlsData(
      mediaUrls: mediaUrlsList
          .map((item) => MediaUrlInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MediaUrlInfo {
  final String contentType;
  final String filename;
  final int order;
  final String presignedUrl;
  final String publicUrl;

  MediaUrlInfo({
    required this.contentType,
    required this.filename,
    required this.order,
    required this.presignedUrl,
    required this.publicUrl,
  });

  factory MediaUrlInfo.fromJson(Map<String, dynamic> json) {
    return MediaUrlInfo(
      contentType: json['content_type'] as String,
      filename: json['filename'] as String,
      order: json['order'] as int,
      presignedUrl: json['presigned_url'] as String,
      publicUrl: json['public_url'] as String,
    );
  }
}
