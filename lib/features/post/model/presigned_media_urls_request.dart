// Request model for POST /posts/presigned-media-urls
class PresignedMediaUrlsRequest {
  final List<MediaFileInfo> files;

  PresignedMediaUrlsRequest({
    required this.files,
  });

  Map<String, dynamic> toJson() {
    return {
      'files': files.map((f) => f.toJson()).toList(),
    };
  }
}

class MediaFileInfo {
  final String contentType;
  final String filename;

  MediaFileInfo({
    required this.contentType,
    required this.filename,
  });

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentType,
      'filename': filename,
    };
  }
}
