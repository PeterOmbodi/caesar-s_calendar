import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:caesar_puzzle/presentation/onboarding/bloc/onboarding_event.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_mode.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/onboarding_step_policy.dart';
import 'package:caesar_puzzle/presentation/pages/history/history_screen.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/history_screen_result.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/actions_for.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/how_to_play_hint.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_cupertino_alert_dialog.dart';
import 'package:caesar_puzzle/presentation/widgets/one_time_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

enum _BottomControlIntro { history, allSolutions, hint }

extension _BottomControlIntroX on _BottomControlIntro {
  String get storageKey => 'bottom_control_intro_seen_$name';

  String get title => switch (this) {
    _BottomControlIntro.history => S.current.bottomControlIntroHistoryTitle,
    _BottomControlIntro.allSolutions => S.current.bottomControlIntroAllSolutionsTitle,
    _BottomControlIntro.hint => S.current.bottomControlIntroHintTitle,
  };

  String get message => switch (this) {
    _BottomControlIntro.history => S.current.bottomControlIntroHistoryMessage,
    _BottomControlIntro.allSolutions => S.current.bottomControlIntroAllSolutionsMessage,
    _BottomControlIntro.hint => S.current.bottomControlIntroHintMessage,
  };

  String get actionLabel => switch (this) {
    _BottomControlIntro.history => S.current.onboardingNext,
    _BottomControlIntro.allSolutions => S.current.ok,
    _BottomControlIntro.hint => S.current.ok,
  };
}

class PuzzleToolbar extends StatelessWidget {
  const PuzzleToolbar({super.key});

  Future<bool> _showIntroIfNeeded(final BuildContext context, final _BottomControlIntro intro) =>
      OneTimeInfoDialog.show(
        context: context,
        storageKey: intro.storageKey,
        title: intro.title,
        message: intro.message,
        actionLabel: intro.actionLabel,
      );

  Future<void> _runAfterIntro(
    final BuildContext context,
    final _BottomControlIntro intro,
    final Future<void> Function() action,
  ) async {
    if (!await _showIntroIfNeeded(context, intro)) {
      return;
    }
    await action();
  }

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
        final currentDifficulty = settingsCubit.state.solutionIndicator.sessionDifficulty;
        if (currentDifficulty != session.difficulty) {
          final shouldContinue = await _showDifficultyMismatchDialog(
            context,
            sessionDifficulty: session.difficulty,
            currentDifficulty: currentDifficulty,
          );
          if (shouldContinue != true || !context.mounted) {
            return;
          }
          settingsCubit.setSolutionIndicator(session.difficulty.solutionIndicator);
        }
        if (!context.mounted) {
          return;
        }
        context.read<PuzzleBloc>().add(PuzzleEvent.restoreSession(session));
      case StartPuzzleForDateHistoryResult(:final date):
        context.read<PuzzleBloc>().add(PuzzleEvent.setPuzzleDate(date));
    }
  }

  Future<bool?> _showDifficultyMismatchDialog(
    final BuildContext context, {
    required final PuzzleSessionDifficulty sessionDifficulty,
    required final PuzzleSessionDifficulty currentDifficulty,
  }) => showDialog<bool>(
    context: context,
    builder: (final dialogContext) => PlatformAlertDialog(
      title: Text(S.current.historyDifficultyMismatchTitle),
      content: Text(S.current.historyDifficultyMismatchContent(sessionDifficulty.label, currentDifficulty.label)),
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

  Future<void> _runAssist(
    final BuildContext context,
    final PuzzleState state,
    final AssistGate gate,
    final VoidCallback allowedEvent,
  ) async {
    switch (gate) {
      case AssistGate.open:
        allowedEvent();
      case AssistGate.noSolutions:
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
      case AssistGate.confirmEasy:
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
        if (result == true && context.mounted) {
          context.read<PuzzleBloc>().markCurrentSessionDifficulty(PuzzleSessionDifficulty.easy);
          allowedEvent();
        }
    }
  }

  Future<void> _invoke(final BuildContext context, final PuzzleState state, final GameAction action) async {
    final puzzleBloc = context.read<PuzzleBloc>();
    switch (action.id) {
      case GameActionId.history:
        await _runAfterIntro(context, _BottomControlIntro.history, () => _showHistory(context));
      case GameActionId.hint:
        await _runAfterIntro(
          context,
          _BottomControlIntro.hint,
          () => _runAssist(context, state, action.assistGate!, () => puzzleBloc.add(PuzzleEvent.showHint())),
        );
      case GameActionId.undo:
        puzzleBloc.add(PuzzleEvent.undo());
      case GameActionId.redo:
        puzzleBloc.add(PuzzleEvent.redo());
      case GameActionId.rotate:
        puzzleBloc.add(const PuzzleEvent.rotateSelected());
      case GameActionId.flip:
        puzzleBloc.add(const PuzzleEvent.flipSelected());
      case GameActionId.prevSolution:
        puzzleBloc.add(PuzzleEvent.showSolution(state.solutionIdx - 1));
      case GameActionId.nextSolution:
        puzzleBloc.add(PuzzleEvent.showSolution(state.solutionIdx + 1));
      case GameActionId.solutionCounter:
        break;
      case GameActionId.closeSolutions:
      case GameActionId.restart:
        puzzleBloc.add(PuzzleEvent.reset());
      case GameActionId.showSolutions:
        await _runAfterIntro(
          context,
          _BottomControlIntro.allSolutions,
          () => _runAssist(context, state, action.assistGate!, () => puzzleBloc.add(PuzzleEvent.showSolution(0))),
        );
      case GameActionId.howToPlay:
        await _showHowToPlayDialog(context);
    }
  }

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) => GameChrome.forSpec(
      actions: actionsFor(state, context.watch<SettingsCubit>().state.solutionIndicator),
      spec: ScreenSpec.of(context),
      onInvoke: (final action) => _invoke(context, state, action),
    ),
  );
}
