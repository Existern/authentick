import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../routing/routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../authentication/repository/authentication_repository.dart';
import '../../../profile/repository/profile_repository.dart';
import '../../view_model/onboarding_view_model.dart';

// Custom formatter for invite code: XXXX-XXXX format
class InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-alphanumeric characters except dash
    String text = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '')
        .toUpperCase();

    // Remove existing dashes to rebuild formatting
    String cleanText = text.replaceAll('-', '');

    // Limit to 8 characters
    if (cleanText.length > 8) {
      cleanText = cleanText.substring(0, 8);
    }

    // Add dash after 4th character
    String formatted = '';
    if (cleanText.length > 4) {
      formatted = '${cleanText.substring(0, 4)}-${cleanText.substring(4)}';
    } else {
      formatted = cleanText;
    }

    // Maintain cursor position properly
    int newCursorPosition = formatted.length;
    if (newValue.selection.baseOffset <= oldValue.text.length) {
      // Calculate new cursor position based on old position
      int oldCleanLength = oldValue.text.replaceAll('-', '').length;
      int newCleanLength = cleanText.length;
      if (newCleanLength > oldCleanLength) {
        // Adding characters
        newCursorPosition = formatted.length;
      } else if (newCleanLength < oldCleanLength) {
        // Removing characters
        newCursorPosition = newValue.selection.baseOffset;
        if (newCursorPosition > formatted.length) {
          newCursorPosition = formatted.length;
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
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
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;
  bool _isValidating = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    // Request focus after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    // Clear error when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Only update if the field is focused and has content
    if (_focusNode.hasFocus) {
      // Store the raw code without dash
      final rawCode = _codeController.text.replaceAll('-', '');
      ref.read(onboardingViewModelProvider.notifier).updateInviteCode(rawCode);
    }
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
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
                              focusNode: _focusNode,
                              autofocus: true,
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
                                counterText: '', // Hide character counter
                              ),
                              inputFormatters: [InviteCodeFormatter()],
                              keyboardType: TextInputType.visiblePassword,
                              textCapitalization: TextCapitalization.characters,
                              enableSuggestions: false,
                              autocorrect: false,
                              maxLength: 9, // 8 chars + 1 dash
                            ),

                            // Error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 16,
                                  ),
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

                            // Terms checkbox
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreedToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF4300FF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _agreedToTerms = !_agreedToTerms;
                                        });
                                      },
                                      child: RichText(
                                        textAlign: TextAlign.left,
                                        text: TextSpan(
                                          style: AppTheme.body12.copyWith(
                                            color: AppColors.mono100,
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'By continuing, you agree to Authentick\'s ',
                                            ),
                                            TextSpan(
                                              text: 'EULA',
                                              style: AppTheme.body12.copyWith(
                                                color: const Color(0xFF0D47A1),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(text: ', '),
                                            TextSpan(
                                              text: 'terms of service',
                                              style: AppTheme.body12.copyWith(
                                                color: const Color(0xFF0D47A1),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'privacy policy',
                                              style: AppTheme.body12.copyWith(
                                                color: const Color(0xFF0D47A1),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(text: '.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Get started button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    state.inviteCode.length == 8 &&
                                        !_isValidating &&
                                        _agreedToTerms
                                    ? _validateAndSubmit
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4300FF),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFEDE9FF,
                                  ),
                                  disabledForegroundColor: const Color(
                                    0xFFC4B5FD,
                                  ),
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
                                onPressed: () async {
                                  // Save 'waitlist' step so user returns here on app restart
                                  final authRepo = ref.read(
                                    authenticationRepositoryProvider,
                                  );
                                  await authRepo.saveCurrentOnboardingStep(
                                    'waitlist',
                                  );
                                  if (!mounted) return;
                                  context.go(Routes.waitlist);
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
                                  'I don\'t have an invite code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
