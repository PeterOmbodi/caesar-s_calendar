import 'dart:math';

import 'package:caesar_puzzle/application/race/race_board.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:collection/collection.dart';

abstract final class RaceRules {
  static const Duration timeLimit = Duration(minutes: 10);

  /// Time for the others to finish after the first solve; the room keeps its own value.
  static const int graceSec = 15;
  static const Duration reconnectTime = Duration(seconds: 30);

  /// Offline for longer than [reconnectTime] in the middle of the race, by [nowMs].
  static bool isOut(final RacePlayer player, {required final int nowMs}) {
    if (player.hasFinished || hasGivenUp(player, nowMs: nowMs)) {
      return false;
    }
    final outAt = player.outAt;
    if (outAt != null && outAt <= nowMs) {
      return true;
    }
    final lastSeen = player.lastSeen;
    return !player.online && lastSeen != null && nowMs - lastSeen >= reconnectTime.inMilliseconds;
  }

  /// By [nowMs]; a give-up without its time, from an older client, counts at any moment.
  static bool hasGivenUp(final RacePlayer player, {required final int nowMs}) {
    final gaveUpAt = player.gaveUpAt;
    return player.gaveUp && (gaveUpAt == null || gaveUpAt <= nowMs);
  }

  /// The player's board from the round that started at [startAtMs]: a retried write from the last round may land
  /// after Race again.
  static RaceBoard? boardOf(final RacePlayer player, {required final int? startAtMs}) {
    final board = player.board;
    final publishedAt = board?.publishedAtMs;
    if (board == null || startAtMs == null || publishedAt == null) {
      return board;
    }
    return publishedAt >= startAtMs ? board : null;
  }

  static RacePlayer? firstFinisher(final RaceRoom room) =>
      room.players.where((final p) => p.hasFinished).sortedBy((final p) => p.durationMs!).firstOrNull;

  static bool isOnOtherDevice(final RacePlayer player, {required final String deviceId}) =>
      player.device != null && player.device != deviceId;

  static bool isRacing(final RacePlayer player, {required final int nowMs}) =>
      !player.hasFinished && !hasGivenUp(player, nowMs: nowMs) && !isOut(player, nowMs: nowMs);

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

  /// The earliest moment the race was over; what players do after it, like leaving, must not change the result.
  static int overAtMs(final RaceRoom room, {required final int nowMs}) {
    final startAt = room.startAt;
    if (startAt == null) {
      return nowMs;
    }
    final moments = <int>{
      ?endsAtMs(room),
      for (final player in room.players) ...[
        if (player.durationMs case final duration?) startAt + duration,
        if (!player.online && player.lastSeen != null) player.lastSeen! + reconnectTime.inMilliseconds,
        ?player.gaveUpAt,
        ?player.outAt,
      ],
    }.where((final t) => t <= nowMs).toList()..sort();
    for (final moment in moments) {
      if (isOver(room, nowMs: moment)) {
        return moment;
      }
    }
    return nowMs;
  }

  /// Away long enough to be out, and out while the race was still on. A player who left after the end and comes
  /// back is not, so that coming back does not change a result already decided.
  static bool wentOutDuringRace(final RaceRoom room, final RacePlayer player, {required final int nowMs}) {
    final lastSeen = player.lastSeen;
    return room.status == RaceRoomStatus.playing &&
        lastSeen != null &&
        isOut(player, nowMs: nowMs) &&
        overAtMs(room, nowMs: nowMs) > lastSeen;
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
