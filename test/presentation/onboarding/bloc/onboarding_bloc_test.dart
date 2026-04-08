import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingBloc', () {
    test('starts short onboarding with initial step available', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isVisible, isTrue);
      expect(bloc.state.steps, hasLength(4));
      expect(bloc.state.currentStep?.id, OnboardingStepId.dateGoal);
      expect(bloc.state.canGoNext, isTrue);
    });

    test('keeps completed drag-step progress after next and previous', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextOnboardingStep());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CompleteCurrentOnboardingStep());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextOnboardingStep());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PreviousOnboardingStep());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.currentStep?.id, OnboardingStepId.dragPiece);
      expect(bloc.state.isCurrentStepPreviouslyCompleted, isTrue);
      expect(bloc.state.isCurrentStepComplete, isFalse);
      expect(bloc.state.canGoNext, isTrue);
      expect(bloc.state.isCurrentStepInteractionEnabled, isFalse);
    });
  });
}
