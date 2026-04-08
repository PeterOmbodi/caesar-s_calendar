enum OnboardingStepId {
  dateGoal,
  dragPiece,
  rotatePiece,
  flipPiece,
}

class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.tutorialDate,
    this.highlightedLabelIndices = const [],
    this.highlightGrid = false,
    this.requiresUserAction = false,
  });

  final OnboardingStepId id;
  final DateTime tutorialDate;
  final List<int> highlightedLabelIndices;
  final bool highlightGrid;
  final bool requiresUserAction;
}
