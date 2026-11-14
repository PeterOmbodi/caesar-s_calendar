import 'dart:async';
import 'dart:math';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_entitlements.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/race/race_room_mapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RaceRoomRepository)
class RaceRoomRepositoryImpl implements RaceRoomRepository {
  RaceRoomRepositoryImpl(this._database, this._auth);

  // Offline writes queue up instead of failing, so every call needs its own deadline.
  static const _timeout = Duration(seconds: 10);
  static const _connectWait = Duration(seconds: 3);
  static const _staleAfter = Duration(hours: 2);
  static const _createAttempts = 5;
  static const _graceSec = 60;

  final FirebaseDatabase _database;
  final AuthService _auth;
  final Random _random = Random.secure();

  int _serverOffsetMs = 0;
  // Both listeners live as long as the repository: re-listening to the same `.info` path after a cancel proved
  // unreliable.
  bool _isListeningToServer = false;
  final StreamController<bool> _connectionChanges = StreamController<bool>.broadcast();
  bool _isConnected = false;
  Future<void>? _leaving;

  // The server forgets onDisconnect handlers once they fire, so they are set again after every reconnect.
  String? _presenceCode;
  bool _isHost = false;
  // In the lobby a lost connection frees the place (and closes the host's room); in a race the player stays.
  bool _inLobby = true;

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  DateTime serverNow() => DateTime.now().add(Duration(milliseconds: _serverOffsetMs));

  @override
  Future<String> create(final RaceProfile profile) => _entering(() async {
    final uid = _requireUid();
    for (var attempt = 0; attempt < _createAttempts; attempt++) {
      final code = RaceRoomCode.generate(_random);
      final existing = await _read(code);
      if (existing != null) {
        if (!_isStale(existing)) {
          continue;
        }
        await _guard(_room(code).remove());
      }
      if (await _guard(_claim(code, uid, profile))) {
        await _keepPresence(code, isHost: true, inLobby: true);
        return code;
      }
    }
    throw const RaceRoomException(RaceRoomFailure.unknown, 'no free room code');
  });

  @override
  Future<void> join(final String code, final RaceProfile profile) => _entering(() async {
    final uid = _requireUid();
    final room = await _read(code);
    if (room == null || _isStale(room)) {
      throw const RaceRoomException(RaceRoomFailure.noRoom);
    }
    final player = _player(code, uid);
    if (room.player(uid) != null) {
      await _guard(player.update({'online': true}));
    } else {
      if (room.status != RaceRoomStatus.lobby) {
        throw const RaceRoomException(RaceRoomFailure.started);
      }
      if (room.isFull) {
        throw const RaceRoomException(RaceRoomFailure.full);
      }
      await _guard(player.set(_newPlayer(profile)), denied: RaceRoomFailure.started);
      // The rules cannot count players, so two guests can get in at once; the later one steps back.
      final joined = await _read(code);
      final place = joined?.players.indexWhere((final p) => p.uid == uid) ?? -1;
      if (joined == null || place < 0) {
        throw const RaceRoomException(RaceRoomFailure.noRoom);
      }
      if (place >= joined.maxPlayers) {
        await _guard(player.remove());
        throw const RaceRoomException(RaceRoomFailure.full);
      }
    }
    await _keepPresence(code, isHost: room.hostUid == uid, inLobby: room.status == RaceRoomStatus.lobby);
  });

  @override
  Future<void> leave(final String code) async {
    final leaving = _leave(code);
    _leaving = leaving;
    try {
      await leaving;
    } finally {
      if (identical(_leaving, leaving)) {
        _leaving = null;
      }
    }
  }

  // Nothing here waits for a read: the write goes first, and going offline fires the onDisconnect handlers, which
  // do the same if the write did not get through.
  Future<void> _leave(final String code) async {
    final uid = this.uid;
    try {
      if (uid == null || _presenceCode != code) {
        return;
      }
      _presenceCode = null;
      final player = _player(code, uid);
      if (_inLobby) {
        await _guard(_isHost ? _room(code).remove() : player.remove());
      } else {
        await _guard(player.update({'online': false, 'lastSeen': ServerValue.timestamp}));
      }
    } finally {
      await _disconnect();
    }
  }

