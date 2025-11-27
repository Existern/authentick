import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/post/repository/feed_repository.dart';
import 'package:flutter_mvvm_riverpod/screens/home/postcard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyHome extends ConsumerStatefulWidget {
  const MyHome({super.key});

  @override
  ConsumerState<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends ConsumerState<MyHome> {
  String selectedTab = 'All';

  String _getFilterForTab() {
    switch (selectedTab) {
      case 'Friends':
        return 'friends';
      case 'Following':
        return 'following';
      case 'All':
        return 'all';
      default:
        return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = _getFilterForTab();
    final feedAsync = ref.watch(feedProvider(filter: filter));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: SvgPicture.asset(
                'assets/images/authentick_logo.svg',
                width: 40,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),


            Row(
              children: [
                const SizedBox(width: 10),
                _buildTab(icon: Icons.people, label: 'Friends'),
                _buildTab(label: 'Following'),
                _buildTab(label: 'All'),
              ],
            ),

            Expanded(
              child: feedAsync.when(
                data: (feedResponse) {
                  final posts = feedResponse.data.posts;

                  if (posts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.post_add, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(feedProvider);
                    },
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final firstMedia = post.media?.isNotEmpty == true
                            ? post.media!.first
                            : null;

                        return PostCard(
                          username: post.user.username ?? 'User',
                          profileImage: post.user.profileImage,
                          postImage: firstMedia?.mediaUrl,
                          content: post.content,
                          location: post.metadata?.location,
                          createdAt: post.createdAt,
                          likesCount: post.likesCount,
                          commentsCount: post.commentsCount,
                          initialIsLiked: post.isLiked,
                        );
                      },
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
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load feed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(feedProvider);
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
          ],
        ),
      ),
    );
  }

  Widget _buildTab({IconData? icon, required String label}) {
    final bool isSelected = selectedTab == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF3620B3) : Colors.black54,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF3620B3) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
