import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/actions_for.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/layout_edit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _easy = SolutionIndicator.countSolutions;
const _medium = SolutionIndicator.solvability;
const _hard = SolutionIndicator.none;

Move _move() => HintMove(
  'piece',
  from: MovePlacement(position: const Position.zero()),
  to: MovePlacement(position: const Position.zero()),
  rotationFrom: 0,
  rotationTo: 0,
  flippedFrom: false,
  flippedTo: false,
);

final _square = PuzzlePieceUI.fromType(PieceType.square, Offset.zero, const Offset(5, 5), 10);

PuzzleState _state({
  final GameStatus status = GameStatus.playing,
  final int solutions = 50,
  final int moves = 0,
  final int moveIndex = 0,
  final int solutionIdx = -1,
  final bool selected = false,
}) => PuzzleState.initial().copyWith(
  status: status,
  pieces: [_square],
  selectedPieceId: selected ? _square.id : null,
  applicableSolutions: List.generate(solutions, (_) => <String, PlacementParams>{}),
  moveHistory: List.generate(moves, (_) => _move()),
  moveIndex: moveIndex,
  solutionIdx: solutionIdx,
);

List<GameActionId> _ids(final List<GameAction> actions, final ActionSlot slot) =>
    actions.where((final a) => a.slot == slot).map((final a) => a.id).toList();

GameAction _action(final List<GameAction> actions, final GameActionId id) => actions.singleWhere((final a) => a.id == id);

