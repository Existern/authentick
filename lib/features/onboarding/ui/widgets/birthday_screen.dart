import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../profile/repository/profile_repository.dart';
import '../../view_model/onboarding_view_model.dart';

// Custom formatter for birthday: DD MM YYYY format
class BirthdayFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-numeric characters
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 8 digits (DDMMYYYY)
    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    // Add spaces after DD and MM
    String formatted = '';
    if (text.length > 4) {
      formatted = '${text.substring(0, 2)} ${text.substring(2, 4)} ${text.substring(4)}';
    } else if (text.length > 2) {
      formatted = '${text.substring(0, 2)} ${text.substring(2)}';
    } else {
      formatted = text;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BirthdayScreen extends ConsumerStatefulWidget {
  const BirthdayScreen({super.key});

  @override
  ConsumerState<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends ConsumerState<BirthdayScreen> {
  final TextEditingController _birthdayController = TextEditingController();
  String? _errorMessage;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _birthdayController.addListener(_onBirthdayChanged);
  }

  @override
  void dispose() {
    _birthdayController.removeListener(_onBirthdayChanged);
    _birthdayController.dispose();
    super.dispose();
  }

  void _onBirthdayChanged() {
    // Store the raw birthday without spaces
    final rawBirthday = _birthdayController.text.replaceAll(' ', '');
    ref.read(onboardingViewModelProvider.notifier).updateBirthday(rawBirthday);

    // Clear error message when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  /// Convert DDMMYYYY to YYYY-MM-DD format
  String _convertToApiFormat(String ddmmyyyy) {
    final day = ddmmyyyy.substring(0, 2);
    final month = ddmmyyyy.substring(2, 4);
    final year = ddmmyyyy.substring(4, 8);
    return '$year-$month-$day';
  }

  Future<void> _submitBirthday() async {
    final rawBirthday = _birthdayController.text.replaceAll(' ', '');
    if (rawBirthday.length != 8) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      // Convert DDMMYYYY to YYYY-MM-DD
      final apiDateFormat = _convertToApiFormat(rawBirthday);

      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(dateOfBirth: apiDateFormat);

      if (!mounted) return;

      setState(() {
        _errorMessage = null;
        _isUpdating = false;
      });

      // Continue to next step
      ref.read(onboardingViewModelProvider.notifier).submitBirthday();
    } catch (error) {
      if (!mounted) return;

      // Show error
      setState(() {
        _errorMessage = 'Date of birth is not valid';
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.showErrorSnackBar(state.error!);
        viewModel.clearError();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background with two ellipses
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
                    bottom: 200,
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
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // Header: Centered logo with check icon
                  SizedBox(
                    height: 40,
                    child: Align(
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
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'When\'s your birthday?',
                    style: AppTheme.title24.copyWith(
                      color: AppColors.mono100,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Birthday input
                  TextField(
                    controller: _birthdayController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mono100,
                      letterSpacing: 4.0,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'DD MM YYYY',
                      hintStyle: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mono40,
                        letterSpacing: 4.0,
                      ),
                    ),
                    inputFormatters: [BirthdayFormatter()],
                    keyboardType: TextInputType.number,
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _errorMessage!,
                          style: AppTheme.body14.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: state.birthday.length == 8 && !_isUpdating
                          ? _submitBirthday
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4300FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFEDE9FF),
                        disabledForegroundColor: const Color(0xFFC4B5FD),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
