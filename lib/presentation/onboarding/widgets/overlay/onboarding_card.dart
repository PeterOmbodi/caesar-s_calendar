import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_state.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.step, required this.state, this.onTryPressed});

  final OnboardingStep step;
  final OnboardingState state;
  final VoidCallback? onTryPressed;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tutorialDateText = DateFormat.MMMMd(locale).format(step.tutorialDate);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, minHeight: 272, maxHeight: 272),
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
                  if (state.currentStepIndex > 0)
                    TextButton(
                      onPressed: () => context.read<OnboardingBloc>().add(const PreviousOnboardingStep()),
                      child: Text(S.current.onboardingBack),
                    ),
                  const Spacer(),
                  if (onTryPressed != null) ...[
                    FilledButton.tonal(onPressed: onTryPressed, child: Text(S.current.onboardingTry)),
                    const Spacer(),
                  ],
                  FilledButton(
                    onPressed: step.requiresUserAction && !state.canSkipActionStep
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: showCompletionOnly
                ? Text(step.id.successMessage, style: textTheme.bodyMedium)
                : step.id == OnboardingStepId.dateGoal
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(combinedBodyText, maxLines: 4, overflow: TextOverflow.ellipsis),
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
                : Text(combinedBodyText, maxLines: 5, overflow: TextOverflow.ellipsis),
          ),
        ),
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
