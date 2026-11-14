import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_puzzle.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';

enum RaceRoomPhase { entering, open, closed, failed }

class RaceRoomState {
  const RaceRoomState({required this.phase, this.code, this.room, this.failure, this.isBusy = false});

  final RaceRoomPhase phase;
  final String? code;
  final RaceRoom? room;

  /// Why entering failed, or why the last action in the room did.
  final RaceRoomFailure? failure;
  final bool isBusy;

  @override
  bool operator ==(final Object other) =>
      other is RaceRoomState &&
      other.phase == phase &&
      other.code == code &&
      other.room == room &&
      other.failure == failure &&
      other.isBusy == isBusy;

  @override
  int get hashCode => Object.hash(phase, code, room, failure, isBusy);
}

class RaceRoomCubit extends Cubit<RaceRoomState> {
  RaceRoomCubit(this._repository, {this.finishRetryDelay = const Duration(seconds: 2)})
    : super(const RaceRoomState(phase: RaceRoomPhase.entering));

  static const int _finishAttempts = 5;
  static const Duration _progressInterval = Duration(seconds: 1);

  final Duration finishRetryDelay;

  /// Covers the five start lights and the random pause after them.
  static const Duration startDelay = Duration(seconds: 8);

  final RaceRoomRepository _repository;
  StreamSubscription<RaceRoom?>? _subscription;
  bool _hasLeft = false;
  bool _isFinishing = false;
  Timer? _progressTimer;
  int? _sentPlaced;
  int? _pendingPlaced;
  int? _checkedStartAt;

  String? get uid => _repository.uid;

  DateTime serverNow() => _repository.serverNow();

  /// Creates a room, or joins the one with [code].
  Future<void> enter({required final RaceProfile profile, final String? code}) async {
    try {
      final String entered;
      if (code == null) {
        entered = await _repository.create(profile);
      } else {
        await _repository.join(code, profile);
        entered = code;
      }
      if (isClosed || _hasLeft) {
        unawaited(_leaveQuietly(entered));
        return;
      }
      emit(RaceRoomState(phase: RaceRoomPhase.entering, code: entered));
      _subscription = _repository.watchRoom(entered).listen(_onRoom, onError: _onError);
    } on RaceRoomException catch (e) {
      if (!isClosed) {
        emit(RaceRoomState(phase: RaceRoomPhase.failed, failure: e.failure));
      }
    }
  }

  Future<void> setReady({required final bool ready}) =>
      _run((final code, final room) => _repository.setReady(code, ready: ready, round: room.round));

  Future<void> start() => _run((final code, final room) async {
    if (room.hostUid != uid || !room.canStart) {
      return;
    }
    final startAt = _repository.serverNow().add(startDelay);
    final date = RacePuzzle.dateFor(room.seed, startAt);
    await _repository.start(
      code,
      puzzle: RaceRoomPuzzle(month: date.month, day: date.day),
      startAt: startAt,
    );
  });

  /// Tells the others how many pieces are on the board, at most once a second.
  void reportProgress(final int placed) {
    _pendingPlaced = placed;
    if (_progressTimer == null) {
      _sendProgress();
      _progressTimer = Timer.periodic(_progressInterval, (_) => _sendProgress());
    }
  }

  /// Records the solve; the time is taken from the server clock, so a failed attempt is retried with a new one.
  Future<void> finish() async {
    final code = state.code;
    final startAt = state.room?.startAt;
    if (code == null || startAt == null || _isFinishing) {
      return;
    }
    _isFinishing = true;
    for (var attempt = 0; attempt < _finishAttempts && !_hasLeft && !isClosed; attempt++) {
      try {
        await _repository.finish(code, durationMs: serverNow().millisecondsSinceEpoch - startAt);
        return;
      } on RaceRoomException {
        await Future<void>.delayed(finishRetryDelay);
      }
    }
    _isFinishing = false;
  }

