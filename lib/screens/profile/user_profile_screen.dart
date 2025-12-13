import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/other_user_profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/user_posts_repository.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/post_like_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_mvvm_riverpod/screens/profile/profile_image_full_view.dart';
import 'package:flutter_mvvm_riverpod/screens/post/post_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  final String? initialUsername;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUsername,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId: userId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with back button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF5A5A72),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SvgPicture.asset(
                    'assets/images/authentick_logo.svg',
                    width: 40,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(otherUserProfileProvider(userId: userId));
                  ref.invalidate(userPostsProvider(userId: userId));
                },
                color: const Color(0xFF3620B3),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Profile Section
                      profileAsync.when(
                        data: (profileResponse) {
                          final profile = profileResponse.data;

                          return Center(
                            child: Column(
                              children: [
                                // Profile Image (no edit button)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF3620B3),
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.grey[300],
                                    ),
                                    child: GestureDetector(
                                      onTap:
                                          (profile.profileImage != null &&
                                                  profile
                                                      .profileImage!
                                                      .isNotEmpty) ||
                                              (profile.profileImageThumbnail !=
                                                      null &&
                                                  profile
                                                      .profileImageThumbnail!
                                                      .isNotEmpty)
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfileImageFullView(
                                                        profileImage: profile
                                                            .profileImage,
                                                        profileImageThumbnail:
                                                            profile
                                                                .profileImageThumbnail,
                                                        isCurrentUser: false,
                                                      ),
                                                ),
                                              );
                                            }
                                          : null,
                                      child:
                                          (profile.profileImageThumbnail !=
                                                      null &&
                                                  profile
                                                      .profileImageThumbnail!
                                                      .isNotEmpty) ||
                                              (profile.profileImage != null &&
                                                  profile
                                                      .profileImage!
                                                      .isNotEmpty)
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  profile
                                                      .profileImageThumbnail ??
                                                  profile.profileImage!,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFF3620B3,
                                                          ),
                                                        ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.person,
                                                        size: 60,
                                                        color: Colors.grey,
                                                      ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  profile.firstName != null &&
                                          profile.lastName != null
                                      ? '${profile.firstName} ${profile.lastName}'
                                      : profile.username ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '@${profile.username ?? 'user'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (profile.bio != null &&
                                    profile.bio!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      profile.bio!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                if (profile.location != null &&
                                    profile.location!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.location!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (profile.isVerified == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 18,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF3620B3),
                            ),
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.invalidate(
                                      otherUserProfileProvider(userId: userId),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3620B3),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Posts Section
                      profileAsync.when(
                        data: (profileResponse) {
                          final profileId = profileResponse.data.id;
                          final userPostsAsync = ref.watch(
                            userPostsProvider(userId: profileId),
                          );

                          return userPostsAsync.when(
                            data: (postsResponse) {
                              if (postsResponse.data == null) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No data available',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final posts = postsResponse.data!.posts;

                              if (posts.isEmpty) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No moments yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Filter posts with images
                              final postsWithImages = posts
                                  .where(
                                    (post) =>
                                        post.media != null &&
                                        post.media!.isNotEmpty &&
                                        post.media!.any(
                                          (media) => media.mediaType == 'image',
                                        ),
                                  )
                                  .toList();

                              // Watch the postLikeManager to rebuild when likes change
                              ref.watch(postLikeManagerProvider);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: MasonryGridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                      ),
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  itemCount: postsWithImages.length,
                                  itemBuilder: (context, index) {
                                    final post = postsWithImages[index];
                                    final firstImageMedia = post.media!
                                        .where(
                                          (media) => media.mediaType == 'image',
                                        )
                                        .first;

                                    // Calculate height based on aspect ratio if available
                                    final double height =
                                        (firstImageMedia.height != null &&
                                            firstImageMedia.width != null)
                                        ? (firstImageMedia.height! /
                                                  firstImageMedia.width!) *
                                              180
                                        : ((index % 3 == 0)
                                              ? 250
                                              : (index % 3 == 1)
                                              ? 180
                                              : 220);

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PostDetailScreen(
                                                  postId: post.id,
                                                ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: height,
                                          color: Colors.grey[200],
                                          child: CachedNetworkImage(
                                            imageUrl: firstImageMedia.mediaUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Color(
                                                          0xFF3620B3,
                                                        ),
                                                      ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3620B3),
                                ),
                              ),
                            ),
                            error: (error, stack) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Failed to load posts'),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.invalidate(
                                          userPostsProvider(userId: profileId),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3620B3,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (error, stack) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
