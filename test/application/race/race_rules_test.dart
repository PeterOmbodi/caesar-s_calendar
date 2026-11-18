import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
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

  test('the time to finish does not go past the time limit', () {
    final room = _room([_player('a', durationMs: 595000), _player('b')], firstFinishAt: _startAt + 595000);
    expect(RaceRules.graceEndsAtMs(room), _startAt + 655000);
    expect(RaceRules.endsAtMs(room), _startAt + 600000);
  });

  test('the first finisher is the fastest one', () {
    expect(RaceRules.firstFinisher(_room([_player('a'), _player('b')])), isNull);
    final room = _room([_player('a', durationMs: 90000), _player('b', durationMs: 85000), _player('c')]);
    expect(RaceRules.firstFinisher(room)?.uid, 'b');
  });

  test('another device is one that wrote a different id; without an id nobody can tell', () {
    const player = RacePlayer(uid: 'a', nickname: 'a', colorIndex: 0, joinedAt: 0, device: 'phone');
    expect(RaceRules.isOnOtherDevice(player, deviceId: 'phone'), isFalse);
    expect(RaceRules.isOnOtherDevice(player, deviceId: 'tablet'), isTrue);
    expect(RaceRules.isOnOtherDevice(_player('a'), deviceId: 'tablet'), isFalse);
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
    expect(RaceRules.standings(players, nowMs: _startAt).map((final p) => p.uid), ['e', 'c', 'b', 'd', 'a']);
  });

  group('connection', () {
    final offline = _player('b', online: false, lastSeen: _startAt + 10000);

    test('an offline player is out after the time to come back', () {
      expect(RaceRules.isOut(offline, nowMs: _startAt + 39999), isFalse);
      expect(RaceRules.isOut(offline, nowMs: _startAt + 40000), isTrue);
    });

    test('an opponent who stays offline loses the race', () {
      final room = _room([_player('a'), offline]);
      expect(RaceRules.isOver(room, nowMs: _startAt + 39999), isFalse);
      expect(RaceRules.isOver(room, nowMs: _startAt + 40000), isTrue);
    });

    test('a finisher is never out', () {
      expect(RaceRules.isOut(_player('b', durationMs: 5000, online: false, lastSeen: 0), nowMs: _startAt), isFalse);
    });

    test('the next deadline is the earliest of the time to come back and the end of the race', () {
      expect(RaceRules.nextDeadlineMs(_room([_player('a'), offline]), nowMs: _startAt + 20000), _startAt + 40000);
      expect(RaceRules.nextDeadlineMs(_room([_player('a'), _player('b')]), nowMs: _startAt), _startAt + 600000);
    });

    test('a player out of the race comes after those still racing', () {
      final players = [offline, _player('a')];
      expect(RaceRules.standings(players, nowMs: _startAt + 40000).map((final p) => p.uid), ['a', 'b']);
    });
  });

  group('board of the round', () {
    RacePlayer withBoard(final RaceBoard? board) =>
        RacePlayer(uid: 'a', nickname: 'a', colorIndex: 0, joinedAt: 0, board: board);

    test('a board written before this round started is left out', () {
      final stale = RaceBoard(const [], publishedAtMs: _startAt - 1);
      expect(RaceRules.boardOf(withBoard(stale), startAtMs: _startAt), isNull);
    });

    test('a board written in this round is kept', () {
      final board = RaceBoard(const [], publishedAtMs: _startAt + 5000);
      expect(RaceRules.boardOf(withBoard(board), startAtMs: _startAt), same(board));
    });

    test('a board that has not been through the database is kept', () {
      final board = RaceBoard(const []);
      expect(RaceRules.boardOf(withBoard(board), startAtMs: _startAt), same(board));
    });
  });

  group('went out during the race', () {
    const limit = _startAt + 10 * 60 * 1000;

    test('away mid-race for longer than the time to come back', () {
      final away = _player('b', online: false, lastSeen: _startAt + 10000);
      expect(RaceRules.wentOutDuringRace(_room([_player('a'), away]), away, nowMs: _startAt + 60000), isTrue);
    });

    test('left after the time limit and came back later', () {
      final away = _player('b', online: false, lastSeen: limit + 5000);
      expect(RaceRules.wentOutDuringRace(_room([_player('a'), away]), away, nowMs: limit + 60000), isFalse);
    });

    test('left during the time to finish and stayed away past it', () {
      final away = _player('b', online: false, lastSeen: _startAt + 70000);
      final room = _room([_player('a', durationMs: 60000), away], firstFinishAt: _startAt + 60000);
      expect(RaceRules.wentOutDuringRace(room, away, nowMs: _startAt + 200000), isTrue);
    });
  });

  group('moments of leaving the race', () {
    test('out from the stored moment, online or not', () {
      final back = RacePlayer(uid: 'a', nickname: 'a', colorIndex: 0, joinedAt: 0, outAt: _startAt + 40000);
      expect(RaceRules.isOut(back, nowMs: _startAt + 39999), isFalse);
      expect(RaceRules.isOut(back, nowMs: _startAt + 40000), isTrue);
    });

    test('a give-up counts from its time, one without a time always', () {
      final timed = RacePlayer(
        uid: 'a',
        nickname: 'a',
        colorIndex: 0,
        joinedAt: 0,
        gaveUp: true,
        gaveUpAt: _startAt + 5000,
      );
      expect(RaceRules.hasGivenUp(timed, nowMs: _startAt + 4999), isFalse);
      expect(RaceRules.hasGivenUp(timed, nowMs: _startAt + 5000), isTrue);
      expect(RaceRules.hasGivenUp(_player('a', gaveUp: true), nowMs: _startAt), isTrue);
    });
  });
}
