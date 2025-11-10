import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../post/ui/create_post_screen.dart';
import '../../view_model/onboarding_view_model.dart';

class WelcomeFirstMomentScreen extends ConsumerWidget {
  const WelcomeFirstMomentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final firstName = state.firstName ?? 'Name';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background with purple ellipses
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF8F7FF),
              child: Stack(
                children: [
                  // Top-left ellipse
                  Positioned(
                    top: -100,
                    left: -100,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 213.8, sigmaY: 213.8),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE4CAFF).withValues(alpha: 1.0),
                              const Color(0xFFE4CAFF).withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-right ellipse
                  Positioned(
                    bottom: 150,
                    right: -100,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 213.8, sigmaY: 213.8),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE4CAFF).withValues(alpha: 1.0),
                              const Color(0xFFE4CAFF).withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // White gradient from bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.80, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with logo and skip button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'authentick',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1C28),
                              letterSpacing: -0.44,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            'assets/images/CheckFat.svg',
                            width: 22,
                            height: 22,
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(onboardingViewModelProvider.notifier)
                              .skipFirstMoment();
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

                const SizedBox(height: 16),

                // Title - Made smaller
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to\nAuthentick, $firstName!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'An authentic world awaits you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Image Grid with Masonry Layout
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: MasonryGridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        // Define varying heights for masonry effect
                        final double height = (index % 3 == 0)
                            ? 250
                            : (index % 3 == 1)
                                ? 180
                                : 220;

                        // Image paths for the grid
                        final images = [
                          'assets/images/post1.jpg',
                          'assets/images/post2.jpg',
                          'assets/images/post3.jpg',
                          'assets/images/post4.jpg',
                          'assets/images/post5.jpg',
                          'assets/images/post6.jpg',
                        ];

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            child: Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

            // Capture button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Navigate to create post screen
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(
                          isOnboarding: true,
                          onComplete: () {
                            // When post is created, go back and continue onboarding
                            Navigator.of(context).pop();
                            ref
                                .read(onboardingViewModelProvider.notifier)
                                .captureFirstMoment();
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3620B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Capture your first moment',
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
            ),
          ),
        ],
      ),
    );
  }
}
