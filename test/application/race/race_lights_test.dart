import 'package:caesar_puzzle/application/race/race_lights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const startAt = 100000;
  const pause = 1500;

  int lit(final int now) => RaceLights.lit(nowMs: now, startAtMs: startAt, pauseMs: pause);

  test('one more light every second, all five before the pause', () {
    expect(lit(startAt - pause - 4001), 0);
    expect(lit(startAt - pause - 4000), 1);
    expect(lit(startAt - pause - 3001), 1);
    expect(lit(startAt - pause - 3000), 2);
    expect(lit(startAt - pause - 1000), 4);
    expect(lit(startAt - pause), 5);
    expect(lit(startAt - 1), 5);
  });

  test('all lights are off from the start on', () {
    expect(lit(startAt), 0);
    expect(lit(startAt + 60000), 0);
  });

  test('the pause is the same for a seed and stays in range', () {
    expect(RaceLights.pauseMs(433851801), RaceLights.pauseMs(433851801));
    final pauses = {for (var seed = 0; seed < 2000; seed++) RaceLights.pauseMs(seed * 7919)};
    expect(pauses.every((final p) => p >= RaceLights.minPauseMs && p <= RaceLights.maxPauseMs), isTrue);
    expect(pauses.length, greaterThan(500));
  });
}
