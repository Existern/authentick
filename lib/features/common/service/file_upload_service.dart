import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';

part 'file_upload_service.g.dart';

@riverpod
FileUploadService fileUploadService(Ref ref) {
  return FileUploadService();
}

/// Shared service for uploading files to presigned URLs
/// Can be used for profile photos, post images, etc.
class FileUploadService {
  /// Upload file to presigned URL (S3)
  /// Handles both types of presigned URLs:
  /// - URLs with query parameters (AWS signature): sends raw bytes
  /// - URLs without query parameters: sends as multipart
  Future<void> uploadToPresignedUrl(
    String presignedUrl,
    String filePath,
    String contentType,
  ) async {
    try {
      debugPrint(
        '${Constants.tag} [FileUploadService] 🔄 Uploading file to S3...',
      );
      debugPrint('${Constants.tag} [FileUploadService] URL: $presignedUrl');
      debugPrint(
        '${Constants.tag} [FileUploadService] Content-Type: $contentType',
      );

      final dio = Dio();

      // Check if URL has query parameters (AWS signature)
      final hasQueryParams = presignedUrl.contains('?');

      if (hasQueryParams) {
        // For presigned URLs with query parameters, send raw file bytes
        // DO NOT add any custom headers for AWS signed URLs - it will cause 403
        // The signature only includes specific headers (host, x-amz-acl)
        debugPrint(
          '${Constants.tag} [FileUploadService] Using raw bytes (signed URL)',
        );
        final file = File(filePath);
        final fileBytes = await file.readAsBytes();

        debugPrint(
          '${Constants.tag} [FileUploadService] File size: ${fileBytes.length} bytes',
        );

        // Create a new Dio instance without any interceptors
        final cleanDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );

        debugPrint(
          '${Constants.tag} [FileUploadService] Sending PUT request to S3...',
        );

        // The presigned URL has X-Amz-SignedHeaders=host;x-amz-acl
        // This means x-amz-acl header must be present in the request
        final response = await cleanDio.put(
          presignedUrl,
          data: fileBytes,
          options: Options(
            headers: {
              'x-amz-acl': 'private', // Required by signature
            },
            followRedirects: false,
            validateStatus: (status) => status! < 500,
          ),
        );

        debugPrint(
          '${Constants.tag} [FileUploadService] Response status: ${response.statusCode}',
        );

        if (response.statusCode == 403) {
          debugPrint('${Constants.tag} [FileUploadService] ❌ Got 403 error');
          debugPrint(
            '${Constants.tag} [FileUploadService] Response data: ${response.data}',
          );
        } else {
          debugPrint(
            '${Constants.tag} [FileUploadService] ✅ Upload successful',
          );
        }
      } else {
        // For URLs without query parameters, use multipart
        debugPrint(
          '${Constants.tag} [FileUploadService] Using multipart form data',
        );
        final response = await dio.put(
          presignedUrl,
          data: await MultipartFile.fromFile(filePath),
          options: Options(headers: {'Content-Type': contentType}),
        );

        debugPrint('${Constants.tag} [FileUploadService] ✅ Upload successful');
        debugPrint(
          '${Constants.tag} [FileUploadService] Status: ${response.statusCode}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [FileUploadService] ❌ UPLOAD FAILED ❌');
      debugPrint(
        '${Constants.tag} [FileUploadService] Error Type: ${error.runtimeType}',
      );
      debugPrint('${Constants.tag} [FileUploadService] Error Details: $error');
      debugPrint('${Constants.tag} [FileUploadService] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
