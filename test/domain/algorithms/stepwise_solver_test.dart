import 'dart:math';

import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_placement.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';
import 'package:caesar_puzzle/domain/algorithms/stepwise_solver.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_pieces.dart';
import 'package:flutter_test/flutter_test.dart';

StepwiseSolver _solver(final DateTime date, final SolverLevel level) => StepwiseSolver(
  PuzzleSolver(grid: solverGrid, pieces: standardSolverPieces(), date: date),
  mostConstrainedFirst: level.mostConstrainedFirst,
  skipDeadEnds: level.skipDeadEnds,
);

/// Plays the steps back and fails on a piece put on another or taken back without being there.
Map<String, SolverPlacement> _replay(final Iterable<SolverStep> steps) {
  final board = <String, SolverPlacement>{};
  final covered = <Cell>{};
  for (final step in steps) {
    switch (step) {
      case PlaceStep(:final placement):
        expect(board.containsKey(placement.piece.id), isFalse, reason: '${placement.piece.id} put down twice');
        for (final cell in placement.coveredCells) {
          expect(covered.add(cell), isTrue, reason: '${placement.id} overlaps');
        }
        board[placement.piece.id] = placement;
      case RemoveStep(:final pieceId):
        final placement = board.remove(pieceId);
        expect(placement, isNotNull, reason: '$pieceId taken back without being there');
        covered.removeAll(placement!.coveredCells);
    }
  }
  return board;
}

void main() {
  final dates = [DateTime(2024, 10, 8), DateTime(2024), DateTime(2024, 2, 29), DateTime(2024, 12, 31)];

  for (final level in SolverLevel.values) {
    test('${level.name}: valid moves that end in a solution', () {
      for (final date in dates) {
        final solver = _solver(date, level);
        final board = _replay(solver.steps());
        expect(solver.isSolved, isTrue, reason: '$date');
        expect(board, hasLength(8), reason: '$date');
        final puzzle = PuzzleSolver(grid: solverGrid, pieces: standardSolverPieces(), date: date);
        final covered = {for (final p in board.values) ...p.coveredCells};
        expect(covered.intersection(puzzle.buildDateCells()), isEmpty, reason: '$date');
        expect(covered.intersection(puzzle.forbiddenCells), isEmpty, reason: '$date');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }

  test('the same date gives the same moves', () {
    String moves(final StepwiseSolver solver) => [
      for (final step in solver.steps())
        switch (step) {
          PlaceStep(:final placement) => '+${placement.id}',
          RemoveStep(:final pieceId) => '-$pieceId',
        },
    ].join(' ');
    final date = DateTime(2024, 10, 8);
    expect(moves(_solver(date, SolverLevel.confident)), moves(_solver(date, SolverLevel.confident)));
  });

  test('a stronger level needs fewer moves', () {
    final date = DateTime(2024, 10, 8);
    int count(final SolverLevel level) => _solver(date, level).steps().length;
    final novice = count(SolverLevel.novice);
    final confident = count(SolverLevel.confident);
    final master = count(SolverLevel.master);
    expect(novice, greaterThanOrEqualTo(confident));
    expect(confident, greaterThan(master));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('the time grows with the number of moves and stays within the level range', () {
    for (final level in SolverLevel.values) {
      expect(level.timeFor(1), level.minTime, reason: level.name);
      expect(level.timeFor(level.fewSteps), level.minTime, reason: level.name);
      expect(level.timeFor(level.manySteps), level.maxTime, reason: level.name);
      expect(level.timeFor(1 << 30), level.maxTime, reason: level.name);
      final middle = level.timeFor(sqrt(level.fewSteps * level.manySteps).round());
      expect(middle, greaterThan(level.minTime), reason: level.name);
      expect(middle, lessThan(level.maxTime), reason: level.name);
    }
  });
}
