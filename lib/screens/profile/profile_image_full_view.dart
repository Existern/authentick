import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/profile/repository/profile_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user/model/update_profile_request.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_mvvm_riverpod/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/extensions/build_context_extension.dart';

class ProfileImageFullView extends ConsumerStatefulWidget {
  final String? profileImage;
  final String? profileImageThumbnail;

  const ProfileImageFullView({
    super.key,
    this.profileImage,
    this.profileImageThumbnail,
  });

  @override
  ConsumerState<ProfileImageFullView> createState() =>
      _ProfileImageFullViewState();
}

class _ProfileImageFullViewState extends ConsumerState<ProfileImageFullView> {
  bool _isUploadingImage = false;
  bool _isRemovingImage = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _handleEditImage() async {
    try {
      // Directly open camera without showing gallery option
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

        context.showSuccessSnackBar('Profile image updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        context.showErrorSnackBar(
          'Failed to update profile image: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _handleRemoveImage() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.secondaryBackgroundColor,
        title: Text(
          'Remove Profile Image',
          style: AppTheme.title16.copyWith(color: context.primaryTextColor),
        ),
        content: Text(
          'Are you sure you want to remove your profile image?',
          style: AppTheme.body14.copyWith(color: context.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTheme.body14.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: AppTheme.body14.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isRemovingImage = true;
      });

      // Delete profile image using DELETE endpoint
      await ref
          .read(userProfileRepositoryProvider.notifier)
          .deleteImage('profile');

      if (mounted) {
        setState(() {
          _isRemovingImage = false;
        });

        context.showSuccessSnackBar('Profile image removed successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRemovingImage = false;
        });

        context.showErrorSnackBar(
          'Failed to remove profile image: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen image
            Center(
              child:
                  widget.profileImage != null && widget.profileImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.profileImage!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: AppTheme.body16.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : widget.profileImageThumbnail != null &&
                        widget.profileImageThumbnail!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.profileImageThumbnail!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.person,
                          size: 120,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white54,
                      ),
                    ),
            ),

            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Action buttons at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Edit button
                    ElevatedButton.icon(
                      onPressed: _isUploadingImage || _isRemovingImage
                          ? null
                          : _handleEditImage,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.edit, size: 20),
                      label: Text(
                        'Edit',
                        style: AppTheme.body14.copyWith(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3620B3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    // Remove button
                    if (widget.profileImage != null &&
                        widget.profileImage!.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage || _isRemovingImage
                            ? null
                            : _handleRemoveImage,
                        icon: _isRemovingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_outline, size: 20),
                        label: Text(
                          'Remove',
                          style: AppTheme.body14.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