  Future<void> giveUp() async {
    final code = state.code;
    if (code == null) {
      return;
    }
    try {
      await _repository.giveUp(code);
    } on RaceRoomException {
      // The board is closed here anyway; the others see the player offline once they leave.
    }
  }

  Future<void> rematch() => _run((final code, final room) => _repository.rematch(code, round: room.round + 1));

  Future<void> leave() async {
    if (_hasLeft) {
      return;
    }
    _hasLeft = true;
    _progressTimer?.cancel();
    await _subscription?.cancel();
    final code = state.code;
    if (code != null) {
      await _leaveQuietly(code);
    }
  }

  @override
  Future<void> close() async {
    unawaited(leave());
    return super.close();
  }

  void _onRoom(final RaceRoom? room) {
    if (_hasLeft) {
      return;
    }
    if (room?.status == RaceRoomStatus.lobby) {
      _isFinishing = false;
      _progressTimer?.cancel();
      _progressTimer = null;
      _sentPlaced = null;
      _pendingPlaced = null;
    }
    final wasHost = state.room?.hostUid == uid;
    if (room == null && !wasHost) {
      emit(RaceRoomState(phase: RaceRoomPhase.closed, code: state.code));
    } else if (room == null || room.player(uid ?? '') == null) {
      // A lost connection closes the host's lobby and frees a guest's place.
      emit(RaceRoomState(phase: RaceRoomPhase.failed, code: state.code, failure: RaceRoomFailure.offline));
    } else if (!_drawsSameDate(room)) {
      emit(RaceRoomState(phase: RaceRoomPhase.failed, code: state.code, failure: RaceRoomFailure.date));
      unawaited(leave());
    } else {
      emit(RaceRoomState(phase: RaceRoomPhase.open, code: state.code, room: room, isBusy: state.isBusy));
    }
  }

  void _onError(final Object error) {
    if (_hasLeft) {
      return;
    }
    emit(
      RaceRoomState(
        phase: RaceRoomPhase.failed,
        code: state.code,
        failure: error is RaceRoomException ? error.failure : RaceRoomFailure.unknown,
      ),
    );
  }

  Future<void> _run(final Future<void> Function(String code, RaceRoom room) action) async {
    final code = state.code;
    final room = state.room;
    if (code == null || room == null || state.isBusy) {
      return;
    }
    emit(RaceRoomState(phase: state.phase, code: code, room: room, isBusy: true));
    RaceRoomFailure? failure;
    try {
      await action(code, room);
    } on RaceRoomException catch (e) {
      failure = e.failure;
    }
    if (!isClosed && !_hasLeft && state.phase == RaceRoomPhase.open) {
      emit(RaceRoomState(phase: state.phase, code: code, room: state.room, failure: failure));
    }
  }

  // Every client draws the date itself, so that nobody plays a different puzzle without knowing it.
  bool _drawsSameDate(final RaceRoom room) {
    final startAt = room.startAt;
    final puzzle = room.puzzle;
    if (room.status != RaceRoomStatus.playing || startAt == null || puzzle == null || startAt == _checkedStartAt) {
      return true;
    }
    final date = RacePuzzle.dateFor(room.seed, DateTime.fromMillisecondsSinceEpoch(startAt, isUtc: true));
    if (date.month != puzzle.month || date.day != puzzle.day) {
      return false;
    }
    _checkedStartAt = startAt;
    return true;
  }

  void _sendProgress() {
    final code = state.code;
    final placed = _pendingPlaced;
    if (code == null || placed == null || placed == _sentPlaced) {
      return;
    }
    _sentPlaced = placed;
    unawaited(
      _repository.reportProgress(code, placed).catchError((final Object _) {
        _sentPlaced = null;
      }),
    );
  }

  Future<void> _leaveQuietly(final String code) async {
    try {
      await _repository.leave(code);
    } on RaceRoomException {
      // The room is left behind; it frees itself when the connection drops or after two hours.
    }
  }
}
