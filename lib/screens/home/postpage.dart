import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/features/post/view_model/friends_feed_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/post/view_model/following_feed_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/post/view_model/all_feed_view_model.dart';
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
  bool _isLoadingMore = false;

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate feed based on selected tab
    final feedAsync = selectedTab == 'Friends'
        ? ref.watch(friendsFeedViewModelProvider)
        : selectedTab == 'Following'
        ? ref.watch(followingFeedViewModelProvider)
        : ref.watch(allFeedViewModelProvider);

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
                data: (posts) {
                  if (posts.isEmpty) {
                    // Get the appropriate view model based on selected tab
                    dynamic viewModel = selectedTab == 'Friends'
                        ? ref.read(friendsFeedViewModelProvider.notifier)
                        : selectedTab == 'Following'
                        ? ref.read(followingFeedViewModelProvider.notifier)
                        : ref.read(allFeedViewModelProvider.notifier);

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _isLoadingMore = false;
                        });
                        await viewModel.refresh();
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: constraints.maxHeight,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.post_add,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
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
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  // Get the appropriate view model based on selected tab
                  dynamic viewModel = selectedTab == 'Friends'
                      ? ref.read(friendsFeedViewModelProvider.notifier)
                      : selectedTab == 'Following'
                      ? ref.read(followingFeedViewModelProvider.notifier)
                      : ref.read(allFeedViewModelProvider.notifier);

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _isLoadingMore = false;
                      });
                      await viewModel.refresh();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        top: 0,
                        bottom: 100, // Add bottom padding
                        left: 0,
                        right: 0,
                      ),
                      itemCount: posts.length + (viewModel.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == posts.length) {
                          // Show Load More button or loading indicator
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            child: Center(
                              child: _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF3620B3),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _isLoadingMore = true;
                                        });
                                        try {
                                          await viewModel.loadMore();
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isLoadingMore = false;
                                            });
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3620B3,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        'Load More',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }

                        final post = posts[index];
                        final firstMedia = post.media?.isNotEmpty == true
                            ? post.media!.first
                            : null;

                        return PostCard(
                          postId: post.id,
                          userId: post.userId,
                          username: post.user?.username ?? 'User',
                          profileImage: post.user?.profileImage,
                          postImage:
                              firstMedia?.previewUrl ?? firstMedia?.mediaUrl,
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
                  child: CircularProgressIndicator(color: Color(0xFF3620B3)),
                ),
                error: (error, stack) {
                  // Get the appropriate view model based on selected tab
                  dynamic viewModel = selectedTab == 'Friends'
                      ? ref.read(friendsFeedViewModelProvider.notifier)
                      : selectedTab == 'Following'
                      ? ref.read(followingFeedViewModelProvider.notifier)
                      : ref.read(allFeedViewModelProvider.notifier);

                  return Center(
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoadingMore = false;
                            });
                            viewModel.refresh();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3620B3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
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
          _isLoadingMore = false; // Reset loading state when switching tabs
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
