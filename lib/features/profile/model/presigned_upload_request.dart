// Presigned upload URL request model for POST /users/presigned-upload-url
class PresignedUploadRequest {
  final String contentType;
  final String imageType;

  PresignedUploadRequest({
    required this.contentType,
    required this.imageType,
  });

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentType,
      'image_type': imageType,
    };
  }
}
