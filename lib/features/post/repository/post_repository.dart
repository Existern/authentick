import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../model/create_post_request.dart';
import '../model/create_post_response.dart';
import '../model/presigned_media_urls_request.dart';
import '../service/post_service.dart';
import '../service/post_upload_service.dart';
import '../ui/widgets/privacy_selector.dart';

part 'post_repository.g.dart';

@riverpod
PostRepository postRepository(Ref ref) {
  final postService = ref.watch(postServiceProvider);
  return PostRepository(postService);
}

class PostRepository {
  final PostService _postService;
  final PostUploadService _uploadService = PostUploadService();

  PostRepository(this._postService);

  /// Upload post image and create post
  /// 1. Get presigned URL
  /// 2. Upload image to S3
  /// 3. Create post
  Future<CreatePostResponse> createPost({
    required String imagePath,
    required String contentType,
    String? caption,
    PostPrivacy privacy = PostPrivacy.friends,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint(
        '${Constants.tag} [PostRepository] 🔄 Starting post creation...',
      );

      // Get image dimensions
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      final width = image?.width;
      final height = image?.height;
      final fileSize = await file.length();

      // Extract filename from path
      final filename = imagePath.split(Platform.pathSeparator).last;

      debugPrint(
        '${Constants.tag} [PostRepository] 📷 Image: $filename ($width x $height, ${fileSize} bytes)',
      );

      // Step 1: Get presigned URL using new endpoint
      final presignedRequest = PresignedMediaUrlsRequest(
        files: [MediaFileInfo(contentType: contentType, filename: filename)],
      );

      final presignedResponse = await _postService.getPresignedMediaUrls(
        presignedRequest,
      );

      debugPrint('${Constants.tag} [PostRepository] ✅ Got presigned URL');

      final mediaUrlInfo = presignedResponse.data.mediaUrls.first;

      // Step 2: Upload to S3 using presigned URL (AWS signed URL)
      await _uploadService.uploadToPresignedUrl(
        mediaUrlInfo.presignedUrl,
        imagePath,
      );

      debugPrint('${Constants.tag} [PostRepository] ✅ Image uploaded to S3');

      // Step 3: Create post
      final visibility = privacy == PostPrivacy.friends ? 'friends' : 'public';

      final mediaItem = MediaItem(
        mediaType: 'image',
        mediaUrl: mediaUrlInfo.publicUrl, // Use public URL from response
        mimeType: contentType,
        order: 0,
        fileSize: fileSize,
        width: width,
        height: height,
      );

      final metadata =
          (location != null || latitude != null || longitude != null)
          ? PostMetadata(
              location: location,
              latitude: latitude,
              longitude: longitude,
            )
          : null;

      final createPostRequest = CreatePostRequest(
        content: caption,
        media: [mediaItem],
        metadata: metadata,
        postType: 'image',
        visibility: visibility,
      );

      final createPostResponse = await _postService.createPost(
        createPostRequest,
      );

      debugPrint(
        '${Constants.tag} [PostRepository] ✅ Post created successfully',
      );
      debugPrint(
        '${Constants.tag} [PostRepository] Post ID: ${createPostResponse.data.id}',
      );

      return createPostResponse;
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [PostRepository] ❌ POST CREATION FAILED ❌');
      debugPrint(
        '${Constants.tag} [PostRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint('${Constants.tag} [PostRepository] Error Details: $error');
      debugPrint('${Constants.tag} [PostRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
