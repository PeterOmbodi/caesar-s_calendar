import 'dart:async';
import 'dart:math';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_entitlements.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_puzzle.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_piece.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_placement.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';
import 'package:caesar_puzzle/domain/algorithms/stepwise_solver.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';

/// A room on this device against the solver: no network and no account. The solver's search is replayed against the
/// clock, so its progress goes on while the app is in the background.
class SolverRaceRepository implements RaceRoomRepository {
  SolverRaceRepository({
    required this.pieces,
    required this.grid,
    required this.level,
    required this.solverNickname,
    final Random? random,
    final DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  static const String myUid = 'you';
  static const String solverUid = solverPlayerUid;
  static const String _code = 'SLVR2';
  static const int _solverColor = 7;

  /// The search is cut here; a solver that has not solved by then does not finish.
  static const int maxSteps = 200000;
  static const Duration _tick = Duration(milliseconds: 250);

  final List<SolverPiece> pieces;
  final PuzzleGridEntity grid;
  final SolverLevel level;
  final String solverNickname;
  final Random _random;
  final DateTime Function() _clock;

  final StreamController<RaceRoom?> _rooms = StreamController<RaceRoom?>.broadcast();
  RaceRoom? _room;
  Timer? _timer;
  List<SolverStep> _steps = const [];
  var _isSolvable = false;
  var _applied = 0;
  final Map<String, SolverPlacement> _board = {};

  @override
  String? get uid => myUid;

  @override
  DateTime serverNow() => _clock();

  int get _nowMs => serverNow().millisecondsSinceEpoch;

  @override
  Future<String> create(final RaceProfile profile) async {
    final now = _nowMs;
    _room = RaceRoom(
      code: _code,
      hostUid: myUid,
      status: RaceRoomStatus.lobby,
      maxPlayers: RaceEntitlements.duel.maxPlayers,
      graceSec: RaceRules.graceSec,
      hints: 0,
      round: 1,
      players: [
        _ready(RacePlayer(uid: myUid, nickname: profile.nickname, colorIndex: profile.colorIndex, joinedAt: now)),
        _ready(RacePlayer(uid: solverUid, nickname: solverNickname, colorIndex: _solverColor, joinedAt: now + 1)),
      ],
      createdAt: now,
    );
    return _code;
  }

  @override
  Future<void> join(final String code, final RaceProfile profile) async =>
      throw const RaceRoomException(RaceRoomFailure.noRoom);

  @override
  Future<void> leave(final String code) async {
    _timer?.cancel();
    _room = null;
    await _rooms.close();
  }

  @override
  Stream<RaceRoom?> watchRoom(final String code) {
    // The cubit listens after create, so the room it missed comes first.
    scheduleMicrotask(() => _emit(_room));
    return _rooms.stream;
  }

  @override
  Future<void> setReady(final String code, {required final bool ready, required final int round}) async =>
      _updatePlayer(myUid, (final p) => _ready(p, ready: ready));

  @override
  Future<void> start(final String code, {required final RaceRoomPuzzle puzzle, required final DateTime startAt}) async {
    final room = _room;
    if (room == null) {
      return;
    }
    _set(
      _copyRoom(room, status: RaceRoomStatus.playing, puzzle: puzzle, startAt: startAt.millisecondsSinceEpoch),
    );
    await _search(DateTime(RacePuzzle.year, puzzle.month, puzzle.day));
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _play());
  }

  @override
  Future<void> reportProgress(final String code, final int placed) async =>
      _updatePlayer(myUid, (final p) => _copyPlayer(p, placed: placed));

  @override
  Future<void> finish(final String code, {required final int durationMs}) async {
    _updatePlayer(myUid, (final p) => _copyPlayer(p, durationMs: durationMs));
    final room = _room;
    if (room != null && room.player(solverUid)?.hasFinished == false) {
      // Unlike a person, the solver does not need the time to finish: it would only delay the result.
      _set(_copyRoom(room, firstFinishAt: room.firstFinishAt ?? _nowMs, graceSec: 0));
    } else {
      _markFirstFinish(_nowMs);
    }
  }

  @override
  Future<void> giveUp(final String code) async =>
      _updatePlayer(myUid, (final p) => _copyPlayer(p, gaveUp: true, gaveUpAt: _nowMs));

  @override
  Future<void> publishBoard(final String code, final RaceBoard board) async =>
      _updatePlayer(myUid, (final p) => _copyPlayer(p, board: board));

  @override
  Future<void> rematch(final String code, {required final int round}) async {
    final room = _room;
    if (room == null) {
      return;
    }
    _timer?.cancel();
    _set(
      RaceRoom(
        code: room.code,
        hostUid: room.hostUid,
        status: RaceRoomStatus.lobby,
        maxPlayers: room.maxPlayers,
        graceSec: RaceRules.graceSec,
        hints: room.hints,
        round: round,
        players: [
          for (final p in room.players)
            _ready(RacePlayer(uid: p.uid, nickname: p.nickname, colorIndex: p.colorIndex, joinedAt: p.joinedAt)),
        ],
        createdAt: _nowMs,
      ),
    );
  }

  // Runs in slices so that the screen does not freeze, the web having no isolates.
  Future<void> _search(final DateTime date) async {
    final solver = StepwiseSolver(
      PuzzleSolver(grid: grid, pieces: pieces, date: date),
      mostConstrainedFirst: level.mostConstrainedFirst,
      skipDeadEnds: level.skipDeadEnds,
    );
    final steps = <SolverStep>[];
    final iterator = solver.steps().iterator;
    while (steps.length < maxSteps && iterator.moveNext()) {
      steps.add(iterator.current);
      if (steps.length % 2000 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    _steps = steps;
    _isSolvable = solver.isSolved;
    _applied = 0;
    _board.clear();
  }

  void _play() {
    final room = _room;
    final startAt = room?.startAt;
    if (room == null || startAt == null || room.status != RaceRoomStatus.playing) {
      _timer?.cancel();
      return;
    }
    final now = _nowMs;
    final solver = room.player(solverUid);
    if (solver == null) {
      _timer?.cancel();
      return;
    }
    if (!solver.hasFinished) {
      _catchUp(room, startAt, min(now, RaceRules.endsAtMs(room) ?? now));
    }
    final current = _room;
    if (current == null || RaceRules.isOver(current, nowMs: now)) {
      _timer?.cancel();
      _publishSolverBoard();
    }
  }

  // Moves up to [untilMs], not up to now: after a long pause in the background the solver may have finished long
  // ago, but not after the race ended.
  void _catchUp(final RaceRoom room, final int startAt, final int untilMs) {
    final time = level.timeFor(_steps.length).inMilliseconds;
    final due = untilMs <= startAt ? 0 : min(_steps.length, (_steps.length * (untilMs - startAt) / time).floor());
    while (_applied < due) {
      switch (_steps[_applied++]) {
        case PlaceStep(:final placement):
          _board[placement.piece.id] = placement;
        case RemoveStep(:final pieceId):
          _board.remove(pieceId);
      }
    }
    if (_isSolvable && _applied == _steps.length) {
      _updatePlayer(solverUid, (final p) => _copyPlayer(p, placed: _board.length, durationMs: time));
      _markFirstFinish(startAt + time);
      _publishSolverBoard();
    } else if (room.player(solverUid)?.placed != _board.length) {
      _updatePlayer(solverUid, (final p) => _copyPlayer(p, placed: _board.length));
    }
  }

  void _publishSolverBoard() {
    if (_room?.player(solverUid)?.board != null) {
      return;
    }
    final board = RaceBoard([
      for (final p in _board.values) PlacementParams(p.piece.id, p.row, p.col, p.rotationSteps, p.isFlipped),
    ]);
    _updatePlayer(solverUid, (final p) => _copyPlayer(p, board: board));
  }

  void _markFirstFinish(final int atMs) {
    final room = _room;
    if (room != null && room.firstFinishAt == null) {
      _set(_copyRoom(room, firstFinishAt: atMs));
    }
  }

  RacePlayer _ready(final RacePlayer player, {final bool ready = true}) => RacePlayer(
    uid: player.uid,
    nickname: player.nickname,
    colorIndex: player.colorIndex,
    joinedAt: player.joinedAt,
    ready: ready,
    nonce: ready ? _random.nextInt(0x7FFFFFFF) : null,
  );

  void _updatePlayer(final String uid, final RacePlayer Function(RacePlayer player) update) {
    final room = _room;
    if (room == null) {
      return;
    }
    _set(
      _copyRoom(
        room,
        players: [for (final p in room.players) p.uid == uid ? update(p) : p],
      ),
    );
  }

  void _set(final RaceRoom room) {
    _room = room;
    _emit(room);
  }

  void _emit(final RaceRoom? room) {
    if (!_rooms.isClosed) {
      _rooms.add(room);
    }
  }

  static RacePlayer _copyPlayer(
    final RacePlayer p, {
    final int? placed,
    final int? durationMs,
    final bool? gaveUp,
    final int? gaveUpAt,
    final RaceBoard? board,
  }) => RacePlayer(
    uid: p.uid,
    nickname: p.nickname,
    colorIndex: p.colorIndex,
    joinedAt: p.joinedAt,
    online: p.online,
    lastSeen: p.lastSeen,
    ready: p.ready,
    nonce: p.nonce,
    placed: placed ?? p.placed,
    durationMs: durationMs ?? p.durationMs,
    gaveUp: gaveUp ?? p.gaveUp,
    gaveUpAt: gaveUpAt ?? p.gaveUpAt,
    outAt: p.outAt,
    board: board ?? p.board,
  );

  static RaceRoom _copyRoom(
    final RaceRoom room, {
    final RaceRoomStatus? status,
    final List<RacePlayer>? players,
    final RaceRoomPuzzle? puzzle,
    final int? startAt,
    final int? firstFinishAt,
    final int? graceSec,
  }) => RaceRoom(
    code: room.code,
    hostUid: room.hostUid,
    status: status ?? room.status,
    maxPlayers: room.maxPlayers,
    graceSec: graceSec ?? room.graceSec,
    hints: room.hints,
    round: room.round,
    players: players ?? room.players,
    puzzle: puzzle ?? room.puzzle,
    startAt: startAt ?? room.startAt,
    firstFinishAt: firstFinishAt ?? room.firstFinishAt,
    createdAt: room.createdAt,
  );
}
