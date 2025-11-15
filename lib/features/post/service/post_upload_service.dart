import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../constants/constants.dart';

/// Service specifically for uploading post images to AWS S3 presigned URLs
class PostUploadService {
  /// Upload file to AWS S3 presigned URL
  /// Uses Dio to send raw binary data (not multipart) to match S3 presigned URL expectations
  Future<void> uploadToPresignedUrl(
    String presignedUrl,
    String filePath,
  ) async {
    try {
      debugPrint('${Constants.tag} [PostUploadService] 🔄 Uploading to S3...');
      debugPrint('${Constants.tag} [PostUploadService] URL: $presignedUrl');

      final dio = Dio();
      // Read file as bytes and send as binary data (like Postman's Binary option)
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      debugPrint(
        '${Constants.tag} [PostUploadService] File size: ${fileBytes.length} bytes',
      );

      await dio.put(
        presignedUrl,
        data: fileBytes, // Send raw bytes, NOT MultipartFile
        options: Options(
          headers: {}, // Empty headers - let S3 presigned URL handle everything
        ),
      );

      debugPrint('${Constants.tag} [PostUploadService] ✅ Upload successful!');
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [PostUploadService] ❌ UPLOAD FAILED ❌');
      debugPrint('${Constants.tag} [PostUploadService] Error: $error');
      debugPrint('${Constants.tag} [PostUploadService] Stack: $stackTrace');
      rethrow;
    }
  }
}
