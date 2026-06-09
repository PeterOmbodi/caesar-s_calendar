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
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/floating_panel.dart';
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

class PuzzleBottomControls extends StatelessWidget {
  const PuzzleBottomControls({super.key, required this.isSetupVisible});

  final bool isSetupVisible;

  Future<bool> _showIntroIfNeeded(final BuildContext context, final _BottomControlIntro intro) => OneTimeInfoDialog.show(
    context: context,
    storageKey: intro.storageKey,
    title: intro.title,
    message: intro.message,
    actionLabel: intro.actionLabel,
  );

  Future<void> _runAfterIntro(final BuildContext context, final _BottomControlIntro intro, final Future<void> Function() action) async {
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
        PlatformDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(S.current.historySessionDialogCancel)),
        PlatformDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(S.current.historyDifficultyMismatchContinue),
        ),
      ],
    ),
  );

  List<Widget> _buildMoreControls(final BuildContext context, final PuzzleState state) => [
    IconButton(
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => _showHowToPlayDialog(context),
      tooltip: S.current.howToPlayTitle,
    ),
    if (isSetupVisible)
      IconButton(icon: Icon(Icons.settings), onPressed: () => Scaffold.of(context).openEndDrawer(), tooltip: S.current.settings),
    state.isSolving
        ? const SizedBox(
            width: FloatingPanel.buttonSize,
            height: FloatingPanel.buttonSize,
            child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
          )
        : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PuzzleBloc>().add(PuzzleEvent.reset()),
            tooltip: S.current.reset,
          ),
  ];

  ToolbarControlGroup _buildSolutionControls({
    required final BuildContext context,
    required final PuzzleState state,
    required final int solutionsCount,
    required final PuzzleBloc puzzleBloc,
    required final Widget showSolutionButton,
  }) {
    final isShowingSolutions = state.isShowSolutions && solutionsCount > 0;
    return ToolbarControlGroup(
      showOutline: isShowingSolutions,
      children: [
        showSolutionButton,
        if (isShowingSolutions) ...[
          IconButton(
            icon: const Icon(Icons.arrow_left),
            onPressed: () => puzzleBloc.add(PuzzleEvent.showSolution(state.solutionIdx - 1)),
            tooltip: S.current.prevSolution,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () => puzzleBloc.add(PuzzleEvent.showSolution(state.solutionIdx + 1)),
            tooltip: S.current.nextSolution,
          ),
        ] else ...[
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: state.isUndoEnabled ? () => puzzleBloc.add(PuzzleEvent.undo()) : null,
            tooltip: S.current.undo,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: state.isRedoEnabled ? () => puzzleBloc.add(PuzzleEvent.redo()) : null,
            tooltip: S.current.redo,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) {
      final solutionsCount = state.applicableSolutions.length;
      final puzzleBloc = context.read<PuzzleBloc>();
      final solutionIndicator = context.watch<SettingsCubit>().state.solutionIndicator;
      final isSolvabilityInfoVisible = solutionIndicator != SolutionIndicator.none;
      final isSolutionSearchDisabled = state.isSolving || (isSolvabilityInfoVisible && solutionsCount == 0) || state.isShowSolutions;
      final isHintDisabled = isSolutionSearchDisabled || state.isSolved;

      Future<void> onAssistPressed(final VoidCallback allowedEvent) async {
        if (solutionsCount == 0) {
          await showDialog(
            context: context,
            builder: (final context) => PlatformAlertDialog(
              title: Text(S.of(context).searchCompletedDialogTitle),
              content: Text(S.of(context).solutionsNotFoundDialogMessage),
              actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.of(context).ok))],
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
                PlatformDialogAction(onPressed: () => Navigator.of(context).pop(true), child: Text(S.of(context).solutionsFoundDialogOk)),
              ],
            ),
          );
          if (result == true) {
            puzzleBloc.markCurrentSessionDifficulty(PuzzleSessionDifficulty.easy);
            allowedEvent.call();
          }
        }
      }

      final showSolutionButton = IconButton(
        icon: Icon(Icons.lightbulb),
        style: state.isShowSolutions ? selectedToolbarIconButtonStyle(context) : null,
        onPressed: state.isShowSolutions
            ? () => puzzleBloc.add(PuzzleEvent.reset())
            : isSolutionSearchDisabled
            ? null
            : () => _runAfterIntro(
                context,
                _BottomControlIntro.allSolutions,
                () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.showSolution(0))),
              ),
        tooltip: S.current.searchSolution,
      );
      final solutionControls = _buildSolutionControls(
        context: context,
        state: state,
        solutionsCount: solutionsCount,
        puzzleBloc: puzzleBloc,
        showSolutionButton: showSolutionButton,
      );

      return FloatingPanel(
        morePanel: FloatingVerticalMoreToolbar(
          moreTooltip: S.current.showControls,
          closeTooltip: S.current.hideControls,
          children: _buildMoreControls(context, state),
        ),
        children: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _runAfterIntro(context, _BottomControlIntro.history, () => _showHistory(context)),
            tooltip: S.current.historyTitle,
          ),
          solutionControls,
          IconButton(
            icon: Icon(Icons.tips_and_updates_outlined),
            onPressed: isHintDisabled
                ? null
                : () => _runAfterIntro(
                    context,
                    _BottomControlIntro.hint,
                    () => onAssistPressed(() => puzzleBloc.add(PuzzleEvent.showHint())),
                  ),
            tooltip: S.current.hint,
          ),
        ],
      );
    },
  );
}
