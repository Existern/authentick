import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/profile/repository/profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user/model/update_profile_request.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/settingspage.dart';
import 'package:image_picker/image_picker.dart';

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
          .updateProfile(
            UpdateProfileRequest(profileImage: imageUrl),
          );

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

    final List<String> imageUrls = [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
      'https://images.unsplash.com/photo-1495567720989-cebdbdd97913',
      'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c',
      'https://images.unsplash.com/photo-1504196606672-aef5c9cefc92',
      'https://images.unsplash.com/photo-1481349518771-20055b2a7b24',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29',
      'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c',
      'https://images.unsplash.com/photo-1504196606672-aef5c9cefc92',
      'https://images.unsplash.com/photo-1481349518771-20055b2a7b24',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
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
                              child: profile.profileImage != null && profile.profileImage!.isNotEmpty
                                  ? Image.network(
                                      profile.profileImage!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            color: const Color(0xFF3620B3),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        );
                                      },
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
                              onTap: _isUploadingImage ? null : _handleProfileImageUpdate,
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
                      if (profile.location != null && profile.location!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: MasonryGridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                  ),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                 
                    final double height = (index % 3 == 0)
                        ? 250
                        : (index % 3 == 1)
                            ? 180
                            : 220;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: height,
                        color: Colors.grey[200],
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.error)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
