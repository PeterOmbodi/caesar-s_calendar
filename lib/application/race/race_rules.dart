import 'dart:math';

import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';

abstract final class RaceRules {
  static const Duration timeLimit = Duration(minutes: 10);

  /// Time to finish after the first solve in a duel; the room keeps its own value.
  static const int graceSec = 60;
  static const Duration reconnectTime = Duration(seconds: 30);

  /// Offline for longer than [reconnectTime] in the middle of the race.
  static bool isOut(final RacePlayer player, {required final int nowMs}) {
    final lastSeen = player.lastSeen;
    return !player.online &&
        !player.hasFinished &&
        !player.gaveUp &&
        lastSeen != null &&
        nowMs - lastSeen >= reconnectTime.inMilliseconds;
  }

  static bool isRacing(final RacePlayer player, {required final int nowMs}) =>
      !player.hasFinished && !player.gaveUp && !isOut(player, nowMs: nowMs);

  /// Null before anybody solves.
  static int? graceEndsAtMs(final RaceRoom room) {
    final startAt = room.startAt;
    if (startAt == null) {
      return null;
    }
    final solves = [
      for (final player in room.players)
        if (player.durationMs case final duration?) startAt + duration,
    ];
    // Counted from the solve itself when the solver's write of firstFinishAt did not get through.
    final first = room.firstFinishAt ?? (solves.isEmpty ? null : solves.reduce(min));
    return first == null ? null : first + room.graceSec * 1000;
  }

  static int? endsAtMs(final RaceRoom room) {
    final startAt = room.startAt;
    if (startAt == null) {
      return null;
    }
    final limit = startAt + timeLimit.inMilliseconds;
    final grace = graceEndsAtMs(room);
    return grace == null ? limit : min(limit, grace);
  }

  static bool isOver(final RaceRoom room, {required final int nowMs}) {
    final endsAt = endsAtMs(room);
    if (endsAt != null && nowMs >= endsAt) {
      return true;
    }
    final inRace = room.players.where((final p) => p.hasFinished || isRacing(p, nowMs: nowMs)).toList();
    // The last one left in the race wins without having to solve.
    if (room.players.length > 1 && inRace.length <= 1) {
      return true;
    }
    return inRace.every((final p) => p.hasFinished);
  }

  /// The next moment the race may end without anybody writing to the room: the end of the time to finish or of the
  /// time an offline player has to come back.
  static int? nextDeadlineMs(final RaceRoom room, {required final int nowMs}) {
    final deadlines = [
      ?endsAtMs(room),
      for (final player in room.players)
        if (!player.online && isRacing(player, nowMs: nowMs) && player.lastSeen != null)
          player.lastSeen! + reconnectTime.inMilliseconds,
    ];
    return deadlines.isEmpty ? null : deadlines.reduce(min);
  }

  /// The number of pieces on the board does not count: it says nothing about being right.
  static List<RacePlayer> standings(final Iterable<RacePlayer> players, {required final int nowMs}) {
    final finished = players.where((final p) => p.hasFinished).toList()
      ..sort((final a, final b) => a.durationMs!.compareTo(b.durationMs!));
    return [
      ...finished,
      ...players.where((final p) => isRacing(p, nowMs: nowMs)),
      ...players.where((final p) => !p.hasFinished && !isRacing(p, nowMs: nowMs)),
    ];
  }
}
