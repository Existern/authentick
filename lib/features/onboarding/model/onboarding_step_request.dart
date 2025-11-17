class OnboardingStepRequest {
  final String step;
  final String? action;

  OnboardingStepRequest({
    required this.step,
    this.action,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'step': step,
    };

    if (action != null) {
      json['action'] = action;
    }

    return json;
  }
}
