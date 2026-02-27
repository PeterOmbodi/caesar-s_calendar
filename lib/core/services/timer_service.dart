import 'package:injectable/injectable.dart';

@lazySingleton
class TimerService {
  int totalElapsedSeconds({
    required final int? startedAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isPaused,
    final bool roundUp = false,
  }) {
    if (startedAt == null) {
      return 0;
    }

    final elapsedMs = _elapsedMs(
      startedAt: startedAt,
      lastResumedAt: lastResumedAt,
      activeElapsedMs: activeElapsedMs,
      isPaused: isPaused,
    );
    final seconds = elapsedMs / 1000;
    return roundUp ? seconds.ceil() : seconds.floor();
  }

  Stream<int> elapsedSeconds({
    required final int? startedAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isPaused,
  }) async* {
    if (startedAt == null) return;

    int calc() => totalElapsedSeconds(
      startedAt: startedAt,
      lastResumedAt: lastResumedAt,
      activeElapsedMs: activeElapsedMs,
      isPaused: isPaused,
    );

    yield calc();

    yield* Stream<int>.periodic(const Duration(seconds: 1), (_) => calc()).distinct();
  }

  Stream<int> minutes({
    required final int? startedAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isPaused,
  }) => elapsedSeconds(
    startedAt: startedAt,
    lastResumedAt: lastResumedAt,
    activeElapsedMs: activeElapsedMs,
    isPaused: isPaused,
  ).map((final s) => s ~/ 60).distinct();

  Stream<int> seconds({
    required final int? startedAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isPaused,
  }) => elapsedSeconds(
    startedAt: startedAt,
    lastResumedAt: lastResumedAt,
    activeElapsedMs: activeElapsedMs,
    isPaused: isPaused,
  ).map((final s) => s % 60).distinct();

  int _elapsedMs({
    required final int startedAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isPaused,
  }) {
    if (isPaused) {
      return activeElapsedMs;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final resumeBase = lastResumedAt ?? (activeElapsedMs == 0 ? startedAt : null);
    if (resumeBase == null) {
      return activeElapsedMs;
    }
    return activeElapsedMs + (nowMs - resumeBase);
  }
}
