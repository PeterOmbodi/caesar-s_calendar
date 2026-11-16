import 'dart:async';
import 'dart:math';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/infrastructure/race/solver_race_repository.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_pieces.dart';
import 'package:flutter_test/flutter_test.dart';

const _you = SolverRaceRepository.myUid;
const _solver = SolverRaceRepository.solverUid;
const _puzzle = RaceRoomPuzzle(month: 10, day: 8);

void main() {
  late DateTime now;
  late SolverRaceRepository repository;
  late List<RaceRoom?> rooms;
  late StreamSubscription<RaceRoom?> subscription;
  late String code;

  Future<void> open(final SolverLevel level) async {
    now = DateTime.utc(2026, 11, 15, 12);
    repository = SolverRaceRepository(
      pieces: standardSolverPieces(),
      grid: solverGrid,
      level: level,
      solverNickname: 'Solver',
      random: Random(1),
      clock: () => now,
    );
    code = await repository.create(const RaceProfile(nickname: 'Me', colorIndex: 0));
    rooms = [];
    subscription = repository.watchRoom(code).listen(rooms.add);
    await Future<void>.delayed(Duration.zero);
  }

  RaceRoom room() => rooms.last!;

  Future<void> start() async {
    await repository.start(code, puzzle: _puzzle, startAt: now.add(const Duration(seconds: 8)));
  }

  // Moves the clock and waits for the next tick of the solver.
  Future<void> at(final Duration sinceStart) async {
    now = DateTime.fromMillisecondsSinceEpoch(room().startAt!, isUtc: true).add(sinceStart);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  tearDown(() async {
    await subscription.cancel();
    await repository.leave(code);
  });

  test('the room is ready to start at once, with the player as the host', () async {
    await open(SolverLevel.master);
    expect(room().hostUid, _you);
    expect(room().players.map((final p) => p.uid), [_you, _solver]);
    expect(room().canStart, isTrue);
  });

  test('there is no room to join', () async {
    await open(SolverLevel.master);
    expect(
      () => repository.join('K7M4P', const RaceProfile(nickname: 'Me', colorIndex: 0)),
      throwsA(isA<RaceRoomException>()),
    );
  });

  test('the solver finishes within its level time and shows its board', () async {
    await open(SolverLevel.master);
    await start();
    expect(room().status, RaceRoomStatus.playing);
    await at(const Duration(seconds: 30));
    expect(room().player(_solver)!.hasFinished, isFalse);
    await at(SolverLevel.master.maxTime + const Duration(seconds: 1));
    final solver = room().player(_solver)!;
    expect(
      solver.durationMs,
      inInclusiveRange(SolverLevel.master.minTime.inMilliseconds, SolverLevel.master.maxTime.inMilliseconds),
    );
    expect(solver.board!.pieces, hasLength(8));
    expect(room().firstFinishAt, room().startAt! + solver.durationMs!);
  });

  test('when the player finishes first, the race ends at once and the solver shows where it stopped', () async {
    await open(SolverLevel.confident);
    await start();
    await at(const Duration(seconds: 10));
    await repository.finish(code, durationMs: 10000);
    await Future<void>.delayed(Duration.zero);
    expect(RaceRules.isOver(room(), nowMs: now.millisecondsSinceEpoch), isTrue);
    await at(const Duration(seconds: 11));
    final solver = room().player(_solver)!;
    expect(solver.hasFinished, isFalse);
    expect(solver.board, isNotNull);
  });

  test('when the solver finishes first, the player has the time to finish', () async {
    await open(SolverLevel.master);
    await start();
    await at(SolverLevel.master.maxTime + const Duration(seconds: 1));
    final solved = room().firstFinishAt!;
    expect(room().player(_solver)!.hasFinished, isTrue);
    expect(RaceRules.isOver(room(), nowMs: solved + (RaceRules.graceSec - 1) * 1000), isFalse);
    await repository.finish(code, durationMs: solved - room().startAt! + 5000);
    await Future<void>.delayed(Duration.zero);
    expect(room().graceSec, RaceRules.graceSec);
  });

  test('giving up ends the race and shows the solver board', () async {
    await open(SolverLevel.master);
    await start();
    await at(const Duration(seconds: 5));
    await repository.giveUp(code);
    await at(const Duration(seconds: 6));
    expect(room().player(_you)!.gaveUp, isTrue);
    expect(room().player(_solver)!.board, isNotNull);
  });

  test('race again goes back to a lobby that is ready to start', () async {
    await open(SolverLevel.master);
    await start();
    await repository.finish(code, durationMs: 10000);
    await repository.rematch(code, round: 2);
    await Future<void>.delayed(Duration.zero);
    expect((room().status, room().round, room().startAt, room().firstFinishAt), (RaceRoomStatus.lobby, 2, null, null));
    expect(room().players.every((final p) => !p.hasFinished && p.board == null), isTrue);
    expect(room().canStart, isTrue);
    expect(room().graceSec, RaceRules.graceSec);
  });
}