  @override
  Stream<RaceRoom?> watchRoom(final String code) => _room(code).onValue
      .map((final event) {
        final room = RaceRoomMapper.fromValue(code, event.snapshot.value);
        _followStatus(code, room);
        return room;
      })
      .transform(
        StreamTransformer<RaceRoom?, RaceRoom?>.fromHandlers(
          handleError: (final error, final stackTrace, final sink) => sink.addError(
            error is FirebaseException ? RaceRoomException(_failureOf(error), error) : error,
            stackTrace,
          ),
        ),
      );

  @override
  Future<void> setReady(final String code, {required final bool ready, required final int round}) => _guard(
    _player(code, _requireUid()).update({
      'ready': ready,
      'round': round,
      'nonce': ready ? _random.nextInt(0x7FFFFFFF) : null,
      'placed': 0,
      'durationMs': null,
      'finishedAt': null,
      'gaveUp': null,
    }),
  );

  @override
  Future<void> start(
    final String code, {
    required final RaceRoomPuzzle puzzle,
    required final DateTime startAt,
  }) async {
    final room = _room(code);
    // From here a dropped connection must not close the room.
    _inLobby = false;
    try {
      await _guard(room.onDisconnect().cancel());
      await _registerDisconnect();
      await _guard(
        room.update({
          'status': RaceRoomStatus.playing.name,
          'puzzle': {'month': puzzle.month, 'day': puzzle.day},
          'startAt': startAt.millisecondsSinceEpoch,
          'firstFinishAt': null,
          'createdAt': ServerValue.timestamp,
        }),
      );
    } on RaceRoomException {
      _inLobby = true;
      unawaited(_restorePresence());
      rethrow;
    }
  }

  @override
  Future<void> reportProgress(final String code, final int placed) =>
      _guard(_player(code, _requireUid()).update({'placed': placed}));

  @override
  Future<void> finish(final String code, {required final int durationMs}) async {
    await _guard(
      _player(code, _requireUid()).update({'durationMs': durationMs, 'finishedAt': ServerValue.timestamp}),
    );
    await _guard(
      _room(code)
          .child('firstFinishAt')
          .runTransaction(
            (final value) => value == null ? Transaction.success(ServerValue.timestamp) : Transaction.abort(),
            applyLocally: false,
          ),
    );
  }

  @override
  Future<void> giveUp(final String code) => _guard(_player(code, _requireUid()).update({'gaveUp': true}));

  @override
  Future<void> rematch(final String code, {required final int round}) async {
    await _guard(
      _room(code).update({
        'status': RaceRoomStatus.lobby.name,
        'round': round,
        'puzzle': null,
        'startAt': null,
        'firstFinishAt': null,
        'createdAt': ServerValue.timestamp,
      }),
    );
    _inLobby = true;
    await _registerDisconnect();
    // Whoever left during the race must not hold a place in the new lobby.
    final room = await _read(code);
    for (final player in room?.players ?? const <RacePlayer>[]) {
      if (!player.online && player.uid != uid) {
        await _guard(_player(code, player.uid).remove());
      }
    }
  }

  DatabaseReference _room(final String code) => _database.ref('rooms/$code');

  DatabaseReference _player(final String code, final String uid) => _room(code).child('players/$uid');

  String _requireUid() => uid ?? (throw const RaceRoomException(RaceRoomFailure.signInRequired));

  Future<RaceRoom?> _read(final String code) async =>
      RaceRoomMapper.fromValue(code, (await _guard(_room(code).get())).value);

  bool _isStale(final RaceRoom room) {
    final createdAt = room.createdAt;
    return createdAt != null && serverNow().millisecondsSinceEpoch - createdAt > _staleAfter.inMilliseconds;
  }

  Map<String, Object?> _newPlayer(final RaceProfile profile) => {
    'nickname': profile.nickname,
    'colorIndex': profile.colorIndex,
    'joinedAt': ServerValue.timestamp,
    'online': true,
  };

