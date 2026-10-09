import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';

List<GameAction> actionsFor(final PuzzleState state, final SolutionIndicator indicator) {
  final solutionsCount = state.applicableSolutions.length;
  final showsSolvability = indicator != SolutionIndicator.none;
  final isAssistDisabled = state.isSolving || (showsSolvability && solutionsCount == 0) || state.isShowSolutions;
  final assistGate = solutionsCount == 0
      ? AssistGate.noSolutions
      : showsSolvability
      ? AssistGate.open
      : AssistGate.confirmEasy;
  final isBrowsingSolutions = state.isShowSolutions && solutionsCount > 0;

  return [
    const GameAction(GameActionId.history, slot: ActionSlot.primary),
    if (state.isShowSolutions)
      const GameAction(GameActionId.closeSolutions, slot: ActionSlot.primary, active: true)
    else
      GameAction(
        GameActionId.showSolutions,
        slot: ActionSlot.primary,
        enabled: !isAssistDisabled,
        assistGate: assistGate,
      ),
    if (isBrowsingSolutions) ...[
      const GameAction(GameActionId.prevSolution, slot: ActionSlot.primary),
      const GameAction(GameActionId.nextSolution, slot: ActionSlot.primary),
    ] else ...[
      GameAction(GameActionId.undo, slot: ActionSlot.primary, enabled: state.isUndoEnabled),
      GameAction(GameActionId.redo, slot: ActionSlot.primary, enabled: state.isRedoEnabled),
    ],
    GameAction(
      GameActionId.hint,
      slot: ActionSlot.primary,
      enabled: !isAssistDisabled && !state.isSolved,
      assistGate: assistGate,
    ),
    const GameAction(GameActionId.howToPlay, slot: ActionSlot.overflow),
    const GameAction(GameActionId.settings, slot: ActionSlot.overflow),
    GameAction(GameActionId.restart, slot: ActionSlot.overflow, enabled: !state.isSolving, busy: state.isSolving),
  ];
}
