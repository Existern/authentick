class SkipOnboardingRequest {
  final String step;

  SkipOnboardingRequest({required this.step});

  Map<String, dynamic> toJson() {
    return {
      'step': step,
    };
  }
}
