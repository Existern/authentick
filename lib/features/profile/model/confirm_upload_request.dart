// Confirm upload request model for POST /users/confirm-upload
class ConfirmUploadRequest {
  final String imageUrl;

  ConfirmUploadRequest({required this.imageUrl});

  Map<String, dynamic> toJson() {
    return {'image_url': imageUrl};
  }
}
