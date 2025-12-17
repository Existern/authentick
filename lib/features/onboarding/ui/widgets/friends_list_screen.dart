import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../connections/service/connection_service.dart';
import '../../../user/model/bulk_lookup_request.dart';
import '../../../user/model/bulk_lookup_response.dart';
import '../../../user/service/user_service.dart';
import '../../service/contacts_service.dart';
import '../../view_model/onboarding_view_model.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  List<UserLookupInfo> _authentickUsers = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _processingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadAuthentickUsers();
  }

  Future<void> _loadAuthentickUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      developer.log('FriendsListScreen: Starting to load Authentick users...');

      // First get all contacts with emails
      final contacts = await ContactsService.getAllContactsWithEmails();
      developer.log('FriendsListScreen: Got ${contacts.length} contacts');

      // Extract emails from contacts
      final emails = <String>[];
      for (final contact in contacts) {
        emails.addAll(contact.emails);
      }

      developer.log(
        'FriendsListScreen: Extracted ${emails.length} email addresses',
      );

      if (emails.isEmpty) {
        developer.log('FriendsListScreen: No emails found, showing empty list');
        setState(() {
          _authentickUsers = [];
          _isLoading = false;
        });
        return;
      }

      // Bulk lookup users on Authentick
      developer.log(
        'FriendsListScreen: Performing bulk lookup for ${emails.length} emails',
      );
      final userService = ref.read(userServiceProvider);
      final request = BulkLookupRequest(emails: emails);
      final response = await userService.bulkLookupUsers(request);

      developer.log('FriendsListScreen: Bulk lookup completed');
      developer.log(
        'FriendsListScreen: Found ${response.data.totalFound} users on Authentick',
      );
      developer.log(
        'FriendsListScreen: ${response.data.totalConnected} already connected',
      );
      developer.log(
        'FriendsListScreen: ${response.data.totalRequested} pending requests',
      );

      setState(() {
        _authentickUsers = response.data.users;
        _isLoading = false;
      });
    } catch (error) {
      developer.log(
        'FriendsListScreen: Error loading Authentick users: $error',
      );
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(UserLookupInfo user) async {
    if (_processingUsers.contains(user.id)) return;

    setState(() {
      _processingUsers.add(user.id);
    });

    try {
      developer.log(
        'FriendsListScreen: Sending friend request to ${user.username}',
      );

      final connectionService = ref.read(connectionServiceProvider);
      final request = await connectionService.sendFriendRequest(user.id);

      developer.log(
        'FriendsListScreen: Friend request sent successfully to ${user.username}',
      );

      // Update local state immediately
      setState(() {
        final index = _authentickUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _authentickUsers[index] = user.copyWith(friendRequestId: request.id);
        }
      });
    } catch (error) {
      developer.log('FriendsListScreen: Error sending friend request: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request to ${user.username}'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _processingUsers.remove(user.id);
      });
    }
  }

  Future<void> _cancelFriendRequest(UserLookupInfo user) async {
    if (_processingUsers.contains(user.id) || user.friendRequestId == null) {
      return;
    }

    setState(() {
      _processingUsers.add(user.id);
    });

    try {
      developer.log(
        'FriendsListScreen: Cancelling friend request to ${user.username}',
      );

      final connectionService = ref.read(connectionServiceProvider);
      await connectionService.cancelFriendRequest(user.friendRequestId!);

      developer.log(
        'FriendsListScreen: Friend request cancelled for ${user.username}',
      );

      // Update local state immediately
      setState(() {
        final index = _authentickUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _authentickUsers[index] = user.copyWith(friendRequestId: null);
        }
      });
    } catch (error) {
      developer.log(
        'FriendsListScreen: Error cancelling friend request: $error',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel friend request'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _processingUsers.remove(user.id);
      });
    }
  }

  Future<void> _followUser(UserLookupInfo user) async {
    if (_processingUsers.contains(user.id)) return;

    setState(() {
      _processingUsers.add(user.id);
    });

    try {
      developer.log('FriendsListScreen: Following user ${user.username}');

      final connectionService = ref.read(connectionServiceProvider);
      await connectionService.followUser(user.id);

      developer.log(
        'FriendsListScreen: Successfully followed ${user.username}',
      );

      // Update local state immediately
      setState(() {
        final index = _authentickUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _authentickUsers[index] = user.copyWith(isFollowing: true);
        }
      });
    } catch (error) {
      developer.log('FriendsListScreen: Error following user: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to follow ${user.username}'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _processingUsers.remove(user.id);
      });
    }
  }

  Future<void> _unfollowUser(UserLookupInfo user) async {
    if (_processingUsers.contains(user.id)) return;

    setState(() {
      _processingUsers.add(user.id);
    });

    try {
      developer.log('FriendsListScreen: Unfollowing user ${user.username}');

      final connectionService = ref.read(connectionServiceProvider);
      await connectionService.unfollowUser(user.id);

      developer.log(
        'FriendsListScreen: Successfully unfollowed ${user.username}',
      );

      // Update local state immediately
      setState(() {
        final index = _authentickUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _authentickUsers[index] = user.copyWith(isFollowing: false);
        }
      });
    } catch (error) {
      developer.log('FriendsListScreen: Error unfollowing user: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unfollow ${user.username}'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _processingUsers.remove(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Spacer(),
                  const Text(
                    'authentick',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF3620B3),
                    size: 20,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(onboardingViewModelProvider.notifier)
                          .completeFriendsFlow();
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3620B3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Find your friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contacts section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: [
                  Text(
                    'Friends on Authentick (${_authentickUsers.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: _loadAuthentickUsers,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3620B3).withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Color(0xFF3620B3),
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contacts list
            Expanded(child: _buildAuthentickUsersList()),

            // Action buttons
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthentickUsersList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding your friends on Authentick...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAuthentickUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_authentickUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No friends found on Authentick',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'None of your contacts are on Authentick yet.\nInvite them to join!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      itemCount: _authentickUsers.length,
      itemBuilder: (context, index) {
        final user = _authentickUsers[index];
        final isProcessing = _processingUsers.contains(user.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: user.isConnected
                  ? Colors.green.withAlpha(128)
                  : const Color(0xFF3620B3).withAlpha(51),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: user.isConnected
                    ? Colors.green[600]
                    : const Color(0xFF3620B3),
                backgroundImage: user.profileImage != null
                    ? CachedNetworkImageProvider(user.profileImage!)
                    : null,
                child: user.profileImage == null
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              _buildActionButtons(user, isProcessing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(UserLookupInfo user, bool isProcessing) {
    final isFriend = user.isFriend ?? false;
    final isFollowing = user.isFollowing ?? false;
    final hasPendingRequest = user.friendRequestId != null;

    // If user is a friend, show Connected badge
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Connected',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Show buttons in a column for better layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add Friend or Cancel Request button
        hasPendingRequest
            ? OutlinedButton(
                onPressed: isProcessing
                    ? null
                    : () => _cancelFriendRequest(user),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      )
                    : const Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )
            : OutlinedButton(
                onPressed: isProcessing ? null : () => _sendFriendRequest(user),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3620B3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3620B3),
                        ),
                      )
                    : const Text(
                        'Add Friend',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3620B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
        const SizedBox(height: 4),
        // Follow or Unfollow button
        isFollowing
            ? ElevatedButton(
                onPressed: isProcessing ? null : () => _unfollowUser(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Unfollow',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )
            : ElevatedButton(
                onPressed: isProcessing ? null : () => _followUser(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3620B3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Follow',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        // Continue button
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(onboardingViewModelProvider.notifier)
                    .completeFriendsFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3620B3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
