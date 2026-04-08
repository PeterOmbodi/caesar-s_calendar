import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';

sealed class OnboardingEvent {
  const OnboardingEvent();
}

class StartOnboarding extends OnboardingEvent {
  const StartOnboarding(this.mode, {this.isReplay = false});

  final OnboardingMode mode;
  final bool isReplay;
}

class DismissOnboarding extends OnboardingEvent {
  const DismissOnboarding();
}

class NextOnboardingStep extends OnboardingEvent {
  const NextOnboardingStep();
}

class PreviousOnboardingStep extends OnboardingEvent {
  const PreviousOnboardingStep();
}

class CompleteCurrentOnboardingStep extends OnboardingEvent {
  const CompleteCurrentOnboardingStep();
}

class StartCurrentOnboardingInteraction extends OnboardingEvent {
  const StartCurrentOnboardingInteraction();
}
