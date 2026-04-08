import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';

const int currentOnboardingVersion = 1;

enum OnboardingInputAction { tap, drag, doubleTap }

enum OnboardingPShapeSetup {
  board,
  target,
  targetRotated90,
}

extension OnboardingStepIdPolicyX on OnboardingStepId {
  bool get supportsTry => this != OnboardingStepId.dateGoal;

  bool get usesGridInteractionHole =>
      this == OnboardingStepId.rotatePiece || this == OnboardingStepId.flipPiece;

  bool get showsCompletionMessage =>
      this == OnboardingStepId.dragPiece ||
      this == OnboardingStepId.rotatePiece ||
      this == OnboardingStepId.flipPiece;

  OnboardingInputAction? get allowedInputAction {
    if (this == OnboardingStepId.dragPiece) {
      return OnboardingInputAction.drag;
    }
    if (this == OnboardingStepId.rotatePiece) {
      return OnboardingInputAction.tap;
    }
    if (this == OnboardingStepId.flipPiece) {
      return OnboardingInputAction.doubleTap;
    }
    return null;
  }

  OnboardingPShapeSetup get pShapeSetup {
    if (this == OnboardingStepId.rotatePiece) {
      return OnboardingPShapeSetup.target;
    }
    if (this == OnboardingStepId.flipPiece) {
      return OnboardingPShapeSetup.targetRotated90;
    }
    return OnboardingPShapeSetup.board;
  }

  String get stepTitle => switch (this) {
    OnboardingStepId.dateGoal => S.current.onboardingGoalTitle,
    OnboardingStepId.dragPiece => S.current.onboardingDragTitle,
    OnboardingStepId.rotatePiece => S.current.onboardingRotateTitle,
    OnboardingStepId.flipPiece => S.current.onboardingFlipTitle,
  };

  String get stepDescription => switch (this) {
    OnboardingStepId.dateGoal => S.current.onboardingGoalDescription,
    OnboardingStepId.dragPiece => S.current.onboardingDragDescription,
    OnboardingStepId.rotatePiece => S.current.onboardingRotateDescription,
    OnboardingStepId.flipPiece => S.current.onboardingFlipDescription,
  };

  String get successMessage => switch (this) {
    OnboardingStepId.dateGoal => '',
    OnboardingStepId.dragPiece => S.current.onboardingDragDetected,
    OnboardingStepId.rotatePiece => S.current.onboardingRotateDetected,
    OnboardingStepId.flipPiece => S.current.onboardingFlipDetected,
  };

  String instructionText({required final bool isInteractionEnabled}) {
    if (this == OnboardingStepId.dragPiece) {
      return isInteractionEnabled
          ? S.current.onboardingDragTryNow
          : S.current.onboardingDragPrompt;
    }
    if (this == OnboardingStepId.rotatePiece) {
      return isInteractionEnabled
          ? S.current.onboardingRotateTryNow
          : S.current.onboardingRotatePrompt;
    }
    if (this == OnboardingStepId.flipPiece) {
      return isInteractionEnabled
          ? S.current.onboardingFlipTryNow
          : S.current.onboardingFlipPrompt;
    }
    return S.current.onboardingWaitingForAction;
  }
}
