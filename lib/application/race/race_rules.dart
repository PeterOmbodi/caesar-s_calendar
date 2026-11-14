import 'dart:math';

import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';

abstract final class RaceRules {
  static const Duration timeLimit = Duration(minutes: 10);

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
    final racing = room.players.where((final p) => !p.gaveUp).toList();
    // The last one left in the race wins without having to solve.
    if (room.players.length > 1 && racing.length <= 1) {
      return true;
    }
    return racing.every((final p) => p.hasFinished);
  }

  /// The number of pieces on the board does not count: it says nothing about being right.
  static List<RacePlayer> standings(final Iterable<RacePlayer> players) {
    final finished = players.where((final p) => p.hasFinished).toList()
      ..sort((final a, final b) => a.durationMs!.compareTo(b.durationMs!));
    return [
      ...finished,
      ...players.where((final p) => !p.hasFinished && !p.gaveUp),
      ...players.where((final p) => !p.hasFinished && p.gaveUp),
    ];
  }
}
