import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_card.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tutorialDate = DateTime(2024);
  late final steps = [
    OnboardingStep(id: OnboardingStepId.dateGoal, tutorialDate: tutorialDate),
    OnboardingStep(id: OnboardingStepId.dragPiece, tutorialDate: tutorialDate, requiresUserAction: true),
    OnboardingStep(id: OnboardingStepId.drawPiece, tutorialDate: tutorialDate, requiresUserAction: true),
    OnboardingStep(id: OnboardingStepId.rotatePiece, tutorialDate: tutorialDate, requiresUserAction: true),
    OnboardingStep(id: OnboardingStepId.flipPiece, tutorialDate: tutorialDate, requiresUserAction: true),
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
            body: OnboardingCard(step: state.currentStep!, state: state, onTryPressed: onTryPressed),
          ),
        ),
      ),
    );
  }

  group('OnboardingCard', () {
    testWidgets('animates progress item widths when current step changes', (final tester) async {
      OnboardingState stateAt(final int index) => OnboardingState(
        isVisible: true,
        isReplay: false,
        mode: OnboardingMode.short,
        currentStepIndex: index,
        steps: steps,
        isCurrentStepComplete: true,
        isCurrentStepInteractionEnabled: false,
        completedStepIds: const {},
      );

      await pumpCard(tester, state: stateAt(0));

      final firstItem = find.byKey(const ValueKey('onboarding-progress-0'));
      final secondItem = find.byKey(const ValueKey('onboarding-progress-1'));
      expect(firstItem, findsOneWidget);
      expect(secondItem, findsOneWidget);
      final initialFirstWidth = tester.getSize(firstItem).width;
      final initialSecondWidth = tester.getSize(secondItem).width;

      await pumpCard(tester, state: stateAt(1));
      await tester.pump(const Duration(milliseconds: 125));

      final intermediateFirstWidth = tester.getSize(firstItem).width;
      final intermediateSecondWidth = tester.getSize(secondItem).width;
      expect(intermediateFirstWidth, lessThan(initialFirstWidth));
      expect(intermediateFirstWidth, greaterThan(initialSecondWidth));
      expect(intermediateSecondWidth, greaterThan(initialSecondWidth));
      expect(intermediateSecondWidth, lessThan(initialFirstWidth));

      await tester.pumpAndSettle();

      expect(tester.getSize(firstItem).width, closeTo(initialSecondWidth, 0.01));
      expect(tester.getSize(secondItem).width, closeTo(initialFirstWidth, 0.01));
    });

    testWidgets('shows Try and disables Next for incomplete action step', (final tester) async {
      final state = OnboardingState(
        isVisible: true,
        isReplay: false,
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
        isReplay: false,
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

    testWidgets('shows a compact easy-selected difficulty selector with a persistent settings note', (
      final tester,
    ) async {
      final difficultyStep = OnboardingStep(id: OnboardingStepId.difficulty, tutorialDate: tutorialDate);
      final state = OnboardingState(
        isVisible: true,
        isReplay: false,
        mode: OnboardingMode.short,
        currentStepIndex: steps.length,
        steps: [...steps, difficultyStep],
        isCurrentStepComplete: false,
        isCurrentStepInteractionEnabled: false,
        completedStepIds: const {},
        pendingDifficulty: SolutionIndicator.countSolutions,
      );

      await pumpCard(tester, state: state);

      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
      expect(find.byIcon(Icons.balance_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      expect(
        find.text('Difficulty, timer, theme, language, and more can be changed anytime in Settings.'),
        findsOneWidget,
      );

      final doneButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Ok'));
      expect(doneButton.onPressed, isNotNull);
    });
  });
}
