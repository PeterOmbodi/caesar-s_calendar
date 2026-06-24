import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.step, required this.state, this.onTryPressed, this.onTryAgainPressed});

  final OnboardingStep step;
  final OnboardingState state;
  final VoidCallback? onTryPressed;
  final VoidCallback? onTryAgainPressed;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tutorialDateText = DateFormat.MMMMd(locale).format(step.tutorialDate);
    final cardHeight = MediaQuery.sizeOf(context).height >= 760 ? 292.0 : 272.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 420, minHeight: cardHeight, maxHeight: cardHeight),
      child: Card(
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: OnboardingCardBody(
                  step: step,
                  state: state,
                  textTheme: textTheme,
                  tutorialDateText: tutorialDateText,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (state.currentStepIndex > 0 && step.id != OnboardingStepId.difficulty)
                    TextButton(
                      onPressed: () => context.read<OnboardingBloc>().add(const PreviousOnboardingStep()),
                      child: Text(S.current.onboardingBack),
                    ),
                  const Spacer(),
                  if (onTryPressed != null) ...[
                    FilledButton.tonal(onPressed: onTryPressed, child: Text(S.current.onboardingTry)),
                    const Spacer(),
                  ],
                  if (onTryAgainPressed != null) ...[
                    TextButton(onPressed: onTryAgainPressed, child: Text(S.current.onboardingTryAgain)),
                    const Spacer(),
                  ],
                  FilledButton(
                    onPressed: step.id == OnboardingStepId.difficulty && state.pendingDifficulty == null
                        ? null
                        : step.requiresUserAction && !state.canSkipActionStep
                        ? null
                        : () => context.read<OnboardingBloc>().add(const NextOnboardingStep()),
                    child: Text(
                      state.currentStepIndex == state.steps.length - 1 ? S.current.ok : S.current.onboardingNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingCardBody extends StatelessWidget {
  const OnboardingCardBody({
    super.key,
    required this.step,
    required this.state,
    required this.textTheme,
    required this.tutorialDateText,
  });

  final OnboardingStep step;
  final OnboardingState state;
  final TextTheme textTheme;
  final String tutorialDateText;

  @override
  Widget build(final BuildContext context) {
    final showCompletionOnly = state.isCurrentStepComplete && step.id.showsCompletionMessage;
    final instructionText = step.requiresUserAction
        ? step.id.instructionText(isInteractionEnabled: state.isCurrentStepInteractionEnabled)
        : '';
    final combinedBodyText = step.id == OnboardingStepId.dateGoal || instructionText.isEmpty
        ? step.id.stepDescription
        : '${step.id.stepDescription}\n$instructionText';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(step.id.stepTitle, style: textTheme.titleLarge)),
            if (step.id != OnboardingStepId.difficulty)
              IconButton(
                onPressed: () => context.read<OnboardingBloc>().add(const DismissOnboarding()),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                tooltip: S.current.onboardingClose,
              ),
          ],
        ),
        const SizedBox(height: 4),
        _OnboardingProgress(state: state),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.centerLeft,
              child: showCompletionOnly
                  ? Text(step.id.successMessage, style: textTheme.bodyMedium)
                  : step.id == OnboardingStepId.difficulty
                  ? _DifficultySelector(selectedDifficulty: state.pendingDifficulty)
                  : step.id == OnboardingStepId.dateGoal
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(combinedBodyText),
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_available, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  tutorialDateText,
                                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(combinedBodyText),
            ),
          ),
        ),
      ],
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.selectedDifficulty});

  final SolutionIndicator? selectedDifficulty;

  @override
  Widget build(final BuildContext context) {
    final description = switch (selectedDifficulty) {
      SolutionIndicator.countSolutions => S.current.onboardingDifficultyEasyDescription,
      SolutionIndicator.solvability => S.current.onboardingDifficultyMediumDescription,
      SolutionIndicator.none => S.current.onboardingDifficultyHardDescription,
      null => S.current.onboardingDifficultySettingsNote,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SegmentedButton<SolutionIndicator>(
            segments: [
              ButtonSegment(
                value: SolutionIndicator.countSolutions,
                label: Text(S.current.onboardingDifficultyEasyTitle),
              ),
              ButtonSegment(
                value: SolutionIndicator.solvability,
                label: Text(S.current.onboardingDifficultyMediumTitle),
              ),
              ButtonSegment(value: SolutionIndicator.none, label: Text(S.current.onboardingDifficultyHardTitle)),
            ],
            selected: selectedDifficulty == null ? const {} : {selectedDifficulty!},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (final selected) {
              if (selected.isEmpty) return;
              context.read<OnboardingBloc>().add(SelectOnboardingDifficulty(selected.first));
            },
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 8),
        Text(S.current.onboardingDifficultySettingsNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.state});

  final OnboardingState state;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < state.steps.length; i++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(color: progressColor(colorScheme, i), borderRadius: BorderRadius.circular(999)),
            ),
          ),
          if (i < state.steps.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Color progressColor(final ColorScheme colorScheme, final int index) {
    if (index <= state.currentStepIndex) {
      return colorScheme.primary;
    }
    return colorScheme.primary.withValues(alpha: 0.18);
  }
}
