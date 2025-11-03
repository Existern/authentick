import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class IntroPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const IntroPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image with gradient background - extends beyond visible area
        Positioned.fill(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      const Color(0xFF9B7EDE).withOpacity(0.15),
                      const Color(0xFFF8F7FF).withOpacity(0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) {
                        return child;
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Image not found.\nDid you add it to pubspec.yaml and do a full restart?\nPath: $imagePath',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Text content at the bottom with gradient shadow
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00F8F7FF), // Transparent
                  Color(0xFFF8F7FF), // Solid background
                ],
                stops: [0.0, 0.3],
              ),
            ),
            padding: const EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 80.0,
              bottom: 20.0,
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mono100,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mono80,
                      height: 1.5,
                    ),
                    children: _buildSubtitleSpans(subtitle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildSubtitleSpans(String text) {
    // Check if text contains "No uploads. No edits." or "No Uploads. No edits."
    final boldPattern = RegExp(r'No [uU]ploads?\. No edits\.', caseSensitive: false);
    final match = boldPattern.firstMatch(text);

    if (match != null) {
      final beforeBold = text.substring(0, match.start);
      final boldText = match.group(0)!;
      final afterBold = text.substring(match.end);

      return [
        if (beforeBold.isNotEmpty) TextSpan(text: beforeBold),
        TextSpan(
          text: boldText,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (afterBold.isNotEmpty) TextSpan(text: afterBold),
      ];
    }

    return [TextSpan(text: text)];
  }
}