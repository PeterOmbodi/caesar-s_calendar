import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';

List<GameAction> actionsFor(final PuzzleState state, final SolutionIndicator indicator) {
  const history = GameAction(GameActionId.history, slot: ActionSlot.primary);

  if (state.isEditingLayout) {
    final canTransform = state.selectedPiece != null && !state.isSolving;
    return [
      const GameAction(GameActionId.cancelEdit, slot: ActionSlot.primary),
      GameAction(GameActionId.rotate, slot: ActionSlot.primary, enabled: canTransform),
      GameAction(GameActionId.resetLayout, slot: ActionSlot.primary, enabled: state.isLayoutChanged),
      GameAction(GameActionId.flip, slot: ActionSlot.primary, enabled: canTransform),
      GameAction(
        GameActionId.saveLayout,
        slot: ActionSlot.primary,
        enabled: state.isLayoutChanged && !state.isDragging,
        active: true,
      ),
    ];
  }

  if (state.isShowSolutions) {
    final total = state.applicableSolutions.length;
    return [
      history,
      GameAction(GameActionId.prevSolution, slot: ActionSlot.primary, enabled: total > 1),
      GameAction(
        GameActionId.solutionCounter,
        slot: ActionSlot.primary,
        enabled: false,
        count: state.solutionIdx + 1,
        total: total,
      ),
      GameAction(GameActionId.nextSolution, slot: ActionSlot.primary, enabled: total > 1),
      const GameAction(GameActionId.closeSolutions, slot: ActionSlot.primary),
    ];
  }

  final undo = GameAction(GameActionId.undo, slot: ActionSlot.primary, enabled: state.isUndoEnabled);
  final redo = GameAction(GameActionId.redo, slot: ActionSlot.primary, enabled: state.isRedoEnabled);

  if (state.selectedPiece != null) {
    return [
      history,
      GameAction(GameActionId.rotate, slot: ActionSlot.primary, enabled: !state.isSolving),
      undo,
      redo,
      GameAction(GameActionId.flip, slot: ActionSlot.primary, enabled: !state.isSolving),
    ];
  }

  final solutionsCount = state.applicableSolutions.length;
  final showsSolvability = indicator != SolutionIndicator.none;
  final isAssistDisabled = state.isSolving || (showsSolvability && solutionsCount == 0);
  final assistGate = solutionsCount == 0
      ? AssistGate.noSolutions
      : showsSolvability
      ? AssistGate.open
      : AssistGate.confirmEasy;

  return [
    history,
    GameAction(
      GameActionId.hint,
      slot: ActionSlot.primary,
      enabled: !isAssistDisabled && !state.isSolved,
      assistGate: assistGate,
    ),
    undo,
    redo,
    GameAction(
      GameActionId.showSolutions,
      slot: ActionSlot.overflow,
      enabled: !isAssistDisabled,
      assistGate: assistGate,
      count: indicator == SolutionIndicator.countSolutions ? solutionsCount : null,
    ),
    const GameAction(GameActionId.howToPlay, slot: ActionSlot.overflow),
    GameAction(GameActionId.restart, slot: ActionSlot.overflow, enabled: !state.isSolving, busy: state.isSolving),
  ];
}
