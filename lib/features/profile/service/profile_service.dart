import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/confirm_upload_request.dart';
import '../model/presigned_upload_request.dart';
import '../model/presigned_upload_response.dart';
import '../model/profile_update_request.dart';
import '../model/profile_update_response.dart';

part 'profile_service.g.dart';

@riverpod
ProfileService profileService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient);
}

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  /// Update user profile
  /// PUT /users/profile
  Future<ProfileUpdateResponse> updateProfile(
    ProfileUpdateRequest request,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/users/profile',
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get presigned upload URL for image
  /// POST /users/presigned-upload-url
  Future<PresignedUploadResponse> getPresignedUploadUrl(
    PresignedUploadRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/users/presigned-upload-url',
        data: request.toJson(),
      );
      return PresignedUploadResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image to presigned URL
  /// Uses Dio directly to upload to S3
  /// Sends raw binary data (not multipart) to match S3 presigned URL expectations
  Future<void> uploadImageToPresignedUrl(
    String presignedUrl,
    String filePath,
    String contentType,
  ) async {
    try {
      final dio = Dio();
      // Read file as bytes and send as binary data (like Postman's Binary option)
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      await dio.put(
        presignedUrl,
        data: fileBytes, // Send raw bytes, NOT MultipartFile
        options: Options(headers: {'Content-Type': contentType}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Confirm image upload
  /// POST /users/confirm-upload
  Future<PresignedUploadResponse> confirmUpload(
    ConfirmUploadRequest request,
    String imageType,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/users/confirm-upload',
        data: request.toJson(),
        queryParameters: {'type': imageType},
      );
      return PresignedUploadResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