void main() {
  group('modes', () {
    test('play: History · Hint · Undo · Redo, the rest in More', () {
      final actions = actionsFor(_state(), _easy);
      expect(_ids(actions, ActionSlot.primary), [
        GameActionId.history,
        GameActionId.hint,
        GameActionId.undo,
        GameActionId.redo,
      ]);
      expect(_ids(actions, ActionSlot.overflow), [
        GameActionId.showSolutions,
        GameActionId.howToPlay,
        GameActionId.restart,
      ]);
    });

    test('selection: History · Rotate · Undo · Redo · Flip, nothing in More', () {
      final actions = actionsFor(_state(selected: true), _easy);
      expect(_ids(actions, ActionSlot.primary), [
        GameActionId.history,
        GameActionId.rotate,
        GameActionId.undo,
        GameActionId.redo,
        GameActionId.flip,
      ]);
      expect(_ids(actions, ActionSlot.overflow), isEmpty);
    });

    test('solutions: History · ‹ · n / N · › · Close', () {
      final actions = actionsFor(_state(status: GameStatus.showingSolution, solutionIdx: 4), _easy);
      expect(_ids(actions, ActionSlot.primary), [
        GameActionId.history,
        GameActionId.prevSolution,
        GameActionId.solutionCounter,
        GameActionId.nextSolution,
        GameActionId.closeSolutions,
      ]);
      final counter = _action(actions, GameActionId.solutionCounter);
      expect((counter.count, counter.total), (5, 50));
      expect(_ids(actions, ActionSlot.overflow), isEmpty);
    });

    test('solutions with a single solution disable paging', () {
      final actions = actionsFor(_state(status: GameStatus.showingSolution, solutions: 1, solutionIdx: 0), _easy);
      expect(_action(actions, GameActionId.prevSolution).enabled, isFalse);
      expect(_action(actions, GameActionId.nextSolution).enabled, isFalse);
    });
  });

  group('assist actions per level', () {
    for (final (name, indicator, gate) in [
      ('Easy', _easy, AssistGate.open),
      ('Medium', _medium, AssistGate.open),
      ('Hard', _hard, AssistGate.confirmEasy),
    ]) {
      test('$name, solvable', () {
        final actions = actionsFor(_state(), indicator);
        for (final id in [GameActionId.showSolutions, GameActionId.hint]) {
          expect(_action(actions, id).enabled, isTrue, reason: '$id');
          expect(_action(actions, id).assistGate, gate, reason: '$id');
        }
      });
    }

    for (final (name, indicator) in [('Easy', _easy), ('Medium', _medium)]) {
      test('$name, dead end disables hint and all solutions', () {
        final actions = actionsFor(_state(solutions: 0), indicator);
        expect(_action(actions, GameActionId.showSolutions).enabled, isFalse);
        expect(_action(actions, GameActionId.hint).enabled, isFalse);
      });
    }

    test('Hard, dead end keeps assist enabled and reports no solutions', () {
      final actions = actionsFor(_state(solutions: 0), _hard);
      for (final id in [GameActionId.showSolutions, GameActionId.hint]) {
        expect(_action(actions, id).enabled, isTrue, reason: '$id');
        expect(_action(actions, id).assistGate, AssistGate.noSolutions, reason: '$id');
      }
    });

    test('solved puzzle disables hint only', () {
      final actions = actionsFor(_state(status: GameStatus.solvedByUser), _easy);
      expect(_action(actions, GameActionId.hint).enabled, isFalse);
      expect(_action(actions, GameActionId.showSolutions).enabled, isTrue);
    });

    test('all solutions shows the count on Easy only', () {
      expect(_action(actionsFor(_state(), _easy), GameActionId.showSolutions).count, 50);
      expect(_action(actionsFor(_state(), _medium), GameActionId.showSolutions).count, isNull);
      expect(_action(actionsFor(_state(), _hard), GameActionId.showSolutions).count, isNull);
    });
  });

  group('solving', () {
    for (final indicator in SolutionIndicator.values) {
      test('$indicator: assist, undo and restart are blocked', () {
        final actions = actionsFor(_state(status: GameStatus.searchingSolutions, moves: 2, moveIndex: 1), indicator);
        expect(_action(actions, GameActionId.showSolutions).enabled, isFalse);
        expect(_action(actions, GameActionId.hint).enabled, isFalse);
        expect(_action(actions, GameActionId.undo).enabled, isFalse);
        expect(_action(actions, GameActionId.redo).enabled, isFalse);
        expect(_action(actions, GameActionId.restart).busy, isTrue);
        expect(_action(actions, GameActionId.restart).enabled, isFalse);
      });
    }
  });

  group('undo and redo', () {
    test('follow the move history in play and selection modes', () {
      for (final selected in [false, true]) {
        var actions = actionsFor(_state(selected: selected), _easy);
        expect(_action(actions, GameActionId.undo).enabled, isFalse);
        expect(_action(actions, GameActionId.redo).enabled, isFalse);

        actions = actionsFor(_state(moves: 2, moveIndex: 1, selected: selected), _easy);
        expect(_action(actions, GameActionId.undo).enabled, isTrue);
        expect(_action(actions, GameActionId.redo).enabled, isTrue);
      }
    });
  });

  group('layout edit', () {
    PuzzleState editing({final bool selected = false}) =>
        _state(selected: selected).copyWith(layoutEdit: const LayoutEdit(start: []));

    test('Cancel · Rotate · Reset · Flip · Save on every level, nothing in More', () {
      for (final level in [_easy, _medium, _hard]) {
        final actions = actionsFor(editing(), level);
        expect(_ids(actions, ActionSlot.primary), [
          GameActionId.cancelEdit,
          GameActionId.rotate,
          GameActionId.resetLayout,
          GameActionId.flip,
          GameActionId.saveLayout,
        ]);
        expect(_ids(actions, ActionSlot.overflow), isEmpty);
      }
    });

    test('rotate and flip need a selected block', () {
      expect(_action(actionsFor(editing(), _easy), GameActionId.rotate).enabled, isFalse);
      expect(_action(actionsFor(editing(selected: true), _easy), GameActionId.flip).enabled, isTrue);
    });

    test('Reset and Save wait for a change', () {
      final actions = actionsFor(editing(), _easy);
      expect(_action(actions, GameActionId.resetLayout).enabled, isFalse);
      expect(_action(actions, GameActionId.saveLayout).enabled, isFalse);
    });
  });
}
