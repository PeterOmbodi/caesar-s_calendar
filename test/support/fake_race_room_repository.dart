import 'dart:async';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';

/// In-memory room repository: tests push room states with [emit] and read what was called from [calls].
class FakeRaceRoomRepository implements RaceRoomRepository {
  FakeRaceRoomRepository({this.uid = 'me', this.code = 'K7M4P', DateTime? now})
    : now = now ?? DateTime.utc(2026, 11, 13, 17);

  @override
  final String? uid;
  final String code;
  DateTime now;

  /// Thrown by the next call of any method, once.
  RaceRoomFailure? nextFailure;
  final List<String> calls = [];
  ({RaceRoomPuzzle puzzle, DateTime startAt})? started;

  final StreamController<RaceRoom?> _rooms = StreamController<RaceRoom?>.broadcast();

  void emit(final RaceRoom? room) => _rooms.add(room);

  void emitError(final Object error) => _rooms.addError(error);

  Future<void> dispose() => _rooms.close();

  void _record(final String call) {
    calls.add(call);
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw RaceRoomException(failure);
    }
  }

  @override
  DateTime serverNow() => now;

  @override
  Future<String> create(final RaceProfile profile) async {
    _record('create ${profile.nickname}');
    return code;
  }

  @override
  Future<void> join(final String code, final RaceProfile profile) async => _record('join $code');

  @override
  Future<void> leave(final String code) async => _record('leave $code');

  @override
  Stream<RaceRoom?> watchRoom(final String code) => _rooms.stream;

  @override
  Future<void> setReady(final String code, {required final bool ready, required final int round}) async =>
      _record('setReady $ready round $round');

  @override
  Future<void> start(
    final String code, {
    required final RaceRoomPuzzle puzzle,
    required final DateTime startAt,
  }) async {
    _record('start');
    started = (puzzle: puzzle, startAt: startAt);
  }

  @override
  Future<void> reportProgress(final String code, final int placed) async => _record('progress $placed');

  @override
  Future<void> finish(final String code, {required final int durationMs}) async => _record('finish $durationMs');

  @override
  Future<void> giveUp(final String code) async => _record('giveUp');

  @override
  Future<void> rematch(final String code, {required final int round}) async => _record('rematch round $round');
}
