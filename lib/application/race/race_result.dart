import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';

enum RaceOutcome { finished, gaveUp, out, notFinished, racing }

class RaceStanding {
  const RaceStanding({required this.player, required this.outcome, this.place, this.gapMs});

  final RacePlayer player;
  final RaceOutcome outcome;

  /// Equal times share a place (1, 1, 3). Null for a player without a place.
  final int? place;

  /// Behind the winner; null without a finish time.
  final int? gapMs;

  bool get isWinner => place == 1;
}

abstract final class RaceResult {
  static List<RaceStanding> of(final RaceRoom room, {required final int nowMs}) {
    // Judged when the race ended: leaving afterwards does not make the one who stayed a winner.
    final judgedAt = RaceRules.overAtMs(room, nowMs: nowMs);
    return _at(
      room,
      nowMs: judgedAt,
      isOver: RaceRules.isOver(room, nowMs: judgedAt),
    );
  }

  static List<RaceStanding> _at(final RaceRoom room, {required final int nowMs, required final bool isOver}) {
    final players = RaceRules.standings(room.players, nowMs: nowMs);
    final times = [for (final p in players) ?p.durationMs];
    final best = times.isEmpty ? null : times.first;
    final racing = players.where((final p) => RaceRules.isRacing(p, nowMs: nowMs)).toList();
    // Without a finisher the last one left in the race wins.
    final survivor = best == null && racing.length == 1 && players.length > 1 ? racing.single : null;
    return [
      for (final player in players)
        switch (player) {
          RacePlayer(durationMs: final time?) => RaceStanding(
            player: player,
            outcome: RaceOutcome.finished,
            place: 1 + times.where((final t) => t < time).length,
            gapMs: time - best!,
          ),
          _ when RaceRules.hasGivenUp(player, nowMs: nowMs) => RaceStanding(
            player: player,
            outcome: RaceOutcome.gaveUp,
          ),
          _ when RaceRules.isOut(player, nowMs: nowMs) => RaceStanding(player: player, outcome: RaceOutcome.out),
          _ when !isOver => RaceStanding(player: player, outcome: RaceOutcome.racing),
          _ => RaceStanding(player: player, outcome: RaceOutcome.notFinished, place: player == survivor ? 1 : null),
        },
    ];
  }
}
