import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';

/// Reads a `rooms/{code}` node. Players' per-round fields left from an earlier round read as untouched.
abstract final class RaceRoomMapper {
  static RaceRoom? fromValue(final String code, final Object? value) {
    final room = _map(value);
    final hostUid = room?['hostUid'];
    if (room == null || hostUid is! String) {
      return null;
    }
    final round = _int(room['round']) ?? 1;
    final settings = _map(room['settings']);
    final puzzle = _map(room['puzzle']);
    final month = _int(puzzle?['month']);
    final day = _int(puzzle?['day']);
    final players = [
      for (final MapEntry(key: uid, value: player) in (_map(room['players']) ?? const {}).entries)
        if (_map(player) case final data?) _player(uid, data, round),
    ]..sort(_byJoining);
    return RaceRoom(
      code: code,
      hostUid: hostUid,
      status: RaceRoomStatus.values.asNameMap()[room['status']] ?? RaceRoomStatus.lobby,
      maxPlayers: _int(room['maxPlayers']) ?? 2,
      graceSec: _int(settings?['graceSec']) ?? 60,
      hints: _int(settings?['hints']) ?? 0,
      round: round,
      players: players,
      puzzle: month == null || day == null ? null : RaceRoomPuzzle(month: month, day: day),
      startAt: _int(room['startAt']),
      firstFinishAt: _int(room['firstFinishAt']),
      createdAt: _int(room['createdAt']),
    );
  }

  static RacePlayer _player(final String uid, final Map<String, Object?> data, final int round) {
    final isCurrent = _int(data['round']) == round;
    return RacePlayer(
      uid: uid,
      nickname: data['nickname'] as String? ?? '',
      colorIndex: _int(data['colorIndex']) ?? 0,
      joinedAt: _int(data['joinedAt']) ?? 0,
      online: data['online'] != false,
      lastSeen: _int(data['lastSeen']),
      ready: isCurrent && data['ready'] == true,
      nonce: isCurrent ? _int(data['nonce']) : null,
      placed: isCurrent ? _int(data['placed']) ?? 0 : 0,
      durationMs: isCurrent ? _int(data['durationMs']) : null,
      gaveUp: isCurrent && data['gaveUp'] == true,
      board: isCurrent ? RaceBoard.fromValue(data['board']) : null,
    );
  }

  static int _byJoining(final RacePlayer a, final RacePlayer b) {
    final byTime = a.joinedAt.compareTo(b.joinedAt);
    return byTime != 0 ? byTime : a.uid.compareTo(b.uid);
  }

  static Map<String, Object?>? _map(final Object? value) =>
      value is Map ? {for (final MapEntry(key: k, value: v) in value.entries) '$k': v} : null;

  // The web hands numbers over as doubles.
  static int? _int(final Object? value) => value is num ? value.toInt() : null;
}
