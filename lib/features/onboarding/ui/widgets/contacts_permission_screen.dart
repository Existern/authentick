import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../view_model/onboarding_view_model.dart';

class ContactsPermissionScreen extends ConsumerWidget {
  const ContactsPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Spacer(),
                  SvgPicture.asset(
                    'assets/images/authentick_logo.svg',
                    width: 30,
                    height: 30,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(onboardingViewModelProvider.notifier)
                          .skipContactsPermission();
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

            const Spacer(),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Find your friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Permission dialog
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32.0),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Allow Authentick to access your contacts?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Authentick will search your '),
                        TextSpan(
                          text: 'contacts',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text:
                              ' to help you connect with your friends on Authentick.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Allow button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              ref
                                  .read(onboardingViewModelProvider.notifier)
                                  .allowContactsPermission();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3620B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Allow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Don't Allow button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              ref
                                  .read(onboardingViewModelProvider.notifier)
                                  .skipContactsPermission();
                            },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Don't Allow",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3620B3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Finish button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref
                              .read(onboardingViewModelProvider.notifier)
                              .skipContactsPermission();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF3620B3),
                        width: 2,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Finish',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3620B3),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
