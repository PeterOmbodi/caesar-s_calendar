class TimerService {
  Stream<int> elapsedSeconds({required final int start, required final bool running}) async* {
    if (!running || start == 0) return;
    int calc() => ((DateTime.now().millisecondsSinceEpoch - start) / 1000).ceil();
    yield calc();
    yield* Stream<int>.periodic(const Duration(seconds: 1), (_) => calc()).distinct();
  }

  Stream<int> minutes({required final int start, required final bool running}) =>
      elapsedSeconds(start: start, running: running).map((final s) => s ~/ 60).distinct();

  Stream<int> seconds({required final int start, required final bool running}) =>
      elapsedSeconds(start: start, running: running).map((final s) => s % 60).distinct();
}
