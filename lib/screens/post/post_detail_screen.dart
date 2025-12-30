import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../extensions/build_context_extension.dart';
import '../../features/post/repository/post_detail_repository.dart';
import '../../features/post/repository/post_like_repository.dart';
import '../../features/post/service/post_service.dart';
import '../../features/user/repository/user_profile_repository.dart';
import '../../theme/app_theme.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final bool showDeleteButton;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.showDeleteButton = false,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  bool _isDeleting = false;
  bool _isLiking = false;
  bool _showOverlays = true;

  String _formatTimeAgo(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatLikeCount(int count) {
    if (count == 0) {
      return '0';
    } else if (count == 1) {
      return '1';
    } else if (count < 1000) {
      return '$count';
    } else if (count < 1000000) {
      final k = (count / 1000).toStringAsFixed(1);
      return '${k.replaceAll(RegExp(r'\.0$'), '')}K';
    } else {
      final m = (count / 1000000).toStringAsFixed(1);
      return '${m.replaceAll(RegExp(r'\.0$'), '')}M';
    }
  }

  void _showLocationTooltip(BuildContext context, String fullLocation) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fullLocation,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.black87),
        ),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final postService = ref.read(postServiceProvider);
      await postService.deletePost(postId: widget.postId);

      if (mounted) {
        context.pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        context.showErrorSnackBar('Failed to delete post. Please try again.');
      }
    }
  }

  Future<void> _handleLikeToggle(
    bool currentIsLiked,
    int currentLikesCount,
  ) async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    // Store previous state for potential revert
    final previousIsLiked = currentIsLiked;
    final previousLikesCount = currentLikesCount;

    // Optimistic update via postLikeManager
    final likeManager = ref.read(postLikeManagerProvider.notifier);
    likeManager.initializePost(
      widget.postId,
      currentIsLiked,
      currentLikesCount,
    );
    likeManager.toggleLike(widget.postId);

    try {
      final postService = ref.read(postServiceProvider);

      if (currentIsLiked) {
        await postService.unlikePost(postId: widget.postId);
      } else {
        await postService.likePost(postId: widget.postId);
      }

      // Successfully updated - no need to refetch, optimistic update is already applied
    } catch (e) {
      // Revert the optimistic update on error
      likeManager.revertLike(
        widget.postId,
        previousIsLiked,
        previousLikesCount,
      );

      if (mounted) {
        context.showErrorSnackBar('Failed to update like. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(postId: widget.postId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: postAsync.when(
          data: (postResponse) {
            final post = postResponse.data;
            final firstMedia = post.media?.isNotEmpty == true
                ? post.media!.first
                : null;
            final location = post.metadata?.location;
            final timeText = _formatTimeAgo(post.createdAt ?? '');
            final userName =
                post.user.firstName != null && post.user.lastName != null
                ? '${post.user.firstName} ${post.user.lastName}'
                : post.user.username ?? 'User';

            // Initialize and watch like state from postLikeManager
            final likeManager = ref.read(postLikeManagerProvider.notifier);
            // Delay initialization to avoid modifying provider during build
            Future.microtask(() {
              likeManager.initializePost(
                widget.postId,
                post.isLiked ?? false,
                post.likesCount ?? 0,
              );
            });
            final likeState =
                ref.watch(postLikeManagerProvider)[widget.postId] ??
                PostLikeState(
                  isLiked: post.isLiked ?? false,
                  likesCount: post.likesCount ?? 0,
                );

            return Stack(
              children: [
                // Full screen image - tap to toggle overlays
                if (firstMedia != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showOverlays = !_showOverlays;
                        });
                      },
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: firstMedia.mediaUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOverlays = !_showOverlays;
                      });
                    },
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: IgnorePointer(
                    ignoring: !_showOverlays,
                    child: AnimatedOpacity(
                      opacity: _showOverlays ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 280,
                  child: IgnorePointer(
                    ignoring: !_showOverlays,
                    child: AnimatedOpacity(
                      opacity: _showOverlays ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top buttons - Back button
                Positioned(
                  top: 16,
                  left: 16,
                  child: IgnorePointer(
                    ignoring: !_showOverlays,
                    child: AnimatedOpacity(
                      opacity: _showOverlays ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Show delete button only when enabled AND post is owned by current user
                if (widget.showDeleteButton &&
                    ref.watch(userProfileRepositoryProvider).value?.id ==
                        post.userId)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IgnorePointer(
                      ignoring: !_showOverlays,
                      child: AnimatedOpacity(
                        opacity: _showOverlays ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: _isDeleting ? null : _handleDelete,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: _isDeleting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showOverlays,
                    child: AnimatedOpacity(
                      opacity: _showOverlays ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile picture
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[800],
                                    child:
                                        post.user.profileImage != null &&
                                            post.user.profileImage!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: post.user.profileImage!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Name and location/time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: AppTheme.title14.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (location != null &&
                                              location.isNotEmpty)
                                            Flexible(
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showLocationTooltip(
                                                    context,
                                                    location,
                                                  );
                                                },
                                                child: Text(
                                                  location,
                                                  style: AppTheme.body12
                                                      .copyWith(
                                                        color: Colors.white70,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          if (location != null &&
                                              location.isNotEmpty)
                                            Text(
                                              ' · ',
                                              style: AppTheme.body12.copyWith(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          Text(
                                            timeText,
                                            style: AppTheme.body12.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  post.visibility == 'public'
                                                      ? Icons.public
                                                      : Icons.group,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  post.visibility == 'public'
                                                      ? 'Everyone'
                                                      : 'Friends',
                                                  style: AppTheme.body12
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Caption below user info
                            if (post.content != null &&
                                post.content!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                post.content!,
                                style: AppTheme.body14.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Like button and count (left side)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _isLiking
                                      ? null
                                      : () => _handleLikeToggle(
                                          likeState.isLiked,
                                          likeState.likesCount,
                                        ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _isLiking
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : SvgPicture.asset(
                                                likeState.isLiked
                                                    ? 'assets/images/liked_star.svg'
                                                    : 'assets/images/star.svg',
                                                width: 20,
                                                height: 20,
                                              ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatLikeCount(
                                            likeState.likesCount,
                                          ),
                                          style: AppTheme.body14.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load post',
                  style: AppTheme.title16.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(postDetailProvider(postId: widget.postId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