  // False when another host took the code first.
  Future<bool> _claim(final String code, final String uid, final RaceProfile profile) async {
    try {
      await _room(code).update({
        'hostUid': uid,
        'status': RaceRoomStatus.lobby.name,
        'maxPlayers': RaceEntitlements.duel.maxPlayers,
        'settings': {'graceSec': _graceSec, 'hints': 0},
        'round': 1,
        'createdAt': ServerValue.timestamp,
        'players/$uid': _newPlayer(profile),
      });
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
  }

  Future<T> _entering<T>(final Future<T> Function() enter) async {
    try {
      // A leave still in flight would disconnect this entry halfway.
      await _leaving?.catchError((final Object _) {});
      await _connect();
      return await enter();
    } on RaceRoomException {
      await _disconnect();
      rethrow;
    } on Exception catch (e) {
      await _disconnect();
      throw RaceRoomException(RaceRoomFailure.unknown, e);
    }
  }

  Future<void> _connect() async {
    await _database.goOnline();
    _listenToServer();
    if (!_isConnected) {
      // Best effort: if the signal does not come, the first read decides whether there is a connection.
      await _connectionChanges.stream
          .firstWhere((final isConnected) => isConnected)
          .timeout(_connectWait, onTimeout: () => false);
    }
  }

  void _listenToServer() {
    if (_isListeningToServer) {
      return;
    }
    _isListeningToServer = true;
    _database.ref('.info/serverTimeOffset').onValue.listen((final event) {
      final offset = event.snapshot.value;
      if (offset is num) {
        _serverOffsetMs = offset.toInt();
      }
    });
    _database.ref('.info/connected').onValue.listen((final event) {
      final isConnected = event.snapshot.value == true;
      if (isConnected == _isConnected) {
        return;
      }
      _isConnected = isConnected;
      _connectionChanges.add(isConnected);
      if (isConnected) {
        unawaited(_restorePresence());
      }
    });
  }

  Future<void> _disconnect() async {
    _presenceCode = null;
    _isConnected = false;
    try {
      await _database.goOffline();
    } on Exception {
      // Nothing to close if the plugin never connected.
    }
  }

  Future<void> _keepPresence(final String code, {required final bool isHost, required final bool inLobby}) async {
    _presenceCode = code;
    _isHost = isHost;
    _inLobby = inLobby;
    await _registerDisconnect();
  }

  Future<void> _registerDisconnect() async {
    final code = _presenceCode;
    final uid = this.uid;
    if (code == null || uid == null) {
      return;
    }
    final player = _player(code, uid);
    await _guard(player.onDisconnect().cancel());
    await _guard(
      _inLobby
          ? player.onDisconnect().remove()
          : player.onDisconnect().update({'online': false, 'lastSeen': ServerValue.timestamp}),
    );
    if (_inLobby && _isHost) {
      await _guard(_room(code).onDisconnect().remove());
    }
  }

  void _followStatus(final String code, final RaceRoom? room) {
    if (room == null || code != _presenceCode) {
      return;
    }
    final inLobby = room.status == RaceRoomStatus.lobby;
    if (inLobby != _inLobby) {
      _inLobby = inLobby;
      unawaited(_restorePresence());
    }
  }

  Future<void> _restorePresence() async {
    final code = _presenceCode;
    final uid = this.uid;
    if (code == null || uid == null) {
      return;
    }
    try {
      await _registerDisconnect();
      await _guard(_player(code, uid).update({'online': true}));
    } on RaceRoomException {
      // The next reconnect tries again.
    }
  }

  Future<T> _guard<T>(final Future<T> operation, {final RaceRoomFailure? denied}) async {
    try {
      return await operation.timeout(_timeout);
    } on TimeoutException catch (e) {
      throw _failed(RaceRoomFailure.offline, e);
    } on FirebaseException catch (e) {
      throw _failed(e.code == 'permission-denied' && denied != null ? denied : _failureOf(e), e);
    } on RaceRoomException {
      rethrow;
    } on Exception catch (e) {
      throw _failed(RaceRoomFailure.unknown, e);
    }
  }

  static RaceRoomException _failed(final RaceRoomFailure failure, final Object cause) {
    debugPrint('Race room: $failure, $cause\n${StackTrace.current}');
    return RaceRoomException(failure, cause);
  }

  static RaceRoomFailure _failureOf(final FirebaseException error) => switch (error.code) {
    'network-error' || 'disconnected' || 'unavailable' => RaceRoomFailure.offline,
    _ => RaceRoomFailure.unknown,
  };
}
