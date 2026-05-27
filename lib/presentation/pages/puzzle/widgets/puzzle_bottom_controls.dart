import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/pages/history/history_screen.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/history_screen_result.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/widgets/floating_panel.dart';
import 'package:caesar_puzzle/presentation/widgets/how_to_play_hint.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_cupertino_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PuzzleBottomControls extends StatelessWidget {
  const PuzzleBottomControls({super.key, required this.isSetupVisible});

  final bool isSetupVisible;

  Future<void> _showHowToPlayDialog(final BuildContext context) async {
    final viewWidth = MediaQuery.of(context).size.width;
    final horizontalInset = viewWidth < 600 ? 12.0 : 40.0;

    void replayOnboarding() {
      Navigator.of(context, rootNavigator: true).pop();
      context.read<SettingsCubit>().markOnboardingOffered(currentOnboardingVersion);
      context.read<OnboardingBloc>().add(const StartOnboarding(OnboardingMode.short, isReplay: true));
    }

    await showPlatformDialog(
      context: context,
      material: MaterialDialogData(
        builder: (final context) => PlatformAlertDialog(
          material: (final context, final platform) =>
              MaterialAlertDialogData(insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset)),
          title: Text(S.current.howToPlayTitle),
          content: HowToPlayHint(onReplayOnboarding: replayOnboarding),
          actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok))],
        ),
      ),
      cupertino: CupertinoDialogData(
        builder: (final dialogContext) => InsetCupertinoAlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
          title: Text(S.current.howToPlayTitle),
          content: HowToPlayHint(onReplayOnboarding: replayOnboarding),
          actionLabel: S.current.ok,
          onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
        ),
      ),
    );
  }

  Future<void> _showHistory(final BuildContext context) async {
    final result = await Navigator.of(context).push<HistoryScreenResult>(
      PageRouteBuilder<HistoryScreenResult>(
        pageBuilder: (final context, final animation, final secondaryAnimation) => const HistoryScreen(),
        transitionsBuilder: (final context, final animation, final secondaryAnimation, final child) {
          final offsetAnimation = animation.drive(
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
          );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }
    switch (result) {
      case ResumeHistorySessionResult(:final session):
        final settingsCubit = context.read<SettingsCubit>();
        final currentDifficulty = _difficultyFromSettings(settingsCubit.state.solutionIndicator);
        if (currentDifficulty != session.difficulty) {
          final shouldContinue = await _showDifficultyMismatchDialog(
            context,
            sessionDifficulty: session.difficulty,
            currentDifficulty: currentDifficulty,
          );
          if (shouldContinue != true || !context.mounted) {
            return;
          }
          settingsCubit.setSolutionIndicator(
            session.difficulty == PuzzleSessionDifficulty.easy
                ? SolutionIndicator.countSolutions
                : SolutionIndicator.none,
          );
        }
        if (!context.mounted) {
          return;
        }
        context.read<PuzzleBloc>().add(PuzzleEvent.restoreSession(session));
      case StartPuzzleForDateHistoryResult(:final date):
        context.read<PuzzleBloc>().add(PuzzleEvent.setPuzzleDate(date));
    }
  }

  PuzzleSessionDifficulty _difficultyFromSettings(final SolutionIndicator indicator) =>
      indicator == SolutionIndicator.none ? PuzzleSessionDifficulty.hard : PuzzleSessionDifficulty.easy;

  Future<bool?> _showDifficultyMismatchDialog(
    final BuildContext context, {
    required final PuzzleSessionDifficulty sessionDifficulty,
    required final PuzzleSessionDifficulty currentDifficulty,
  }) => showDialog<bool>(
    context: context,
    builder: (final dialogContext) => PlatformAlertDialog(
      title: Text(S.current.historyDifficultyMismatchTitle),
      content: Text(
        S.current.historyDifficultyMismatchContent(
          _historyDifficultyLabel(sessionDifficulty),
          _historyDifficultyLabel(currentDifficulty),
        ),
      ),
      actions: [
        PlatformDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(S.current.historySessionDialogCancel),
        ),
        PlatformDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(S.current.historyDifficultyMismatchContinue),
        ),
      ],
    ),
  );

  String _historyDifficultyLabel(final PuzzleSessionDifficulty difficulty) =>
      difficulty == PuzzleSessionDifficulty.hard ? S.current.historyDifficultyHard : S.current.historyDifficultyEasy;

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) {
      final solutionsCount = state.applicableSolutions.length;
      final puzzleBloc = context.read<PuzzleBloc>();
      final solutionIndicator = context.watch<SettingsCubit>().state.solutionIndicator;
      final isSolvabilityInfoVisible = solutionIndicator != SolutionIndicator.none;
      final isSolveDisabled =
          state.isSolving || (isSolvabilityInfoVisible && solutionsCount == 0) || state.isShowSolutions;

      Future<void> onAssistPressed(final VoidCallback allowedEvent) async {
        if (solutionsCount == 0) {
          await showDialog(
            context: context,
            builder: (final context) => PlatformAlertDialog(
              title: Text(S.of(context).searchCompletedDialogTitle),
              content: Text(S.of(context).solutionsNotFoundDialogMessage),
              actions: [
                PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok)),
              ],
            ),
          );
          return;
        }
        if (isSolvabilityInfoVisible) {
          allowedEvent.call();
        } else {
          final result = await showDialog<bool>(
            context: context,
            builder: (final context) => PlatformAlertDialog(
              title: Text(S.of(context).searchCompletedDialogTitle),
              content: Text(S.of(context).solutionsFoundDialogMessage(state.applicableSolutions.length)),
              actions: [
                PlatformDialogAction(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.of(context).solutionsFoundDialogCancel),
                ),
                PlatformDialogAction(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(S.of(context).solutionsFoundDialogOk),
                ),
              ],
            ),
          );
          if (result == true) {
            puzzleBloc.markCurrentSessionEasy();
            allowedEvent.call();
          }
        }
      }

      return FloatingPanel(
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showHowToPlayDialog(context),
            tooltip: S.current.howToPlayTitle,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
            tooltip: S.current.historyTitle,
          ),
          IconButton(
            icon: Icon(Icons.lightbulb),
            onPressed: isSolveDisabled
                ? null
                : () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.showSolution(0))),
            tooltip: S.current.searchSolution,
          ),
          if (isSetupVisible)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: S.current.settings,
            ),
        ],
      );
    },
  );
}
