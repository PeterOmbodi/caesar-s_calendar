class TimerService {
  Stream<int> elapsedSeconds({
    required final int? startedAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isPaused,
  }) async* {
    if (startedAt == null) return;

    int calc() {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (isPaused) {
        return (activeElapsedMs / 1000).floor();
      }
      final resumeBase = lastResumedAt ?? startedAt;
      final currentActiveMs = activeElapsedMs + (nowMs - resumeBase);
      return (currentActiveMs / 1000).floor();
    }

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
}
