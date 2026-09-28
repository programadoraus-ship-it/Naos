class InstitutionOnboardingProgress {
  const InstitutionOnboardingProgress._({
    required this.storedStep,
    required this.resumeStep,
    required this.isCompleted,
    required this.isInconsistent,
    this.message,
  });

  static const lastStep = 9;
  static const visibleSteps = <int>{0, 2, 3, 4, 5, 6, 7, 8, 9};

  final int storedStep;
  final int resumeStep;
  final bool isCompleted;
  final bool isInconsistent;
  final String? message;

  factory InstitutionOnboardingProgress.fromValues({
    required Object? step,
    required Object? completed,
  }) {
    final parsedStep = switch (step) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };
    final storedStep = parsedStep ?? 0;

    if (storedStep < 0 || storedStep > lastStep) {
      return InstitutionOnboardingProgress._(
        storedStep: storedStep,
        resumeStep: 0,
        isCompleted: false,
        isInconsistent: true,
        message: 'The saved onboarding step ($storedStep) is not valid.',
      );
    }

    // Step 1 was merged into Welcome. An incomplete step 9 is a legacy state
    // from the old two-click finish flow and must resume at Make it yours.
    final resumeStep = storedStep == 1
        ? 0
        : storedStep == lastStep && completed != true
        ? 8
        : storedStep;
    final markedCompleted = completed == true;
    final validCompletion = markedCompleted && storedStep == lastStep;
    final inconsistent =
        (markedCompleted && storedStep != lastStep) ||
        (!visibleSteps.contains(resumeStep)) ||
        (!markedCompleted && storedStep == lastStep);

    return InstitutionOnboardingProgress._(
      storedStep: storedStep,
      resumeStep: visibleSteps.contains(resumeStep) ? resumeStep : 0,
      isCompleted: validCompletion,
      isInconsistent: inconsistent,
      message: inconsistent
          ? storedStep == lastStep && !markedCompleted
                ? 'The previous unfinished final step was restored to Make it yours.'
                : 'The saved onboarding completion state does not match step '
                      '$storedStep. The setup will remain incomplete.'
          : storedStep == 1
          ? 'Legacy onboarding step 1 was mapped to Welcome.'
          : null,
    );
  }
}
