import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_haptics.dart';
import 'package:flutter_test/flutter_test.dart';

Move _move(final PlaceZone to) =>
    MovePiece('P', from: MovePlacement(position: const Position.zero()), to: MovePlacement(zone: to, position: const Position.zero()));

PuzzleState _after(final PuzzleState state, final Move move) =>
    state.copyWith(moveHistory: [...state.moveHistory, move], moveIndex: state.moveIndex + 1);

void main() {
  final start = PuzzleState.initial().copyWith(status: GameStatus.playing);

  test('placing on the board, turning and solving give feedback', () {
    expect(hapticFor(start, _after(start, _move(PlaceZone.grid))), PuzzleHaptic.piecePlaced);
    expect(hapticFor(start, _after(start, RotatePiece('P', null, rotation: 1))), PuzzleHaptic.pieceTurned);
    expect(hapticFor(start, _after(start, FlipPiece('P', null, isFlipped: true))), PuzzleHaptic.pieceTurned);
    expect(hapticFor(start, start.copyWith(status: GameStatus.solvedByUser)), PuzzleHaptic.solved);
  });

  test('a move back to the tray, undo and redo give none', () {
    final placed = _after(start, _move(PlaceZone.grid));
    expect(hapticFor(start, _after(start, _move(PlaceZone.board))), isNull);
    expect(hapticFor(placed, placed.copyWith(moveIndex: 0)), isNull);
    final undone = placed.copyWith(moveIndex: 0);
    expect(hapticFor(undone, undone.copyWith(moveIndex: 1)), isNull);
  });

  test('a new move after undo gives feedback', () {
    final undone = _after(start, _move(PlaceZone.board)).copyWith(moveIndex: 0);
    final replaced = undone.copyWith(moveHistory: [_move(PlaceZone.grid)], moveIndex: 1);
    expect(hapticFor(undone, replaced), PuzzleHaptic.piecePlaced);
  });

  test('a restored solved session gives none', () {
    expect(
      hapticFor(start, start.copyWith(status: GameStatus.solvedByUser, isRestoredSolvedSession: true)),
      isNull,
    );
  });
}
