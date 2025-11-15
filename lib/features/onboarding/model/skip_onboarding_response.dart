class SkipOnboardingResponse {
  final bool success;
  final OnboardingData data;

  SkipOnboardingResponse({
    required this.success,
    required this.data,
  });

  factory SkipOnboardingResponse.fromJson(Map<String, dynamic> json) {
    return SkipOnboardingResponse(
      success: json['success'] as bool? ?? false,
      data: OnboardingData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class OnboardingData {
  final String userId;
  final bool completed;
  final String? completedAt;
  final List<OnboardingStepInfo> steps;

  OnboardingData({
    required this.userId,
    required this.completed,
    this.completedAt,
    required this.steps,
  });

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    final stepsList = json['steps'] as List<dynamic>? ?? [];
    return OnboardingData(
      userId: json['user_id'] as String,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
      steps: stepsList
          .map((item) => OnboardingStepInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OnboardingStepInfo {
  final String step;
  final String displayName;
  final String status;
  final bool skippable;
  final String? completedAt;

  OnboardingStepInfo({
    required this.step,
    required this.displayName,
    required this.status,
    required this.skippable,
    this.completedAt,
  });

  factory OnboardingStepInfo.fromJson(Map<String, dynamic> json) {
    return OnboardingStepInfo(
      step: json['step'] as String,
      displayName: json['display_name'] as String,
      status: json['status'] as String,
      skippable: json['skippable'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
    );
  }
}
