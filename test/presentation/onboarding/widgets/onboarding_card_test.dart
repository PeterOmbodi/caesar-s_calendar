import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tutorialDate = DateTime(2024);
  late final steps = [
    OnboardingStep(
      id: OnboardingStepId.dateGoal,
      tutorialDate: tutorialDate,
    ),
    OnboardingStep(
      id: OnboardingStepId.dragPiece,
      tutorialDate: tutorialDate,
      requiresUserAction: true,
    ),
    OnboardingStep(
      id: OnboardingStepId.rotatePiece,
      tutorialDate: tutorialDate,
      requiresUserAction: true,
    ),
    OnboardingStep(
      id: OnboardingStepId.flipPiece,
      tutorialDate: tutorialDate,
      requiresUserAction: true,
    ),
  ];

  Future<void> pumpCard(
    final WidgetTester tester, {
    required final OnboardingState state,
    final VoidCallback? onTryPressed,
  }) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => OnboardingBloc(),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: OnboardingCard(
              step: state.currentStep!,
              state: state,
              onTryPressed: onTryPressed,
            ),
          ),
        ),
      ),
    );
  }

  group('OnboardingCard', () {
    testWidgets('shows Try and disables Next for incomplete action step', (final tester) async {
      final state = OnboardingState(
        isVisible: true,
        mode: OnboardingMode.short,
        currentStepIndex: 1,
        steps: steps,
        isCurrentStepComplete: false,
        isCurrentStepInteractionEnabled: false,
        completedStepIds: const {},
      );

      await pumpCard(tester, state: state, onTryPressed: () {});

      expect(find.text('Try'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      final nextButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('hides Try and shows success message for completed drag step', (final tester) async {
      final state = OnboardingState(
        isVisible: true,
        mode: OnboardingMode.short,
        currentStepIndex: 1,
        steps: steps,
        isCurrentStepComplete: true,
        isCurrentStepInteractionEnabled: false,
        completedStepIds: const {OnboardingStepId.dragPiece},
      );

      await pumpCard(tester, state: state);

      expect(find.text('Try'), findsNothing);
      expect(find.text('Great. The drag was detected.'), findsOneWidget);

      final nextButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
      expect(nextButton.onPressed, isNotNull);
    });
  });
}
