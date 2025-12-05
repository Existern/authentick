import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/profile/repository/profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user/model/update_profile_request.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/user_posts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/settingspage.dart';
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

            const SizedBox(height: 20),

            // Profile Section
            SizedBox(
              child: profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Unable to load profile'),
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
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey[300],
                                ),
                                child:
                                    profile.profileImageThumbnail != null &&
                                        profile
                                            .profileImageThumbnail!
                                            .isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl:
                                            profile.profileImageThumbnail!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF3620B3),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
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
                                          child: CircularProgressIndicator(
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
                          '@${profile.username}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (profile.bio != null && profile.bio!.isNotEmpty)
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
                              mainAxisAlignment: MainAxisAlignment.center,
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
                    child: CircularProgressIndicator(color: Color(0xFF3620B3)),
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
                            ref.invalidate(userProfileRepositoryProvider);
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
            ),

            const SizedBox(height: 20),

            Expanded(
              child: profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return const Center(child: Text('Unable to load profile'));
                  }

                  final userPostsAsync = ref.watch(
                    userPostsProvider(userId: profile.id),
                  );

                  return userPostsAsync.when(
                    data: (postsResponse) {
                      final posts = postsResponse.data.posts;

                      if (posts.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            // Refresh user posts
                            ref.invalidate(
                              userPostsProvider(userId: profile.id),
                            );
                          },
                          color: const Color(0xFF3620B3),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
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
                                      'No posts yet',
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
                            ),
                          ),
                        );
                      }

                      // Extract all media URLs from posts
                      final mediaItems = posts
                          .expand((post) => post.media ?? [])
                          .where((media) => media.mediaType == 'image')
                          .toList();

                      return RefreshIndicator(
                        onRefresh: () async {
                          // Refresh user posts
                          ref.invalidate(userPostsProvider(userId: profile.id));
                        },
                        color: const Color(0xFF3620B3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: MasonryGridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            gridDelegate:
                                const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                ),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            itemCount: mediaItems.length,
                            itemBuilder: (context, index) {
                              final media = mediaItems[index];

                              // Calculate height based on aspect ratio if available
                              final double height =
                                  (media.height != null && media.width != null)
                                  ? (media.height! / media.width!) * 180
                                  : ((index % 3 == 0)
                                        ? 250
                                        : (index % 3 == 1)
                                        ? 180
                                        : 220);

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: height,
                                  color: Colors.grey[200],
                                  child: CachedNetworkImage(
                                    imageUrl: media.mediaUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF3620B3),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3620B3),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Failed to load posts',
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
                                userPostsProvider(userId: profile.id),
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
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3620B3)),
                ),
                error: (error, stack) =>
                    const Center(child: Text('Unable to load profile')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
