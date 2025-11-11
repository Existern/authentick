import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../constants/constants.dart';

/// Service specifically for uploading post images to AWS S3 presigned URLs
class PostUploadService {
  /// Upload file to AWS S3 presigned URL with correct header handling
  Future<void> uploadToPresignedUrl(
    String presignedUrl,
    String filePath,
  ) async {
    try {
      debugPrint('${Constants.tag} [PostUploadService] 🔄 Uploading to S3...');
      debugPrint('${Constants.tag} [PostUploadService] URL: $presignedUrl');

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      debugPrint(
        '${Constants.tag} [PostUploadService] File size: ${fileBytes.length} bytes',
      );

      // Parse the presigned URL to understand what headers are required
      final uri = Uri.parse(presignedUrl);
      final signedHeaders = uri.queryParameters['X-Amz-SignedHeaders'];

      debugPrint(
        '${Constants.tag} [PostUploadService] Signed headers: $signedHeaders',
      );

      // Use HTTP client for more precise header control
      await _uploadWithCorrectHeaders(presignedUrl, fileBytes, signedHeaders);
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [PostUploadService] ❌ UPLOAD FAILED ❌');
      debugPrint('${Constants.tag} [PostUploadService] Error: $error');
      debugPrint('${Constants.tag} [PostUploadService] Stack: $stackTrace');
      rethrow;
    }
  }

  /// Upload with correct headers based on what was signed in the presigned URL
  Future<void> _uploadWithCorrectHeaders(
    String presignedUrl,
    List<int> fileBytes,
    String? signedHeaders,
  ) async {
    debugPrint(
      '${Constants.tag} [PostUploadService] 🔄 Starting upload with correct headers...',
    );

    final client = http.Client();
    final uri = Uri.parse(presignedUrl);

    try {
      final request = http.Request('PUT', uri);

      // Clear all default headers first
      request.headers.clear();

      // ===================================================================
      // ✨ FIX 1: Add the payload hash header to match the signature
      // ===================================================================
      // The backend signed this request with 'UNSIGNED-PAYLOAD'.
      // We must manually add this header to override the http client's
      // default behavior of sending the file's real SHA256 hash.
      request.headers['x-amz-content-sha256'] = 'UNSIGNED-PAYLOAD';
      debugPrint(
        '${Constants.tag} [PostUploadService] ✅ Added x-amz-content-sha256: UNSIGNED-PAYLOAD',
      );
      // ===================================================================

      // ===================================================================
      // ✨ FIX 2: REMOVE the Content-Type header
      // ===================================================================
      // The S3 error log's <CanonicalRequest> proves that
      // 'Content-Type' was NOT part of the signature. Adding it
      // (as we did before) also causes a mismatch.
      /* REMOVED:
      request.headers['Content-Type'] = 'image/jpeg';
      debugPrint(
        '${Constants.tag} [PostUploadService] ✅ Added Content-Type: image/jpeg (required for S3)',
      );
      */
      // ===================================================================

      // Add other headers that were explicitly included in the presigned URL signature
      if (signedHeaders != null) {
        final headerList = signedHeaders.split(';');
        debugPrint(
          '${Constants.tag} [PostUploadService] SignedHeaders list: $headerList',
        );

        for (String headerName in headerList) {
          switch (headerName.toLowerCase().trim()) {
            case 'host':
              // Host header is automatically set by the HTTP client
              debugPrint(
                '${Constants.tag} [PostUploadService] ℹ️ Host header handled by HTTP client',
              );
              break;
            case 'x-amz-acl':
              // This MUST match exactly what was used when generating the presigned URL
              request.headers['x-amz-acl'] = 'private';
              debugPrint(
                '${Constants.tag} [PostUploadService] ✅ Added x-amz-acl: private',
              );
              break;
            default:
              debugPrint(
                '${Constants.tag} [PostUploadService] ⚠️ Unknown/unhandled signed header: $headerName',
              );
              break;
          }
        }
      } else {
        debugPrint(
          '${Constants.tag} [PostUploadService] ⚠️ No SignedHeaders found in presigned URL',
        );
      }

      request.bodyBytes = fileBytes;

      // Enhanced debugging for troubleshooting
      debugPrint(
        '${Constants.tag} [PostUploadService] 📤 Final request headers: ${request.headers}',
      );
      debugPrint(
        '${Constants.tag} [PostUploadService] 📤 Request method: ${request.method}',
      );
      debugPrint(
        '${Constants.tag} [PostUploadService] 📤 Request URL path: ${uri.path}',
      );
      debugPrint(
        '${Constants.tag} [PostUploadService] 📤 Body size: ${fileBytes.length} bytes',
      );

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '${Constants.tag} [PostUploadService] 📥 Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('${Constants.tag} [PostUploadService] ✅ Upload successful!');
        return;
      }

      // Enhanced error logging for debugging signature mismatches
      debugPrint('${Constants.tag} [PostUploadService] ❌ Upload failed');
      debugPrint(
        '${Constants.tag} [PostUploadService] 📥 Response headers: ${response.headers}',
      );
      debugPrint(
        '${Constants.tag} [PostUploadService] 📥 Response body: ${response.body}',
      );

      // Parse AWS error for specific guidance
      if (response.statusCode == 403 &&
          response.body.contains('SignatureDoesNotMatch')) {
        debugPrint(
          '${Constants.tag} [PostUploadService] 🔍 SIGNATURE MISMATCH DETECTED:',
        );
        debugPrint(
          '${Constants.tag} [PostUploadService] 🔍 Check that all headers used in backend signature are included in request',
        );
        debugPrint(
          '${Constants.tag} [PostUploadService] 🔍 SignedHeaders from URL: $signedHeaders',
        );
        debugPrint(
          '${Constants.tag} [PostUploadService] 🔍 Headers sent: ${request.headers.keys.join(', ')}',
        );
      }

      throw Exception(
        'S3 upload failed with status ${response.statusCode}: ${response.body}',
      );
    } finally {
      client.close();
    }
  }
}
