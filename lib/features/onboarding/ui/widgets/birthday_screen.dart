import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../authentication/repository/authentication_repository.dart';
import '../../../profile/repository/profile_repository.dart';
import '../../view_model/onboarding_view_model.dart';

class BirthdayScreen extends ConsumerStatefulWidget {
  const BirthdayScreen({super.key});

  @override
  ConsumerState<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends ConsumerState<BirthdayScreen> {
  String? _errorMessage;
  bool _isUpdating = false;

  // Date picker state
  int _selectedDay = 1;
  int _selectedMonth = 1; // January
  int _selectedYear = 2007;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Initialize controllers inline
  final FixedExtentScrollController _dayController =
      FixedExtentScrollController(initialItem: 0);
  final FixedExtentScrollController _monthController =
      FixedExtentScrollController(initialItem: 0);
  final FixedExtentScrollController _yearController =
      FixedExtentScrollController(initialItem: 107); // 2007 - 1900

  @override
  void initState() {
    super.initState();
    // Save current step so user returns to birthday screen on app restart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authRepo = ref.read(authenticationRepositoryProvider);
      authRepo.saveCurrentOnboardingStep('birthday');
      _updateBirthday();
    });
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _updateBirthday() {
    // Format: DDMMYYYY
    final day = _selectedDay.toString().padLeft(2, '0');
    final month = _selectedMonth.toString().padLeft(2, '0');
    final year = _selectedYear.toString();
    final birthday = '$day$month$year';

    ref.read(onboardingViewModelProvider.notifier).updateBirthday(birthday);

    // Clear error message when selection changes
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  int _getDaysInMonth(int month, int year) {
    if (month == 2) {
      // February
      bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
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
    final state = ref.read(onboardingViewModelProvider);
    if (state.birthday.length != 8) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      // Convert DDMMYYYY to YYYY-MM-DD
      final apiDateFormat = _convertToApiFormat(state.birthday);

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

                  const SizedBox(height: 48),

                  // Date picker wheels
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day picker
                        Expanded(
                          child: _buildWheelPicker(
                            controller: _dayController,
                            itemCount: _getDaysInMonth(
                              _selectedMonth,
                              _selectedYear,
                            ),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedDay = index + 1;
                              });
                              _updateBirthday();
                            },
                            itemBuilder: (index) => (index + 1).toString(),
                          ),
                        ),
                        // Month picker
                        Expanded(
                          flex: 2,
                          child: _buildWheelPicker(
                            controller: _monthController,
                            itemCount: 12,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedMonth = index + 1;
                                // Adjust day if it exceeds the new month's max days
                                int maxDays = _getDaysInMonth(
                                  _selectedMonth,
                                  _selectedYear,
                                );
                                if (_selectedDay > maxDays) {
                                  _selectedDay = maxDays;
                                  _dayController.jumpToItem(_selectedDay - 1);
                                }
                              });
                              _updateBirthday();
                            },
                            itemBuilder: (index) => _months[index],
                          ),
                        ),
                        // Year picker
                        Expanded(
                          flex: 2,
                          child: _buildWheelPicker(
                            controller: _yearController,
                            itemCount: 126, // 1900 to 2025
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedYear = 1900 + index;
                                // Adjust day if it's Feb 29 and not a leap year
                                int maxDays = _getDaysInMonth(
                                  _selectedMonth,
                                  _selectedYear,
                                );
                                if (_selectedDay > maxDays) {
                                  _selectedDay = maxDays;
                                  _dayController.jumpToItem(_selectedDay - 1);
                                }
                              });
                              _updateBirthday();
                            },
                            itemBuilder: (index) => (1900 + index).toString(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

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
                      onPressed: !_isUpdating ? _submitBirthday : null,
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

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int) itemBuilder,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Selection indicator
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4300FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // Wheel picker
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 50,
          perspective: 0.003,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= itemCount) return null;
              return Center(
                child: Text(
                  itemBuilder(index),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mono100,
                  ),
                ),
              );
            },
            childCount: itemCount,
          ),
        ),
      ],
    );
  }
}
