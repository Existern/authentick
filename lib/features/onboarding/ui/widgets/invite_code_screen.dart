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

// Custom formatter for invite code: XXXX-XXXX format
class InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-alphanumeric characters
    String text = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();

    // Limit to 8 characters
    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    // Add dash after 4th character
    String formatted = '';
    if (text.length > 4) {
      formatted = '${text.substring(0, 4)}-${text.substring(4)}';
    } else {
      formatted = text;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class InviteCodeScreen extends ConsumerStatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    // Clear error when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    // Store the raw code without dash
    final rawCode = _codeController.text.replaceAll('-', '');
    ref.read(onboardingViewModelProvider.notifier).updateInviteCode(rawCode);
  }

  Future<void> _validateAndSubmit() async {
    // Get the raw code without dash
    final code = _codeController.text.replaceAll('-', '');

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      final response = await repository.updateProfile(invitedByCode: code);

      if (!mounted) return;

      if (response.success) {
        // Clear error and proceed
        setState(() {
          _errorMessage = null;
          _isValidating = false;
        });
        ref.read(onboardingViewModelProvider.notifier).submitInviteCode();
      } else {
        // Show error
        setState(() {
          _errorMessage = 'Invite code is invalid';
          _isValidating = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      // Show error
      setState(() {
        _errorMessage = 'Invite code is invalid';
        _isValidating = false;
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
                  // Header: Centered SVG logo
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/images/authentick_logo.svg',
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'Enter your invite code',
                    style: AppTheme.title24.copyWith(
                      color: AppColors.mono100,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Invite code input
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mono100,
                      letterSpacing: 4.0,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '--------',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mono40,
                        letterSpacing: 4.0,
                      ),
                    ),
                    inputFormatters: [InviteCodeFormatter()],
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
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

                  // Get started button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          state.inviteCode.length == 8 && !_isValidating
                              ? _validateAndSubmit
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
                      child: _isValidating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Get started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: viewModel.skipInviteCode,
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
                        'I don\'t have an invite code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTheme.body12.copyWith(
                          color: AppColors.mono60,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to Authentick\'s ',
                          ),
                          TextSpan(
                            text: 'EULA',
                            style: AppTheme.body12.copyWith(
                              color: AppColors.blueberry100,
                            ),
                          ),
                          const TextSpan(text: ', '),
                          TextSpan(
                            text: 'terms of service',
                            style: AppTheme.body12.copyWith(
                              color: AppColors.blueberry100,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'privacy policy',
                            style: AppTheme.body12.copyWith(
                              color: AppColors.blueberry100,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
