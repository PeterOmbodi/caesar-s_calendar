import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState.hidden()) {
    on<StartOnboarding>(_onStart);
    on<DismissOnboarding>(_onDismiss);
    on<NextOnboardingStep>(_onNextStep);
    on<PreviousOnboardingStep>(_onPreviousStep);
    on<CompleteCurrentOnboardingStep>(_onCompleteCurrentStep);
    on<StartCurrentOnboardingInteraction>(_onStartCurrentInteraction);
  }

  static final DateTime _tutorialDate = DateTime(2024);

  static final List<OnboardingStep> _basicSteps = [
    OnboardingStep(
      id: OnboardingStepId.dateGoal,
      tutorialDate: _tutorialDate,
      highlightedLabelIndices: [0, 12],
    ),
    OnboardingStep(
      id: OnboardingStepId.dragPiece,
      tutorialDate: _tutorialDate,
      requiresUserAction: true,
    ),
    OnboardingStep(
      id: OnboardingStepId.rotatePiece,
      tutorialDate: _tutorialDate,
      requiresUserAction: true,
    ),
    OnboardingStep(
      id: OnboardingStepId.flipPiece,
      tutorialDate: _tutorialDate,
      requiresUserAction: true,
    ),
  ];

  static const List<OnboardingStep> _extendedSteps = [];

  void _onStart(
    final StartOnboarding event,
    final Emitter<OnboardingState> emit,
  ) {
    emit(
      OnboardingState(
        isVisible: true,
        mode: event.mode,
        currentStepIndex: 0,
        steps: _stepsForMode(event.mode),
        isCurrentStepComplete: false,
        isCurrentStepInteractionEnabled: false,
        completedStepIds: const {},
      ),
    );
  }

  void _onDismiss(
    final DismissOnboarding event,
    final Emitter<OnboardingState> emit,
  ) {
    emit(const OnboardingState.hidden());
  }

  void _onNextStep(
    final NextOnboardingStep event,
    final Emitter<OnboardingState> emit,
  ) {
    final step = state.currentStep;
    if (step == null) {
      return;
    }
    if (step.requiresUserAction && !state.canGoNext) {
      return;
    }

    final nextIndex = state.currentStepIndex + 1;
    if (nextIndex >= state.steps.length) {
      emit(const OnboardingState.hidden());
      return;
    }

    emit(
      state.copyWith(
        currentStepIndex: nextIndex,
        isCurrentStepComplete: !state.steps[nextIndex].requiresUserAction,
        isCurrentStepInteractionEnabled: false,
      ),
    );
  }

  void _onPreviousStep(
    final PreviousOnboardingStep event,
    final Emitter<OnboardingState> emit,
  ) {
    if (state.currentStepIndex <= 0) {
      return;
    }
    final previousIndex = state.currentStepIndex - 1;
    emit(
      state.copyWith(
        currentStepIndex: previousIndex,
        isCurrentStepComplete: false,
        isCurrentStepInteractionEnabled: false,
      ),
    );
  }

  void _onCompleteCurrentStep(
    final CompleteCurrentOnboardingStep event,
    final Emitter<OnboardingState> emit,
  ) {
    if (state.isCurrentStepComplete) {
      return;
    }
    emit(
      state.copyWith(
        isCurrentStepComplete: true,
        isCurrentStepInteractionEnabled: false,
        completedStepIds: {...state.completedStepIds, state.currentStep!.id},
      ),
    );
  }

  void _onStartCurrentInteraction(
    final StartCurrentOnboardingInteraction event,
    final Emitter<OnboardingState> emit,
  ) {
    if (state.currentStep?.requiresUserAction != true || state.isCurrentStepInteractionEnabled) {
      return;
    }
    emit(state.copyWith(isCurrentStepInteractionEnabled: true));
  }

  List<OnboardingStep> _stepsForMode(final OnboardingMode mode) {
    switch (mode) {
      case OnboardingMode.short:
        return _basicSteps;
      case OnboardingMode.full:
        return [..._basicSteps, ..._extendedSteps];
    }
  }
}
