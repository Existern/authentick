import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/repository/authentication_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user/model/update_profile_request.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/listtile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  bool _hasTriedRefresh = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController handleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger profile fetch on first load if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  Future<void> _ensureProfileLoaded() async {
    final profileState = ref.read(userProfileRepositoryProvider);
    
    // If profile data is null and not currently loading, trigger refresh
    if (profileState.value == null && !profileState.isLoading && !_hasTriedRefresh) {
      _hasTriedRefresh = true;
      // Fetch from API
      await ref.read(userProfileRepositoryProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    handleController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final profileAsync = ref.read(userProfileRepositoryProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        firstNameController.text = profile.firstName ?? '';
        lastNameController.text = profile.lastName ?? '';
        handleController.text = profile.username ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final request = UpdateProfileRequest(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        username: handleController.text.trim(),
      );

      await ref
          .read(userProfileRepositoryProvider.notifier)
          .updateProfile(request);

      if (mounted) {
        setState(() {
          isEditing = false;
          isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
          errorMessage = 'Failed to update profile';
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      errorMessage = null;
    });
    _loadProfileData();
  }

  Future<void> _handleLogout() async {
    try {
      final authRepo = ref.read(authenticationRepositoryProvider);
      await authRepo.signOut();

      if (!mounted) return;

      // Navigate to register/login screen
      context.go(Routes.register);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to logout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: Stack(
                  children: [
                    // Back button on the left
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // Centered title
                    const Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (!isEditing && !isSaving)
                    GestureDetector(
                      onTap: () {
                        _loadProfileData();
                        setState(() => isEditing = true);
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF3620B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (isEditing)
                    Row(
                      children: [
                        if (!isSaving)
                          GestureDetector(
                            onTap: _cancelEditing,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 20),
                        if (isSaving)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3620B3),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _saveProfile,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF3620B3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Error message
              if (errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              profileAsync.when(
                data: (profile) {
                  // If profile is null, trigger refresh and show loading
                  if (profile == null) {
                    // Trigger refresh in next frame
                    if (!_hasTriedRefresh) {
                      _hasTriedRefresh = true;
                      Future.microtask(() {
                        ref
                            .read(userProfileRepositoryProvider.notifier)
                            .refresh();
                      });
                    }
                    
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF3620B3),
                        ),
                      ),
                    );
                  }

                  // Load data only once when profile is available
                  if (!isEditing &&
                      firstNameController.text.isEmpty &&
                      lastNameController.text.isEmpty &&
                      handleController.text.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      firstNameController.text = profile.firstName ?? '';
                      lastNameController.text = profile.lastName ?? '';
                      handleController.text = profile.username ?? '';
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: 'First Name',
                        controller: firstNameController,
                        enabled: isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Last Name',
                        controller: lastNameController,
                        enabled: isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Handle',
                        controller: handleController,
                        enabled: isEditing,
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF3620B3)),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text('Error loading profile: $error'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Trust & Privacy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              BorderedListTile(title: 'Privacy policy', onTap: () {}),
              const SizedBox(height: 12),
              BorderedListTile(title: 'Terms of use', onTap: () {}),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: _handleLogout,
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFF3620B3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
