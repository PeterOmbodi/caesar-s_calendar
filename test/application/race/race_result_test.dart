import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_result.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:flutter_test/flutter_test.dart';

const _startAt = 1000000;

RacePlayer _player(
  final String uid, {
  final int? durationMs,
  final bool gaveUp = false,
  final bool online = true,
  final int? lastSeen,
}) => RacePlayer(
  uid: uid,
  nickname: uid,
  colorIndex: 0,
  joinedAt: 0,
  online: online,
  lastSeen: lastSeen,
  ready: true,
  nonce: 1,
  durationMs: durationMs,
  gaveUp: gaveUp,
);

List<(String, RaceOutcome, int?, int?)> _result(final List<RacePlayer> players, {final int nowMs = _startAt}) => [
  for (final s in RaceResult.of(
    RaceRoom(
      code: 'K7M4P',
      hostUid: 'a',
      status: RaceRoomStatus.playing,
      maxPlayers: 2,
      graceSec: 60,
      hints: 0,
      round: 1,
      players: players,
      startAt: _startAt,
    ),
    nowMs: nowMs,
  ))
    (s.player.uid, s.outcome, s.place, s.gapMs),
];

void main() {
  test('the faster finisher wins, the other is behind by the difference', () {
    expect(_result([_player('a', durationMs: 95300), _player('b', durationMs: 61100)]), [
      ('b', RaceOutcome.finished, 1, 0),
      ('a', RaceOutcome.finished, 2, 34200),
    ]);
  });

  test('equal times share the first place', () {
    expect(_result([_player('a', durationMs: 60000), _player('b', durationMs: 60000)]), [
      ('a', RaceOutcome.finished, 1, 0),
      ('b', RaceOutcome.finished, 1, 0),
    ]);
  });

  test('the first finisher wins at once, the others are still racing', () {
    expect(_result([_player('a'), _player('b', durationMs: 61100)], nowMs: _startAt + 62000), [
      ('b', RaceOutcome.finished, 1, 0),
      ('a', RaceOutcome.racing, null, null),
    ]);
  });

  test('a finisher wins over one who did not finish in time', () {
    expect(_result([_player('a'), _player('b', durationMs: 61100)], nowMs: _startAt + 61100 + 60000), [
      ('b', RaceOutcome.finished, 1, 0),
      ('a', RaceOutcome.notFinished, null, null),
    ]);
  });

  test("the opponent's giving up wins the race without a solve", () {
    expect(_result([_player('a'), _player('b', gaveUp: true)]), [
      ('a', RaceOutcome.notFinished, 1, null),
      ('b', RaceOutcome.gaveUp, null, null),
    ]);
  });

  test('an opponent offline for too long is out', () {
    final players = [_player('a'), _player('b', online: false, lastSeen: _startAt)];
    expect(_result(players, nowMs: _startAt + 30000), [
      ('a', RaceOutcome.notFinished, 1, null),
      ('b', RaceOutcome.out, null, null),
    ]);
  });

  group('judged when the race ended', () {
    const limit = _startAt + 10 * 60 * 1000;

    test('leaving after the time limit makes nobody a winner', () {
      final players = [_player('a'), _player('b', online: false, lastSeen: limit + 5000)];
      expect(_result(players, nowMs: limit + 60000), [
        ('a', RaceOutcome.notFinished, null, null),
        ('b', RaceOutcome.notFinished, null, null),
      ]);
    });

    test("the loser's coming back does not take away the win", () {
      final players = [
        RacePlayer(
          uid: 'a',
          nickname: 'a',
          colorIndex: 0,
          joinedAt: 0,
          lastSeen: _startAt + 10000,
          outAt: _startAt + 40000,
        ),
        _player('b', online: false, lastSeen: _startAt + 100000),
      ];
      expect(_result(players, nowMs: _startAt + 200000), [
        ('b', RaceOutcome.notFinished, 1, null),
        ('a', RaceOutcome.out, null, null),
      ]);
    });

    test('giving up after the opponent dropped out is too late to lose', () {
      final players = [
        RacePlayer(uid: 'a', nickname: 'a', colorIndex: 0, joinedAt: 0, gaveUp: true, gaveUpAt: _startAt + 300000),
        _player('b', online: false, lastSeen: _startAt + 100000),
      ];
      expect(_result(players, nowMs: _startAt + 400000), [
        ('a', RaceOutcome.notFinished, 1, null),
        ('b', RaceOutcome.out, null, null),
      ]);
    });

    test('the one left in the race keeps the win after leaving too', () {
      final players = [
        _player('a', online: false, lastSeen: _startAt + 100000),
        _player('b', online: false, lastSeen: _startAt + 10000),
      ];
      expect(_result(players, nowMs: _startAt + 200000), [
        ('a', RaceOutcome.notFinished, 1, null),
        ('b', RaceOutcome.out, null, null),
      ]);
    });
  });
}
