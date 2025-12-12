import 'package:flutter/material.dart';

enum PostPrivacy { friends, everyone }

class PrivacySelector extends StatelessWidget {
  final PostPrivacy currentPrivacy;
  final ValueChanged<PostPrivacy> onPrivacyChanged;

  const PrivacySelector({
    super.key,
    required this.currentPrivacy,
    required this.onPrivacyChanged,
  });

  String _getPrivacyTitle(PostPrivacy privacy) {
    return privacy == PostPrivacy.friends ? 'Friends' : 'Everyone';
  }

  String _getPrivacyDescription(PostPrivacy privacy) {
    return privacy == PostPrivacy.friends
        ? 'Shared with all your friends'
        : 'Shared with all your friends';
  }

  IconData _getPrivacyIcon(PostPrivacy privacy) {
    return privacy == PostPrivacy.friends ? Icons.people : Icons.public;
  }

  void _showPrivacyMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final screenWidth = MediaQuery.of(context).size.width;

    // Position the menu ABOVE the selector with full width
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        0, // Start from left edge of screen
        buttonPosition.dy - 140, // Position above (approximate height of menu)
        screenWidth, // Full width
        button.size.height,
      ),
      Offset.zero & overlay.size,
    );

    showMenu<PostPrivacy>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      constraints: BoxConstraints(minWidth: screenWidth, maxWidth: screenWidth),
      items: [
        PopupMenuItem<PostPrivacy>(
          value: PostPrivacy.friends,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.people, size: 24, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Friends',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared with all your friends',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<PostPrivacy>(
          value: PostPrivacy.everyone,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.public, size: 24, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Everyone',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared with all your friends',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        onPrivacyChanged(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPrivacyMenu(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Icon(
              _getPrivacyIcon(currentPrivacy),
              size: 24,
              color: Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPrivacyTitle(currentPrivacy),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getPrivacyDescription(currentPrivacy),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 24, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
