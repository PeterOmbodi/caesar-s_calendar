import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:collection/collection.dart';

enum RaceRoomStatus { lobby, playing, finished }

class RaceRoomPuzzle {
  const RaceRoomPuzzle({required this.month, required this.day});

  final int month;
  final int day;

  @override
  bool operator ==(final Object other) => other is RaceRoomPuzzle && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(month, day);
}

class RaceRoom {
  const RaceRoom({
    required this.code,
    required this.hostUid,
    required this.status,
    required this.maxPlayers,
    required this.graceSec,
    required this.hints,
    required this.round,
    required this.players,
    this.puzzle,
    this.startAt,
    this.firstFinishAt,
    this.createdAt,
  });

  final String code;
  final String hostUid;
  final RaceRoomStatus status;
  final int maxPlayers;

  /// Seconds the others get after the first finisher.
  final int graceSec;
  final int hints;
  final int round;

  /// In joining order.
  final List<RacePlayer> players;
  final RaceRoomPuzzle? puzzle;

  /// Server time when the board opens, epoch milliseconds.
  final int? startAt;

  /// Server time of the first solve, epoch milliseconds.
  final int? firstFinishAt;

  /// Server time, epoch milliseconds.
  final int? createdAt;

  RacePlayer? player(final String uid) => players.firstWhereOrNull((final p) => p.uid == uid);

  bool get isFull => players.length >= maxPlayers;

  bool get canStart => players.length >= 2 && players.every((final p) => p.ready && p.nonce != null);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RaceRoom &&
          other.code == code &&
          other.hostUid == hostUid &&
          other.status == status &&
          other.maxPlayers == maxPlayers &&
          other.graceSec == graceSec &&
          other.hints == hints &&
          other.round == round &&
          other.puzzle == puzzle &&
          other.startAt == startAt &&
          other.firstFinishAt == firstFinishAt &&
          other.createdAt == createdAt &&
          const ListEquality<RacePlayer>().equals(other.players, players);

  @override
  int get hashCode => Object.hash(
    code,
    hostUid,
    status,
    maxPlayers,
    graceSec,
    hints,
    round,
    puzzle,
    startAt,
    firstFinishAt,
    createdAt,
    const ListEquality<RacePlayer>().hash(players),
  );
}
