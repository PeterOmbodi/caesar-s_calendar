import 'package:caesar_puzzle/application/race/race_rng.dart';

abstract final class RaceLights {
  static const int count = 5;
  static const int stepMs = 1000;
  static const int minPauseMs = 500;
  static const int maxPauseMs = 2500;

  /// The pause nobody can predict, the same for every client of the room.
  static int pauseMs(final int seed) => minPauseMs + RaceRng(seed ^ 0x5F3759DF).nextInt(maxPauseMs - minPauseMs + 1);

  static int lit({required final int nowMs, required final int startAtMs, required final int pauseMs}) {
    if (nowMs >= startAtMs) {
      return 0;
    }
    final allOnAt = startAtMs - pauseMs;
    final firstAt = allOnAt - (count - 1) * stepMs;
    if (nowMs < firstAt) {
      return 0;
    }
    return ((nowMs - firstAt) ~/ stepMs + 1).clamp(0, count);
  }
}
