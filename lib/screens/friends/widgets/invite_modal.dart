import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class InviteModal extends StatelessWidget {
  final String inviteCode;
  final int invitesLeft;
  final int maxInvites;
  final int currentUses;

  const InviteModal({
    super.key,
    required this.inviteCode,
    required this.invitesLeft,
    required this.maxInvites,
    required this.currentUses,
  });

  String get _inviteMessage {
    return "Join me and become a part of the movement to bring 'social' back to social media at authentick. Your invite code is \"$inviteCode\" and I can invite only $maxInvites users. Download and install the app from here: https://authentick.app/download";
  }

  String get _headerText {
    if (currentUses == 0) {
      return 'Invite $maxInvites friends';
    } else {
      return '$invitesLeft ${invitesLeft == 1 ? 'invite' : 'invites'} left';
    }
  }

  String get _subHeaderText {
    if (currentUses == 0) {
      return 'The first to register will\nbe accepted.';
    } else {
      return 'The first to register will\nbe accepted.';
    }
  }

  List<String> get _inviteImages {
    if (invitesLeft >= 3) {
      return [
        'assets/images/invite_modal_1.jpg',
        'assets/images/invite_modal_2.jpg',
        'assets/images/invite_modal_3.jpg',
      ];
    } else if (invitesLeft == 2) {
      return [
        'assets/images/invite_modal_1.jpg',
        'assets/images/invite_modal_2.jpg',
      ];
    } else if (invitesLeft == 1) {
      return ['assets/images/invite_modal_1.jpg'];
    } else {
      return [];
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _inviteMessage));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite link copied to clipboard!'),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _shareVia(String platform, BuildContext context) async {
    final encodedMessage = Uri.encodeComponent(_inviteMessage);

    // Recommended: open native share sheet for platforms that don't accept URL schemes (like Instagram)
    if (platform == 'instagram') {
      // copy text to clipboard and open system share sheet so user can choose Instagram
      await Clipboard.setData(ClipboardData(text: _inviteMessage));
      // Show native share sheet
      try {
        await Share.share(_inviteMessage);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Could not open share sheet. Message copied to clipboard.',
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    // For other platforms attempt app scheme first then web fallback
    String appUrl = '';
    switch (platform) {
      case 'whatsapp':
        appUrl = 'whatsapp://send?text=$encodedMessage';
        break;
      case 'telegram':
        appUrl = 'tg://msg?text=$encodedMessage';
        break;
      case 'twitter':
        appUrl = 'twitter://post?message=$encodedMessage';
        break;
      case 'facebook':
        appUrl =
            'fb://facewebmodal/f?href=https://www.facebook.com/sharer/sharer.php?u=https://authentick.app';
        break;
      default:
        appUrl = '';
    }

    try {
      if (appUrl.isNotEmpty) {
        final uri = Uri.parse(appUrl);
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched && context.mounted) {
            Navigator.pop(context);
            return;
          }
        }
      }

      // Web fallback
      String webUrl = '';
      switch (platform) {
        case 'whatsapp':
          webUrl = 'https://wa.me/?text=$encodedMessage';
          break;
        case 'telegram':
          webUrl = 'https://t.me/share/url?text=$encodedMessage';
          break;
        case 'twitter':
          webUrl = 'https://twitter.com/intent/tweet?text=$encodedMessage';
          break;
        case 'facebook':
          webUrl =
              'https://www.facebook.com/sharer/sharer.php?u=https://authentick.app&quote=$encodedMessage';
          break;
      }

      if (webUrl.isNotEmpty) {
        final webUri = Uri.parse(webUrl);
        final launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched && context.mounted) {
          Navigator.pop(context);
          return;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $platform'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening $platform: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Purple section with invite info
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF3620B3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          _headerText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _subHeaderText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.5,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Profile images
                        if (_inviteImages.isNotEmpty)
                          SizedBox(
                            height: 70,
                            width: _inviteImages.length == 3
                                ? 150
                                : _inviteImages.length == 2
                                    ? 110
                                    : 70,
                            child: Stack(
                              children: _inviteImages
                                  .asMap()
                                  .entries
                                  .toList()
                                  .reversed
                                  .map((
                                entry,
                              ) {
                                final index = entry.key;
                                final imagePath = entry.value;
                                return Positioned(
                                  left: index * 40.0,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(imagePath),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Share options (white background)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // First row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareButton(
                        backgroundImagePath: 'assets/images/copy_link.png',
                        iconImagePath: 'assets/images/mdi_link-variant.png',
                        label: 'Copy link',
                        color: const Color(0xFF616161),
                        onTap: () => _copyToClipboard(context),
                      ),
                      _buildShareButton(
                        imagePath: 'assets/images/Whatsapp_icon.png',
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _shareVia('whatsapp', context),
                      ),
                      _buildShareButton(
                        imagePath: 'assets/images/insta_icon.png',
                        label: 'Insta',
                        color: const Color(0xFFE1306C),
                        onTap: () => _shareVia('instagram', context),
                      ),
                      _buildShareButton(
                        imagePath: 'assets/images/tele_icon.png',
                        label: 'Telegram',
                        color: const Color(0xFF0088cc),
                        onTap: () => _shareVia('telegram', context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Second row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildShareButton(
                        icon: Icons.close,
                        label: 'X',
                        color: const Color(0xFF000000),
                        onTap: () => _shareVia('twitter', context),
                      ),
                      const SizedBox(width: 32),
                      _buildShareButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: const Color(0xFF1877F2),
                        onTap: () => _shareVia('facebook', context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Done button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3620B3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    IconData? icon,
    String? imagePath,
    String? backgroundImagePath,
    String? iconImagePath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: backgroundImagePath != null && iconImagePath != null
                ? Stack(
                    children: [
                      // Background image
                      Image.asset(
                        backgroundImagePath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                      // Icon image on top
                      Center(
                        child: Image.asset(
                          iconImagePath,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  )
                : imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
