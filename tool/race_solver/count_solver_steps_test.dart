// Counts the solver's moves for every date and level, to tune SolverLevel.msPerStep.
// Run: fvm flutter test tool/race_solver/count_solver_steps_test.dart
// ignore_for_file: avoid_print

import 'package:caesar_puzzle/application/race/race_puzzle.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';
import 'package:caesar_puzzle/domain/algorithms/stepwise_solver.dart';
import 'package:caesar_puzzle/infrastructure/race/solver_race_repository.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_pieces.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('count solver moves for every date', () {
    final pieces = standardSolverPieces();
    for (final level in SolverLevel.values) {
      final watch = Stopwatch()..start();
      final counts = <int>[];
      var unsolved = 0;
      for (
        var date = DateTime(RacePuzzle.year);
        date.year == RacePuzzle.year;
        date = date.add(const Duration(days: 1))
      ) {
        final solver = StepwiseSolver(
          PuzzleSolver(grid: solverGrid, pieces: pieces, date: date),
          mostConstrainedFirst: level.mostConstrainedFirst,
          skipDeadEnds: level.skipDeadEnds,
        );
        counts.add(solver.steps().take(SolverRaceRepository.maxSteps).length);
        if (!solver.isSolved) {
          unsolved++;
        }
      }
      counts.sort();
      int percentile(final int p) => counts[((counts.length - 1) * p / 100).round()];
      final target = (level.minTime.inMilliseconds + level.maxTime.inMilliseconds) / 2;
      print(
        '${level.name}: min ${counts.first}, p10 ${percentile(10)}, median ${percentile(50)}, '
        'p90 ${percentile(90)}, max ${counts.last}, unsolved $unsolved, '
        'msPerStep for the median at mid range ≈ ${(target / percentile(50)).round()}, '
        'search ${watch.elapsedMilliseconds} ms for 366 dates',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
