import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/profile/repository/profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user/model/update_profile_request.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/paginated_my_posts_repository.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/post_like_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/settingspage.dart';
import 'package:flutter_mvvm_riverpod/screens/profile/profile_image_full_view.dart';
import 'package:flutter_mvvm_riverpod/screens/post/post_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyProfile extends ConsumerStatefulWidget {
  const MyProfile({super.key});

  @override
  ConsumerState<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends ConsumerState<MyProfile> {
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      ref.read(paginatedMyPostsProvider.notifier).loadMore();
    }
  }

  Future<void> _handleProfileImageUpdate() async {
    try {
      // Open camera to capture photo
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload using the same flow as onboarding
      final profileRepo = ref.read(profileRepositoryProvider);
      final imageUrl = await profileRepo.uploadProfilePicture(
        photo.path,
        'image/jpeg',
      );

      // Update user profile with new image URL
      await ref
          .read(userProfileRepositoryProvider.notifier)
          .updateProfile(UpdateProfileRequest(profileImage: imageUrl));

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/authentick_logo.svg',
                    width: 40,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 28,
                      color: Color(0xFF5A5A72),
                    ),
                  ),
                ],
              ),
            ),

            // Wrap entire content in RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh both profile and posts
                  ref.invalidate(userProfileRepositoryProvider);
                  await ref.read(userProfileRepositoryProvider.future);
                  await ref.read(paginatedMyPostsProvider.notifier).refresh();
                },
                color: const Color(0xFF3620B3),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Profile Section
                      profileAsync.when(
                        data: (profile) {
                          // If profile is null, show message
                          if (profile == null) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Unable to load profile',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Center(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: GestureDetector(
                                          onTap:
                                              profile.profileImageThumbnail !=
                                                      null &&
                                                  profile
                                                      .profileImageThumbnail!
                                                      .isNotEmpty
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
                                                          ),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          child:
                                              profile.profileImageThumbnail !=
                                                      null &&
                                                  profile
                                                      .profileImageThumbnail!
                                                      .isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: profile
                                                      .profileImageThumbnail!,
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
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _isUploadingImage
                                            ? null
                                            : _handleProfileImageUpdate,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3620B3),
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: _isUploadingImage
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.edit,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  profile.fullName,
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
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.location!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Failed to load profile',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
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
                                      userProfileRepositoryProvider,
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
                        data: (profile) {
                          if (profile == null) {
                            return const SizedBox();
                          }

                          final postsState = ref.watch(
                            paginatedMyPostsProvider,
                          );

                          // Watch the postLikeManager to rebuild when likes change
                          ref.watch(postLikeManagerProvider);

                          // Show error if any
                          if (postsState.error != null &&
                              postsState.posts.isEmpty) {
                            return SizedBox(
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
                                    Text(
                                      postsState.error!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref
                                            .read(
                                              paginatedMyPostsProvider.notifier,
                                            )
                                            .refresh();
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
                            );
                          }

                          // Show loading for initial load
                          if (postsState.posts.isEmpty &&
                              postsState.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3620B3),
                                ),
                              ),
                            );
                          }

                          // Show empty state when no posts
                          if (postsState.posts.isEmpty &&
                              !postsState.isLoading) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                    SizedBox(height: 8),
                                    Text(
                                      'Pull down to refresh',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Filter posts with images
                          final postsWithImages = postsState.posts
                              .where(
                                (post) =>
                                    post.media != null &&
                                    post.media!.isNotEmpty &&
                                    post.media!.any(
                                      (media) => media.mediaType == 'image',
                                    ),
                              )
                              .toList();

                          return Column(
                            children: [
                              // Posts Grid
                              if (postsWithImages.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ),
                                  child: MasonryGridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                            (media) =>
                                                media.mediaType == 'image',
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
                                                    showDeleteButton: true,
                                                  ),
                                            ),
                                          ).then((deleted) {
                                            // Refresh posts if a post was deleted
                                            if (deleted == true && mounted) {
                                              ref
                                                  .read(
                                                    paginatedMyPostsProvider
                                                        .notifier,
                                                  )
                                                  .refresh();
                                            }
                                          });
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            height: height,
                                            color: Colors.grey[200],
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  firstImageMedia.previewUrl ??
                                                  firstImageMedia.mediaUrl,
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
                                ),

                              // Loading indicator for pagination
                              if (postsState.isLoading &&
                                  postsState.posts.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF3620B3),
                                    ),
                                  ),
                                ),

                              // End of list indicator
                              if (!postsState.hasMore &&
                                  postsState.posts.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No more posts',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
