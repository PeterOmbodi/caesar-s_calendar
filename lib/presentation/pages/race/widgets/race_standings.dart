import 'dart:async';

import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

/// Everyone in the race, like the timing tower of a race broadcast.
class RaceStandings extends StatelessWidget {
  const RaceStandings({
    super.key,
    required this.players,
    required this.myUid,
    required this.isStarted,
    required this.totalPieces,
    required this.graceEndsAtMs,
    required this.now,
  });

  final List<RacePlayer> players;
  final String myUid;
  final bool isStarted;
  final int totalPieces;

  /// Server time when the time to finish after the first solve runs out; null when it does not run for this player.
  final int? graceEndsAtMs;

  /// Server clock.
  final DateTime Function() now;

  @override
  Widget build(final BuildContext context) {
    final chrome = ChromeTheme.of(context);
    final colors = GameColors.of(context);
    final standings = RaceRules.standings(players, nowMs: now().millisecondsSinceEpoch);
    // Information, like the race clock, so the same flat glass; the toolbar's Liquid Glass is for controls.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.glass,
        border: Border.all(color: colors.glassLine),
        borderRadius: BorderRadius.circular(chrome.barRadius),
      ),
      child: SizedBox(
        width: chrome.barHeight,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(9, 14, 5, 14),
          itemCount: standings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, final index) {
            final player = standings[index];
            return _StandingsItem(
              player: player,
              isMe: player.uid == myUid,
              isStarted: isStarted,
              totalPieces: totalPieces,
              graceEndsAtMs: player.hasFinished ? graceEndsAtMs : null,
              now: now,
            );
          },
        ),
      ),
    );
  }
}

class _StandingsItem extends StatelessWidget {
  const _StandingsItem({
    required this.player,
    required this.isMe,
    required this.isStarted,
    required this.totalPieces,
    required this.graceEndsAtMs,
    required this.now,
  });

  final RacePlayer player;
  final bool isMe;
  final bool isStarted;
  final int totalPieces;
  final int? graceEndsAtMs;
  final DateTime Function() now;

  String get _status {
    final duration = player.durationMs;
    if (duration != null) {
      return formatRaceTime(duration, tenths: true);
    }
    if (player.gaveUp) {
      return S.current.raceGaveUp;
    }
    if (!player.online) {
      return RaceRules.isOut(player, nowMs: now().millisecondsSinceEpoch) ? S.current.raceOut : S.current.raceOffline;
    }
    return isStarted ? S.current.raceProgress(player.placed, totalPieces) : S.current.raceReady;
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final graceEndsAt = graceEndsAtMs;
    final duration = player.durationMs;
    const figures = [FontFeature.tabularFigures()];
    final Widget mark = switch (player) {
      RacePlayer(hasFinished: true) => Icon(Icons.sports_score, size: 18, color: colors.text),
      RacePlayer(gaveUp: true) => Icon(Icons.flag_outlined, size: 18, color: colors.textSecondary),
      RacePlayer(online: false) => Icon(Icons.flag, size: 18, color: colors.customConfig),
      _ when !isStarted => Icon(Icons.check, size: 18, color: colors.ok),
      _ => Text(
        '${player.placed}/$totalPieces',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.text, fontFeatures: figures),
      ),
    };
    return Semantics(
      label: [if (isMe) S.current.raceYou, player.nickname, _status].join(', '),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            spacing: 4,
            children: [
              // The ring is drawn over the avatar's edge, so every avatar has the same size and position.
              Container(
                foregroundDecoration: isMe
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.accent, width: 2),
                      )
                    : null,
                child: AccountAvatar(
                  photoUrl: null,
                  fallbackLabel: AccountDisplay.avatarInitials(player.nickname),
                  radius: 13,
                  backgroundColor: colors.player(player.colorIndex),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: mark),
              ),
            ],
          ),
          if (duration != null)
            Text(
              formatRaceTime(duration, tenths: true),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.text, fontFeatures: figures),
            ),
          if (graceEndsAt != null) _GraceCountdown(endsAtMs: graceEndsAt, now: now),
        ],
      ),
    );
  }
}

class _GraceCountdown extends StatefulWidget {
  const _GraceCountdown({required this.endsAtMs, required this.now});

  final int endsAtMs;
  final DateTime Function() now;

  @override
  State<_GraceCountdown> createState() => _GraceCountdownState();
}

class _GraceCountdownState extends State<_GraceCountdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final left = widget.endsAtMs - widget.now().millisecondsSinceEpoch;
    final seconds = left <= 0 ? 0 : (left / 1000).ceil();
    return Semantics(
      label: S.current.raceGraceSemantics(seconds),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: colors.bad),
          const SizedBox(width: 4),
          Text(
            '$seconds',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.bad,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
