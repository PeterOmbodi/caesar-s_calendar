import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingBloc', () {
    test('starts short onboarding with initial step available', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isVisible, isTrue);
      expect(bloc.state.steps, hasLength(6));
      expect(bloc.state.currentStep?.id, OnboardingStepId.dateGoal);
      expect(bloc.state.canGoNext, isTrue);
    });

    test('adds difficulty selection after the first-run tutorial', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.steps.last.id, OnboardingStepId.difficulty);
    });

    test('preselects easy difficulty for the first-run onboarding', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.pendingDifficulty, SolutionIndicator.countSolutions);
    });

    test('does not add difficulty selection to onboarding replay', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short, isReplay: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.steps.map((final step) => step.id), isNot(contains(OnboardingStepId.difficulty)));
    });

    test('keeps selected difficulty pending until the final onboarding action', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short));
      await Future<void>.delayed(Duration.zero);
      await _advanceToDifficulty(bloc);
      bloc.add(const SelectOnboardingDifficulty(SolutionIndicator.solvability));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isVisible, isTrue);
      expect(bloc.state.pendingDifficulty, SolutionIndicator.solvability);

      bloc.add(const NextOnboardingStep());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isVisible, isFalse);
      expect(bloc.state.selectedDifficulty, SolutionIndicator.solvability);
    });

    test('starts v2 update onboarding with only draw step for users who completed v1', () async {
      final bloc = OnboardingBloc();
      addTearDown(bloc.close);

      bloc.add(const StartOnboarding(OnboardingMode.short, completedVersion: 1));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isVisible, isTrue);
      expect(bloc.state.steps, hasLength(1));
      expect(bloc.state.currentStep?.id, OnboardingStepId.drawPiece);
      expect(bloc.state.canGoNext, isFalse);
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

Future<void> _advanceToDifficulty(final OnboardingBloc bloc) async {
  bloc.add(const NextOnboardingStep());
  await Future<void>.delayed(Duration.zero);
  for (var index = 0; index < 4; index++) {
    bloc.add(const CompleteCurrentOnboardingStep());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const NextOnboardingStep());
    await Future<void>.delayed(Duration.zero);
  }
}
