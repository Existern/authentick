// Request model for POST /files/presigned-url
class FilePresignedUrlRequest {
  final String contentType;
  final String filename;

  FilePresignedUrlRequest({
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
