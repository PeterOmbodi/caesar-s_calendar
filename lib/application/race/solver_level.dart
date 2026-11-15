import 'dart:math';

/// How the solver opponent searches and how fast its search is played back.
enum SolverLevel {
  novice(
    mostConstrainedFirst: false,
    skipDeadEnds: false,
    msPerStep: 20,
    minTime: Duration(minutes: 4),
    maxTime: Duration(minutes: 6),
  ),
  confident(
    mostConstrainedFirst: false,
    skipDeadEnds: true,
    msPerStep: 300,
    minTime: Duration(minutes: 2),
    maxTime: Duration(minutes: 3),
  ),
  master(
    mostConstrainedFirst: true,
    skipDeadEnds: true,
    msPerStep: 3000,
    minTime: Duration(seconds: 60),
    maxTime: Duration(seconds: 90),
  );

  const SolverLevel({
    required this.mostConstrainedFirst,
    required this.skipDeadEnds,
    required this.msPerStep,
    required this.minTime,
    required this.maxTime,
  });

  final bool mostConstrainedFirst;
  final bool skipDeadEnds;

  // To be tuned with tool/race_solver/count_solver_steps_test.dart.
  final int msPerStep;
  final Duration minTime;
  final Duration maxTime;

  Duration timeFor(final int steps) => Duration(
    milliseconds: min(max(steps * msPerStep, minTime.inMilliseconds), maxTime.inMilliseconds),
  );
}
