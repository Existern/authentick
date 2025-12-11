import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../view_model/onboarding_view_model.dart';
import 'intro_page.dart';

class IntroPagesWidget extends ConsumerStatefulWidget {
  const IntroPagesWidget({super.key});

  @override
  ConsumerState<IntroPagesWidget> createState() => _IntroPagesWidgetState();
}

class _IntroPagesWidgetState extends ConsumerState<IntroPagesWidget> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    const totalPages = 3;

    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate ellipse position based on current page
    final currentPage = state.introPageIndex;
    final progress = currentPage / (totalPages - 1);

    // Top ellipse moves from left to right
    final topEllipseLeft = -100 + (screenWidth + 200 - 200) * progress;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: Stack(
        children: [
          // Top Ellipse
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 80,
            left: topEllipseLeft,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE4CAFF).withValues(alpha: 0.85),
                    const Color(0xFFE4CAFF).withValues(alpha: 0.65),
                    const Color(0xFFE4CAFF).withValues(alpha: 0.35),
                    const Color(0xFFE4CAFF).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE4CAFF).withValues(alpha: 0.5),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      children: [
                        // Centered Logo
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'authentick',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C1C28),
                                  letterSpacing: -0.44, // -2% of 22px
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
                        ),
                        // Skip Button aligned to the right
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: viewModel.skipIntro,
                            child: Text(
                              'Skip',
                              style: AppTheme.label14.copyWith(
                                color: AppColors.mono80,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      viewModel.setIntroPage(index);
                    },
                    children: const [
                      IntroPage(
                        title: 'See Unfiltered Moments',
                        subtitle:
                            'Capture it. Don\'t curate it. Only share moments captured live through the app. \nNo uploads. No edits.',
                        imagePath: 'assets/images/onboarding_moments.png',
                      ),
                      IntroPage(
                        title: 'Only Real Places',
                        subtitle:
                            'Be where you say you are. Tag a location only if you\'re really there. All check-ins are verified in real time.',
                        imagePath: 'assets/images/onboarding_places.png',
                      ),
                      IntroPage(
                        title: 'Discovery Redefined',
                        subtitle:
                            'See unfiltered moments on a real-time map, from your city to cities you\'ve never seen.',
                        imagePath: 'assets/images/onboarding_discovery_map.png',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.introPageIndex == index
                            ? Colors.black
                            : AppColors.mono40,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: state.introPageIndex == totalPages - 1
                        ? ElevatedButton(
                            onPressed: viewModel.nextIntroPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4300FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            child: const Text(
                              'Try it out',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4300FF),
                              side: const BorderSide(
                                color: Color(0xFF4300FF),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
