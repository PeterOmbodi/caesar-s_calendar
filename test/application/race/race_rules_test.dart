import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _startAt = 1000000;

RacePlayer _player(final String uid, {final int? durationMs, final bool gaveUp = false}) => RacePlayer(
  uid: uid,
  nickname: uid,
  colorIndex: 0,
  joinedAt: 0,
  ready: true,
  nonce: 1,
  durationMs: durationMs,
  gaveUp: gaveUp,
);

RaceRoom _room(final List<RacePlayer> players, {final int? firstFinishAt}) => RaceRoom(
  code: 'K7M4P',
  hostUid: 'a',
  status: RaceRoomStatus.playing,
  maxPlayers: 2,
  graceSec: 60,
  hints: 0,
  round: 1,
  players: players,
  startAt: _startAt,
  firstFinishAt: firstFinishAt,
);

void main() {
  test('before anybody solves, the race ends at the time limit', () {
    final room = _room([_player('a'), _player('b')]);
    expect(RaceRules.graceEndsAtMs(room), isNull);
    expect(RaceRules.endsAtMs(room), _startAt + 600000);
    expect(RaceRules.isOver(room, nowMs: _startAt + 599999), isFalse);
    expect(RaceRules.isOver(room, nowMs: _startAt + 600000), isTrue);
  });

  test('the first solve gives the others the time to finish', () {
    final room = _room([_player('a', durationMs: 90000), _player('b')], firstFinishAt: _startAt + 90500);
    expect(RaceRules.endsAtMs(room), _startAt + 150500);
    expect(RaceRules.isOver(room, nowMs: _startAt + 150499), isFalse);
    expect(RaceRules.isOver(room, nowMs: _startAt + 150500), isTrue);
  });

  test('without firstFinishAt the time to finish counts from the solve', () {
    final room = _room([_player('a', durationMs: 90000), _player('b')]);
    expect(RaceRules.graceEndsAtMs(room), _startAt + 150000);
  });

  test('the time to finish never runs past the time limit', () {
    final room = _room([_player('a', durationMs: 580000), _player('b')]);
    expect(RaceRules.endsAtMs(room), _startAt + 600000);
  });

  test('the race is over once everyone has solved', () {
    final room = _room([_player('a', durationMs: 90000), _player('b', durationMs: 100000)]);
    expect(RaceRules.isOver(room, nowMs: _startAt + 100000), isTrue);
  });

  test("the opponent's giving up ends the race at once", () {
    final room = _room([_player('a'), _player('b', gaveUp: true)]);
    expect(RaceRules.isOver(room, nowMs: _startAt + 1000), isTrue);
  });

  test('a solve and a give-up end the race', () {
    final room = _room([_player('a', durationMs: 90000), _player('b', gaveUp: true)]);
    expect(RaceRules.isOver(room, nowMs: _startAt + 90000), isTrue);
  });

  test('the race goes on while someone is still solving', () {
    final room = _room([_player('a', durationMs: 90000), _player('b')]);
    expect(RaceRules.isOver(room, nowMs: _startAt + 100000), isFalse);
  });

  test('standings: finishers by time, then the others in joining order, those who gave up last', () {
    final players = [
      _player('a', gaveUp: true),
      _player('b'),
      _player('c', durationMs: 120000),
      _player('d'),
      _player('e', durationMs: 90000),
    ];
    expect(RaceRules.standings(players).map((final p) => p.uid), ['e', 'c', 'b', 'd', 'a']);
  });
}
