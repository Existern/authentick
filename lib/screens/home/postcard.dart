import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String? profileImage;
  final String? postImage;
  final String? content;
  final String? location;
  final String createdAt;
  final int likesCount;
  final int commentsCount;
  final bool initialIsLiked;

  const PostCard({
    super.key,
    required this.username,
    this.profileImage,
    this.postImage,
    this.content,
    this.location,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.initialIsLiked,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialIsLiked;
  }

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

  Widget _buildLocationTimeText() {
    final locationText = widget.location;
    final timeText = _formatTimeAgo(widget.createdAt);

    // If no location, just show time
    if (locationText == null || locationText.isEmpty) {
      return Text(
        timeText,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    // If location exists, show location with time
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (locationText.length > 30) {
                _showLocationTooltip(context, locationText);
              }
            },
            child: Tooltip(
              message: locationText,
              preferBelow: false,
              child: Text(
                locationText,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '• $timeText',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  void _showLocationTooltip(BuildContext context, String fullLocation) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + 10,
        top: position.dy - 60,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fullLocation,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove tooltip after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                        image: widget.profileImage != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  widget.profileImage!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.profileImage == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildLocationTimeText(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (widget.postImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: CachedNetworkImage(
              imageUrl: widget.postImage!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3620B3),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLiked = !isLiked;
                  });
                },
                child: SvgPicture.asset(
                  isLiked
                      ? 'assets/images/liked_star.svg'
                      : 'assets/images/star.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),

        if (widget.content != null && widget.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              widget.content!,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
