import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_sheet.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/history_screen.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/history_screen_result.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/actions_for.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action_visuals.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/chrome/game_chrome.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/assist_prompt.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/solution_indicator_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:caesar_puzzle/presentation/widgets/coach_mark.dart';
import 'package:caesar_puzzle/presentation/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  Future<bool> _showIntroIfNeeded(final BuildContext context, final _BottomControlIntro intro, final Rect? anchor) =>
      CoachMark.showOnce(
        context: context,
        storageKey: intro.storageKey,
        anchor: anchor,
        title: intro.title,
        message: intro.message,
        actionLabel: intro.actionLabel,
      );

  Future<void> _runAfterIntro(
    final BuildContext context,
    final _BottomControlIntro intro,
    final Rect? anchor,
    final Future<void> Function() action,
  ) async {
    if (!await _showIntroIfNeeded(context, intro, anchor)) {
      return;
    }
    await action();
  }

  Future<void> _showHistory(final BuildContext context) async {
    final puzzleState = context.read<PuzzleBloc>().state;
    final result = await Navigator.of(context).push(
      MaterialPageRoute<HistoryScreenResult>(
        builder: (_) => HistoryScreen(initialDate: puzzleState.selectedDate, boardBlocked: puzzleState.blockedCells),
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
          if (!shouldContinue || !context.mounted) {
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

  Future<bool> _showDifficultyMismatchDialog(
    final BuildContext context, {
    required final PuzzleSessionDifficulty sessionDifficulty,
    required final PuzzleSessionDifficulty currentDifficulty,
  }) => ConfirmDialog.show(
    context,
    title: S.current.historyDifficultyMismatchTitle,
    message: S.current.historyDifficultyMismatchContent(sessionDifficulty.label, currentDifficulty.label),
    cancelLabel: S.current.historySessionDialogCancel,
    confirmLabel: S.current.historyDifficultyMismatchContinue,
  );

  Future<void> _runAssist(final BuildContext context, final AssistGate gate, final VoidCallback allowedEvent) async {
    final bloc = context.read<PuzzleBloc>();
    final allowed = await confirmAssist(context, gate: gate, countsForRecords: bloc.countsForRecords);
    if (gate == AssistGate.noSolutions) bloc.markAssisted();
    if (allowed && context.mounted) allowedEvent();
  }

  Future<void> _invoke(
    final BuildContext context,
    final PuzzleState state,
    final GameAction action,
    final Rect? anchor,
  ) async {
    final puzzleBloc = context.read<PuzzleBloc>();
    switch (action.id) {
      case GameActionId.history:
        await _runAfterIntro(context, _BottomControlIntro.history, anchor, () => _showHistory(context));
      case GameActionId.hint:
        await _runAfterIntro(
          context,
          _BottomControlIntro.hint,
          anchor,
          () => _runAssist(context, action.assistGate!, () => puzzleBloc.add(PuzzleEvent.showHint())),
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
          anchor,
          () => _runAssist(context, action.assistGate!, () => puzzleBloc.add(PuzzleEvent.showSolution(0))),
        );
      case GameActionId.howToPlay:
        await showHowToPlaySheet(context);
      case GameActionId.cancelEdit:
        puzzleBloc.add(const PuzzleEvent.cancelLayoutEdit());
      case GameActionId.resetLayout:
        puzzleBloc.add(const PuzzleEvent.resetLayoutEdit());
      case GameActionId.saveLayout:
        await _saveLayout(context, state);
    }
  }

  Future<void> _saveLayout(final BuildContext context, final PuzzleState state) async {
    final edit = state.layoutEdit;
    if (edit == null) {
      return;
    }
    final bloc = context.read<PuzzleBloc>();
    final layouts = context.read<BoardLayoutsCubit>();
    final existing = layouts.state.entryWithKey(cellsKey(state.blockedCells))?.layout;
    if (existing != null) {
      if (await _confirmPlayExisting(context, existing)) {
        bloc.add(PuzzleEvent.applyLayout(existing.placements));
      }
      return;
    }
    final placements = state.configPlacements;
    final name = edit.name ?? await showLayoutNameDialog(context, S.current.layoutsSaveTitle, '');
    if (name == null || !context.mounted) {
      return;
    }
    await layouts.saveEdited(replacedId: edit.layoutId, name: name, placements: placements);
    bloc.add(PuzzleEvent.applyLayout(placements));
  }

  Future<bool> _confirmPlayExisting(final BuildContext context, final BoardLayout layout) => ConfirmDialog.show(
    context,
    title: S.current.layoutsDuplicateTitle,
    message: S.current.layoutsDuplicateMessage(layout.isStandard ? S.current.historyConfigStandard : layout.name),
    cancelLabel: S.current.layoutsCancel,
    confirmLabel: S.current.layoutsDuplicatePlay,
  );

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    builder: (final context, final state) {
      final actions = actionsFor(state, context.watch<SettingsCubit>().state.solutionIndicator);
      final apple = hostIsApple;
      return CallbackShortcuts(
        bindings: {
          for (final action in actions)
            if (action.enabled && action.id.shortcut(apple: apple) != null)
              action.id.shortcut(apple: apple)!: () => _invoke(context, state, action, null),
        },
        child: Focus(
          autofocus: true,
          child: GameChrome.forSpec(
            actions: actions,
            spec: ScreenSpec.of(context),
            onInvoke: (final action, final anchor) => _invoke(context, state, action, anchor),
          ),
        ),
      );
    },
  );
}
