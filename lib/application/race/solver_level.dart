import 'dart:math';

/// The solver's place in a room, whatever plays it back.
const String solverPlayerUid = 'solver';

/// How the solver opponent searches and how fast its search is played back.
enum SolverLevel {
  novice(
    mostConstrainedFirst: false,
    skipDeadEnds: false,
    fewSteps: 142,
    manySteps: 5772,
    minTime: Duration(minutes: 4),
    maxTime: Duration(minutes: 6),
  ),
  confident(
    mostConstrainedFirst: false,
    skipDeadEnds: true,
    fewSteps: 64,
    manySteps: 2384,
    minTime: Duration(minutes: 2),
    maxTime: Duration(minutes: 3),
  ),
  master(
    mostConstrainedFirst: true,
    skipDeadEnds: true,
    fewSteps: 30,
    manySteps: 886,
    minTime: Duration(seconds: 60),
    maxTime: Duration(seconds: 90),
  );

  const SolverLevel({
    required this.mostConstrainedFirst,
    required this.skipDeadEnds,
    required this.fewSteps,
    required this.manySteps,
    required this.minTime,
    required this.maxTime,
  });

  final bool mostConstrainedFirst;
  final bool skipDeadEnds;

  // p10 and p90 of the level's moves over all dates, from tool/race_solver/count_solver_steps_test.dart.
  final int fewSteps;
  final int manySteps;
  final Duration minTime;
  final Duration maxTime;

  /// Moves vary a hundredfold between dates, so the time follows their logarithm: [fewSteps] or fewer take
  /// [minTime], [manySteps] or more take [maxTime].
  Duration timeFor(final int steps) {
    final share = steps <= fewSteps
        ? 0.0
        : steps >= manySteps
        ? 1.0
        : log(steps / fewSteps) / log(manySteps / fewSteps);
    final range = maxTime.inMilliseconds - minTime.inMilliseconds;
    return Duration(milliseconds: minTime.inMilliseconds + (range * share).round());
  }
}
