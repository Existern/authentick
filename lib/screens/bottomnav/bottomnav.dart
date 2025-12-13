import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/screens/friends/friendpage.dart';
// import 'package:flutter_mvvm_riverpod/screens/home/homepage.dart';
import 'package:flutter_mvvm_riverpod/screens/home/postpage.dart';
import 'package:flutter_mvvm_riverpod/screens/location/locationpage.dart';
import 'package:flutter_mvvm_riverpod/screens/post/postpage.dart';
// import 'package:flutter_mvvm_riverpod/screens/post/postpage.dart';
import 'package:flutter_mvvm_riverpod/screens/profile/myprofile.dart';
import 'package:flutter_mvvm_riverpod/features/post/ui/create_post_screen.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/feed_repository.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/user_posts_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user/repository/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mvvm_riverpod/constants/constants.dart';

class BottomNavScreen extends ConsumerStatefulWidget {
  const BottomNavScreen({super.key});

  @override
  ConsumerState<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends ConsumerState<BottomNavScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Show first moment popup if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowFirstMomentPopup();
    });
  }

  Future<void> _checkAndShowFirstMomentPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldShow =
        prefs.getBool(Constants.shouldShowFirstMomentPopupKey) ?? false;

    if (shouldShow && mounted) {
      // Clear the flag so it only shows once
      await prefs.setBool(Constants.shouldShowFirstMomentPopupKey, false);

      // Show the popup
      _showFirstMomentPopup();
    }
  }

  void _showFirstMomentPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const FirstMomentPopup(),
    );

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          MyHome(key: ValueKey('home')),
          Locationpage(key: ValueKey('location')),
          Postpage(key: ValueKey('post')),
          Friendpage(key: ValueKey('friends')),
          MyProfile(key: ValueKey('profile')),
        ],
      ),

      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedItemColor: const Color(0xFF3620B3),
                unselectedItemColor: Colors.grey,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on),
                    label: '',
                  ),
                  BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
                  BottomNavigationBarItem(icon: Icon(Icons.people), label: ''),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
                ],
              ),
            ),
          ),

          Positioned(
            top: -25,
            child: GestureDetector(
              onTap: () async {
                // Navigate to create post screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreatePostScreen(isOnboarding: false),
                  ),
                );

                // After returning from create post, refresh feeds
                if (result == true && mounted) {
                  // Get current user ID to refresh their posts
                  final currentProfile = ref
                      .read(userProfileRepositoryProvider)
                      .value;

                  // Refresh the feed to show new posts
                  ref.invalidate(feedProvider);

                  // Immediately trigger a refresh of user posts for profile page
                  // This ensures the new post appears when user navigates to profile
                  if (currentProfile != null) {
                    // Using invalidate() to mark as needing refresh
                    // The profile page will automatically refetch when viewing
                    ref.invalidate(
                      userPostsProvider(userId: currentProfile.id),
                    );
                  }

                  // Navigate to home tab to see the new post
                  setState(() {
                    currentIndex = 0;
                  });
                }
              },
              child: Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF3620B3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.plus,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FirstMomentPopup extends StatelessWidget {
  const FirstMomentPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFE4CAFF).withOpacity(0.95),
                    const Color(0xFFEFE0FF).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4300FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.celebration_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'You posted your first moment!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C28),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
