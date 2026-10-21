import 'dart:async';

/// Emits [combine] of the latest values of [a] and [b] once both have emitted.
Stream<R> combineLatest2<A, B, R>(
  final Stream<A> a,
  final Stream<B> b,
  final R Function(A a, B b) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  late A lastA;
  late B lastB;
  var hasA = false;
  var hasB = false;
  var done = 0;

  void emit() {
    if (hasA && hasB) {
      controller.add(combine(lastA, lastB));
    }
  }

  void onDone() {
    if (++done == 2) {
      controller.close();
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen(
        (final value) {
          lastA = value;
          hasA = true;
          emit();
        },
        onError: controller.addError,
        onDone: onDone,
      );
      subB = b.listen(
        (final value) {
          lastB = value;
          hasB = true;
          emit();
        },
        onError: controller.addError,
        onDone: onDone,
      );
    },
    onPause: () {
      subA?.pause();
      subB?.pause();
    },
    onResume: () {
      subA?.resume();
      subB?.resume();
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}
