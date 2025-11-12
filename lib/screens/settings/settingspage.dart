import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/user/model/update_profile_request.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/listtile.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/profile_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final profileAsync = ref.read(userProfileRepositoryProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        firstNameController.text = profile.firstName ?? '';
        lastNameController.text = profile.lastName ?? '';
        usernameController.text = profile.username;
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      // Send empty strings instead of null to trigger API validation
      final request = UpdateProfileRequest(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        username: usernameController.text.trim(),
      );

      await ref.read(userProfileRepositoryProvider.notifier).updateProfile(request);

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

          // Parse error message
          final errorStr = e.toString().toLowerCase();

          // Check for specific validation errors
          if (errorStr.contains('first') && errorStr.contains('name')) {
            errorMessage = 'First name cannot be empty';
          } else if (errorStr.contains('last') && errorStr.contains('name')) {
            errorMessage = 'Last name cannot be empty';
          } else if (errorStr.contains('username') &&
                     (errorStr.contains('already') ||
                      errorStr.contains('taken') ||
                      errorStr.contains('exists'))) {
            errorMessage = 'Username already taken';
          } else if (errorStr.contains('username') && errorStr.contains('invalid')) {
            errorMessage = 'Username is invalid';
          } else if (errorStr.contains('empty') || errorStr.contains('required')) {
            errorMessage = 'All fields are required';
          } else {
            // Try to extract meaningful error from the response
            if (errorStr.contains('validation') || errorStr.contains('invalid')) {
              errorMessage = 'Validation error: Please check your input';
            } else {
              errorMessage = 'Failed to update profile';
            }
          }
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isEditing) {
                        _cancelEditing();
                      }
                    },
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            !isEditing ? FontWeight.bold : FontWeight.normal,
                      ),
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
                          fontSize: 20,
                          color: Color(0xFF3620B3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isEditing)
                    Row(
                      children: [
                        if (!isSaving)
                          GestureDetector(
                            onTap: _cancelEditing,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
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

              const SizedBox(height: 8),

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
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
                  if (profile == null) {
                    return const Center(
                      child: Text('Unable to load profile'),
                    );
                  }

                  // Load data only once when profile is available
                  if (!isEditing &&
                      firstNameController.text.isEmpty &&
                      lastNameController.text.isEmpty &&
                      usernameController.text.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      firstNameController.text = profile.firstName ?? '';
                      lastNameController.text = profile.lastName ?? '';
                      usernameController.text = profile.username;
                    });
                  }

                  return ProfileSection(
                    firstNameController: firstNameController,
                    lastNameController: lastNameController,
                    usernameController: usernameController,
                    isEditable: isEditing,
                    onSave: () {},
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
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Error loading profile: $error'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Trust & Privacy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              BorderedListTile(title: 'Privacy Policy', onTap: () {}),
              const SizedBox(height: 8),
              BorderedListTile(title: 'Terms of Use', onTap: () {}),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () {},
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
}
