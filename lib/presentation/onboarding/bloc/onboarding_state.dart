import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';

class OnboardingState {
  const OnboardingState({
    required this.isVisible,
    required this.isReplay,
    required this.mode,
    required this.currentStepIndex,
    required this.steps,
    required this.isCurrentStepComplete,
    required this.isCurrentStepInteractionEnabled,
    required this.completedStepIds,
  });

  const OnboardingState.hidden()
    : isVisible = false,
      isReplay = false,
      mode = OnboardingMode.short,
      currentStepIndex = 0,
      steps = const [],
      isCurrentStepComplete = false,
      isCurrentStepInteractionEnabled = false,
      completedStepIds = const {};

  final bool isVisible;
  final bool isReplay;
  final OnboardingMode mode;
  final int currentStepIndex;
  final List<OnboardingStep> steps;
  final bool isCurrentStepComplete;
  final bool isCurrentStepInteractionEnabled;
  final Set<OnboardingStepId> completedStepIds;

  OnboardingStep? get currentStep =>
      currentStepIndex >= 0 && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null;

  bool get isCurrentStepPreviouslyCompleted =>
      currentStep != null && completedStepIds.contains(currentStep!.id);

  bool get canGoNext => currentStep?.requiresUserAction != true || isCurrentStepComplete || isCurrentStepPreviouslyCompleted;
  bool get canSkipActionStep => isReplay || canGoNext;

  OnboardingState copyWith({
    final bool? isVisible,
    final bool? isReplay,
    final OnboardingMode? mode,
    final int? currentStepIndex,
    final List<OnboardingStep>? steps,
    final bool? isCurrentStepComplete,
    final bool? isCurrentStepInteractionEnabled,
    final Set<OnboardingStepId>? completedStepIds,
  }) => OnboardingState(
    isVisible: isVisible ?? this.isVisible,
    isReplay: isReplay ?? this.isReplay,
    mode: mode ?? this.mode,
    currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    steps: steps ?? this.steps,
    isCurrentStepComplete: isCurrentStepComplete ?? this.isCurrentStepComplete,
    isCurrentStepInteractionEnabled:
        isCurrentStepInteractionEnabled ?? this.isCurrentStepInteractionEnabled,
    completedStepIds: completedStepIds ?? this.completedStepIds,
  );
}
