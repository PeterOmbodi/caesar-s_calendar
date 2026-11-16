import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/infrastructure/race/race_room_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _player({
  final int joinedAt = 1000,
  final int round = 1,
  final bool ready = true,
  final Map<String, Object?> extra = const {},
}) => {
  'nickname': 'Swift Otter 47',
  'colorIndex': 3,
  'joinedAt': joinedAt,
  'online': true,
  'ready': ready,
  'nonce': 12345,
  'round': round,
  ...extra,
};

Map<String, Object?> _room({final Map<String, Object?> extra = const {}, final Map<String, Object?>? players}) => {
  'hostUid': 'host',
  'status': 'lobby',
  'maxPlayers': 2,
  'settings': {'graceSec': 60, 'hints': 0},
  'round': 1,
  'createdAt': 500,
  'players': players ?? {'host': _player()},
  ...extra,
};

void main() {
  test('no room without a host', () {
    expect(RaceRoomMapper.fromValue('K7M4P', null), isNull);
    expect(RaceRoomMapper.fromValue('K7M4P', {'players': <String, Object?>{}}), isNull);
  });

  test('reads a lobby', () {
    final room = RaceRoomMapper.fromValue('K7M4P', _room())!;
    expect(
      (room.code, room.hostUid, room.status, room.maxPlayers, room.graceSec, room.hints, room.round, room.createdAt),
      ('K7M4P', 'host', RaceRoomStatus.lobby, 2, 60, 0, 1, 500),
    );
    expect((room.puzzle, room.startAt, room.firstFinishAt), (null, null, null));
    final host = room.player('host')!;
    expect(
      (host.nickname, host.colorIndex, host.ready, host.nonce, host.placed),
      ('Swift Otter 47', 3, true, 12345, 0),
    );
    expect(room.canStart, isFalse);
  });

  test('reads a running race, with numbers as the web sends them', () {
    final room = RaceRoomMapper.fromValue(
      'K7M4P',
      _room(
        extra: {
          'status': 'playing',
          'puzzle': {'month': 3.0, 'day': 5.0},
          'startAt': 2000.0,
          'firstFinishAt': 9000.0,
        },
        players: {
          'host': _player(
            extra: {
              'placed': 8.0,
              'durationMs': 7000.0,
              'board': {
                'at': 9500,
                'pieces': {
                  'Square': {'row': 2.0, 'col': 3.0, 'rot': 0.0, 'flip': false},
                },
              },
            },
          ),
          'guest': _player(joinedAt: 1500, extra: {'placed': 5, 'online': false, 'lastSeen': 8000, 'gaveUp': true}),
        },
      ),
    )!;
    expect(room.status, RaceRoomStatus.playing);
    expect(room.puzzle, const RaceRoomPuzzle(month: 3, day: 5));
    expect((room.startAt, room.firstFinishAt), (2000, 9000));
    final host = room.player('host')!;
    final guest = room.player('guest')!;
    expect((host.placed, host.durationMs, host.hasFinished), (8, 7000, true));
    expect(host.board, RaceBoard([PlacementParams('Square', 2, 3, 0, false)]));
    expect(room.player('guest')!.board, isNull);
    expect(
      (guest.placed, guest.online, guest.lastSeen, guest.gaveUp, guest.hasFinished),
      (5, false, 8000, true, false),
    );
  });

  test('players come in joining order, the uid breaks a tie', () {
    final room = RaceRoomMapper.fromValue(
      'K7M4P',
      _room(players: {'c': _player(joinedAt: 3000), 'b': _player(joinedAt: 1000), 'a': _player(joinedAt: 1000)}),
    )!;
    expect(room.players.map((final p) => p.uid), ['a', 'b', 'c']);
    expect(room.isFull, isTrue);
  });

  test('fields of an earlier round read as untouched', () {
    final room = RaceRoomMapper.fromValue(
      'K7M4P',
      _room(
        extra: {'round': 2},
        players: {
          'host': _player(round: 2),
          'guest': _player(
            joinedAt: 1500,
            extra: {
              'placed': 8,
              'durationMs': 7000,
              'gaveUp': true,
              'board': {'at': 9500},
            },
          ),
        },
      ),
    )!;
    final guest = room.player('guest')!;
    expect((guest.ready, guest.nonce, guest.placed, guest.durationMs, guest.gaveUp), (false, null, 0, null, false));
    expect(guest.board, isNull);
    expect(room.player('host')!.ready, isTrue);
    expect(room.canStart, isFalse);
  });

  test('two ready players can start', () {
    final room = RaceRoomMapper.fromValue(
      'K7M4P',
      _room(players: {'host': _player(), 'guest': _player(joinedAt: 1500)}),
    )!;
    expect(room.canStart, isTrue);
  });

  test('equal data gives equal rooms', () {
    expect(RaceRoomMapper.fromValue('K7M4P', _room()), RaceRoomMapper.fromValue('K7M4P', _room()));
    expect(
      RaceRoomMapper.fromValue('K7M4P', _room()),
      isNot(RaceRoomMapper.fromValue('K7M4P', _room(players: {'host': _player(ready: false)}))),
    );
  });

  group('board', () {
    final board = RaceBoard([PlacementParams('Z-Shape', 3, -1, 1, true), PlacementParams('L-Shape', 0, 4, 0, false)]);

    Map<String, Object?> stored(final RaceBoard board) => {
      ...RaceRoomMapper.boardToValue(board, publishedAt: 'timestamp'),
      'at': 9000,
    };

    test('goes through the database value unchanged, with the time of the write', () {
      final read = RaceRoomMapper.boardFromValue(stored(board));
      expect(read, board);
      expect(read!.publishedAtMs, 9000);
    });

    test('a board without pieces is still a board', () {
      expect(RaceRoomMapper.boardFromValue({'at': 9000}), RaceBoard(const []));
    });

    test('the web hands numbers over as doubles', () {
      final value = {
        'at': 9000.0,
        'pieces': {
          'Square': {'row': 2.0, 'col': 3.0, 'rot': 0.0, 'flip': false},
        },
      };
      expect(RaceRoomMapper.boardFromValue(value), RaceBoard([PlacementParams('Square', 2, 3, 0, false)]));
    });

    test('a missing or malformed value reads as no board', () {
      expect(RaceRoomMapper.boardFromValue(null), isNull);
      expect(RaceRoomMapper.boardFromValue({'pieces': {}}), isNull);
      expect(
        RaceRoomMapper.boardFromValue({
          'at': 9000,
          'pieces': {
            'Square': {'row': 2},
          },
        }),
        isNull,
      );
    });
  });
}
