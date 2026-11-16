import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_puzzle.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/presentation/pages/race/bloc/race_room_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_race_room_repository.dart';

const _profile = RaceProfile(nickname: 'Swift Otter 47', colorIndex: 3);

RacePlayer _player(final String uid, {final bool ready = false, final int? nonce, final int joinedAt = 1000}) =>
    RacePlayer(uid: uid, nickname: uid, colorIndex: 0, joinedAt: joinedAt, ready: ready, nonce: nonce);

RaceRoom _room({
  final String hostUid = 'me',
  final List<RacePlayer>? players,
  final int round = 1,
  final RaceRoomStatus status = RaceRoomStatus.lobby,
  final RaceRoomPuzzle? puzzle,
  final int? startAt,
}) => RaceRoom(
  code: 'K7M4P',
  hostUid: hostUid,
  status: status,
  maxPlayers: 2,
  graceSec: 60,
  hints: 0,
  round: round,
  players: players ?? [_player('me')],
  puzzle: puzzle,
  startAt: startAt,
);

final _readyPair = [_player('me', ready: true, nonce: 123456789), _player('guest', ready: true, nonce: 987654321)];

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeRaceRoomRepository repository;
  late RaceRoomCubit cubit;

  setUp(() {
    repository = FakeRaceRoomRepository();
    cubit = RaceRoomCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  Future<void> open(final RaceRoom room, {final String? code}) async {
    await cubit.enter(profile: _profile, code: code);
    repository.emit(room);
    await _settle();
  }

  group('entering', () {
    test('creating a room opens it once its data arrives', () async {
      await cubit.enter(profile: _profile);
      expect((cubit.state.phase, cubit.state.code), (RaceRoomPhase.entering, 'K7M4P'));

      repository.emit(_room());
      await _settle();

      expect((cubit.state.phase, cubit.state.room), (RaceRoomPhase.open, _room()));
      expect(repository.calls, ['create Swift Otter 47']);
    });

    test('joining uses the given code', () async {
      await open(
        _room(hostUid: 'host', players: [_player('host'), _player('me', joinedAt: 2000)]),
        code: 'ABCDE',
      );
      expect(repository.calls, ['join ABCDE']);
      expect((cubit.state.phase, cubit.state.code), (RaceRoomPhase.open, 'ABCDE'));
    });

    test('a refused entry fails with its reason', () async {
      repository.nextFailure = RaceRoomFailure.full;
      await cubit.enter(profile: _profile, code: 'ABCDE');
      expect((cubit.state.phase, cubit.state.failure), (RaceRoomPhase.failed, RaceRoomFailure.full));
    });
  });

  group('in the room', () {
    test('updates of the room reach the state', () async {
      await open(_room());
      repository.emit(_room(players: [_player('me'), _player('guest', joinedAt: 2000)]));
      await _settle();
      expect(cubit.state.room!.players, hasLength(2));
    });

    test('the room disappearing closes it', () async {
      await open(_room(hostUid: 'host', players: [_player('host'), _player('me', joinedAt: 2000)]));
      repository.emit(null);
      await _settle();
      expect(cubit.state.phase, RaceRoomPhase.closed);
    });

    test('the host losing the room is told about the connection', () async {
      await open(_room());
      repository.emit(null);
      await _settle();
      expect((cubit.state.phase, cubit.state.failure), (RaceRoomPhase.failed, RaceRoomFailure.offline));
    });

    test('a guest dropped from the room is told about the connection', () async {
      await open(_room(hostUid: 'host', players: [_player('host'), _player('me', joinedAt: 2000)]));
      repository.emit(_room(hostUid: 'host', players: [_player('host')]));
      await _settle();
      expect((cubit.state.phase, cubit.state.failure), (RaceRoomPhase.failed, RaceRoomFailure.offline));
    });

    test('a broken stream fails with its reason', () async {
      await open(_room());
      repository.emitError(const RaceRoomException(RaceRoomFailure.offline));
      await _settle();
      expect((cubit.state.phase, cubit.state.failure), (RaceRoomPhase.failed, RaceRoomFailure.offline));
    });

    test('ready is set for the current round', () async {
      await open(_room(round: 3));
      await cubit.setReady(ready: true);
      expect(repository.calls.last, 'setReady true round 3');
      expect((cubit.state.isBusy, cubit.state.failure), (false, null));
    });

    test('a failed action keeps the room open and reports the reason', () async {
      await open(_room());
      repository.nextFailure = RaceRoomFailure.offline;
      await cubit.setReady(ready: true);
      expect((cubit.state.phase, cubit.state.failure), (RaceRoomPhase.open, RaceRoomFailure.offline));
    });
  });

  group('start', () {
    test('the host starts with a date from both nonces, a few seconds ahead', () async {
      await open(_room(players: _readyPair));
      await cubit.start();

      final started = repository.started!;
      final startAt = repository.now.add(RaceRoomCubit.startDelay);
      final date = RacePuzzle.dateFor(RacePuzzle.seedOf([123456789, 987654321], 1), startAt);
      expect(started.startAt, startAt);
      expect(started.puzzle, RaceRoomPuzzle(month: date.month, day: date.day));
    });

    test('a guest cannot start', () async {
      await open(_room(hostUid: 'guest', players: _readyPair));
      await cubit.start();
      expect(repository.started, isNull);
    });

    test('nothing starts until everyone is ready', () async {
      await open(_room(players: [_player('me', ready: true, nonce: 1), _player('guest')]));
      await cubit.start();
      expect(repository.started, isNull);
    });

    test('a rematch asks for the next round', () async {
      await open(_room(players: _readyPair, round: 2, status: RaceRoomStatus.playing));
      await cubit.rematch();
      expect(repository.calls.last, 'rematch round 3');
    });
  });

  group('race', () {
    final startAt = DateTime.utc(2026, 11, 13, 17, 0, 8);
    final drawn = RacePuzzle.dateFor(RacePuzzle.seedOf([123456789, 987654321], 1), startAt);

    RaceRoom racing({final RaceRoomPuzzle? puzzle}) => _room(
      hostUid: 'guest',
      players: _readyPair,
      status: RaceRoomStatus.playing,
      puzzle: puzzle ?? RaceRoomPuzzle(month: drawn.month, day: drawn.day),
      startAt: startAt.millisecondsSinceEpoch,
    );

    test("a guest plays the host's date when it draws the same one", () async {
      await open(racing(), code: 'K7M4P');
      expect(cubit.state.phase, RaceRoomPhase.open);
    });

    test('a guest drawing another date leaves the race', () async {
      final other = drawn.add(const Duration(days: 1));
      await open(
        racing(
          puzzle: RaceRoomPuzzle(month: other.month, day: other.day),
        ),
        code: 'K7M4P',
      );
      await _settle();
      expect((cubit.state.phase, cubit.state.failure), (RaceRoomPhase.failed, RaceRoomFailure.date));
      expect(repository.calls.last, 'leave K7M4P');
    });

    test('progress goes out at once and only when it changes', () async {
      await open(racing(), code: 'K7M4P');
      cubit.reportProgress(1);
      cubit.reportProgress(1);
      await _settle();
      expect(repository.calls.where((final c) => c.startsWith('progress')), ['progress 1']);
    });

    test('the finish time comes from the server clock', () async {
      await open(racing(), code: 'K7M4P');
      repository.now = startAt.add(const Duration(seconds: 42, milliseconds: 300));
      await cubit.finish();
      expect(repository.calls.last, 'finish 42300');
    });

    test('a failed finish is retried', () async {
      await cubit.close();
      cubit = RaceRoomCubit(repository, finishRetryDelay: Duration.zero);
      await open(racing(), code: 'K7M4P');
      repository.now = startAt.add(const Duration(seconds: 42));
      repository.nextFailure = RaceRoomFailure.offline;
      await cubit.finish();
      expect(repository.calls.where((final c) => c.startsWith('finish')), ['finish 42000', 'finish 42000']);
    });

    test('the final board goes out once a round', () async {
      await open(racing(), code: 'K7M4P');
      await cubit.publishBoard([PlacementParams('Square', 0, 0, 0, false)]);
      await cubit.publishBoard(const []);
      expect(repository.calls.where((final c) => c.startsWith('board')), ['board Square']);
    });

    test('a failed board is retried', () async {
      await cubit.close();
      cubit = RaceRoomCubit(repository, finishRetryDelay: Duration.zero);
      await open(racing(), code: 'K7M4P');
      repository.nextFailure = RaceRoomFailure.offline;
      await cubit.publishBoard(const []);
      expect(repository.calls.where((final c) => c.startsWith('board')), ['board ', 'board ']);
    });

    test('retries stop once the room is back in the lobby for the next round', () async {
      await cubit.close();
      cubit = RaceRoomCubit(repository, finishRetryDelay: const Duration(milliseconds: 20));
      await open(racing(), code: 'K7M4P');
      repository.nextFailure = RaceRoomFailure.offline;
      final board = cubit.publishBoard(const []);
      repository.emit(_room(hostUid: 'guest', round: 2, players: _readyPair));
      await _settle();
      await board;
      expect(repository.calls.where((final c) => c.startsWith('board')), ['board ']);
    });

    test('giving up is sent', () async {
      await open(racing(), code: 'K7M4P');
      await cubit.giveUp();
      expect(repository.calls.last, 'giveUp');
    });
  });

  group('leaving', () {
    test('leaves the room once', () async {
      await open(_room());
      await cubit.leave();
      await cubit.leave();
      expect(repository.calls.where((final c) => c.startsWith('leave')), ['leave K7M4P']);
    });

    test('closing the cubit leaves the room', () async {
      await open(_room());
      await cubit.close();
      await _settle();
      expect(repository.calls, contains('leave K7M4P'));
    });

    test('room updates after leaving are ignored', () async {
      await open(_room());
      await cubit.leave();
      final state = cubit.state;
      repository.emit(null);
      await _settle();
      expect(cubit.state, state);
    });
  });
}
