import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_rules.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_grace_countdown.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_player_avatar.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/laurel_wreath.dart';
import 'package:material_ui/material_ui.dart';

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
    required this.solverLevel,
  });

  final List<RacePlayer> players;
  final String myUid;
  final bool isStarted;
  final int totalPieces;

  /// Server time when the time to finish after the first solve runs out; null when it does not run for this player.
  final int? graceEndsAtMs;

  /// Server clock.
  final DateTime Function() now;

  /// Null in a race between people.
  final SolverLevel? solverLevel;

  /// From here on a row has room for a name, short until [_fullNamesFrom].
  static const double _wideFrom = 120;
  static const double _fullNamesFrom = 180;

  @override
  Widget build(final BuildContext context) {
    final chrome = ChromeTheme.of(context);
    final colors = GameColors.of(context);
    final standings = RaceRules.standings(players, nowMs: now().millisecondsSinceEpoch);
    final firstTime = standings.firstOrNull?.durationMs;
    // Information, like the race clock, so the same flat glass; the toolbar's Liquid Glass is for controls.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.glass,
        border: Border.all(color: colors.glassLine),
        borderRadius: BorderRadius.circular(chrome.barRadius),
      ),
      child: LayoutBuilder(
        builder: (final context, final constraints) {
          final isWide = constraints.maxWidth >= _wideFrom;
          final isShort = constraints.maxWidth < _fullNamesFrom;
          final shortNames = NicknameGenerator.shortNames([for (final p in standings) p.nickname]);
          return ListView.separated(
            // Wide, the panel is only as tall as its rows, with the controls below.
            shrinkWrap: isWide,
            padding: isWide ? const EdgeInsets.all(10) : const EdgeInsets.fromLTRB(9, 14, 5, 14),
            itemCount: standings.length,
            separatorBuilder: (_, _) => SizedBox(height: isWide ? 6 : 14),
            itemBuilder: (_, final index) {
              final player = standings[index];
              final item = _StandingsData(
                player: player,
                name: isShort ? shortNames[index] : player.nickname,
                isMe: player.uid == myUid,
                isFirst: firstTime != null && player.durationMs == firstTime,
                isStarted: isStarted,
                totalPieces: totalPieces,
                graceEndsAtMs: player.hasFinished ? graceEndsAtMs : null,
                now: now,
                solverLevel: solverLevel,
              );
              return isWide
                  ? _WideStandingsItem(
                      item: item,
                      avatarSlot: isShort ? _StandingsAvatar.shortSlot : _StandingsAvatar.fullSlot,
                    )
                  : _StandingsItem(item: item);
            },
          );
        },
      ),
    );
  }
}

class _StandingsData {
  const _StandingsData({
    required this.player,
    required this.name,
    required this.isMe,
    required this.isFirst,
    required this.isStarted,
    required this.totalPieces,
    required this.graceEndsAtMs,
    required this.now,
    required this.solverLevel,
  });

  final RacePlayer player;
  final String name;
  final bool isMe;
  final bool isFirst;
  final bool isStarted;
  final int totalPieces;
  final int? graceEndsAtMs;
  final DateTime Function() now;
  final SolverLevel? solverLevel;

  String get status {
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

  String get semanticsLabel => [if (isMe) S.current.raceYou, player.nickname, status].join(', ');
}

class _StandingsItem extends StatelessWidget {
  const _StandingsItem({required this.item});

  final _StandingsData item;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final graceEndsAt = item.graceEndsAtMs;
    final duration = item.player.durationMs;
    return Semantics(
      label: item.semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            spacing: 4,
            children: [
              _StandingsAvatar(item: item),
              if (!item.isFirst)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: _StandingsMark(item: item),
                  ),
                ),
            ],
          ),
          if (duration != null)
            Text(
              formatRaceTime(duration, tenths: true),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          if (graceEndsAt != null) RaceGraceCountdown(endsAtMs: graceEndsAt, now: item.now),
        ],
      ),
    );
  }
}

class _WideStandingsItem extends StatelessWidget {
  const _WideStandingsItem({required this.item, required this.avatarSlot});

  final _StandingsData item;
  final double avatarSlot;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final graceEndsAt = item.graceEndsAtMs;
    final duration = item.player.durationMs;
    return Semantics(
      label: item.semanticsLabel,
      excludeSemantics: true,
      child: Row(
        spacing: 8,
        children: [
          _StandingsAvatar(item: item, slot: avatarSlot),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: item.isMe ? FontWeight.w700 : FontWeight.w500,
                    color: colors.text,
                  ),
                ),
                if (duration != null)
                  // In a narrow column the countdown goes under the time.
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatRaceTime(duration, tenths: true),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (graceEndsAt != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RaceGraceCountdown(endsAtMs: graceEndsAt, now: item.now),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          _StandingsMark(item: item),
        ],
      ),
    );
  }
}

class _StandingsAvatar extends StatelessWidget {
  const _StandingsAvatar({required this.item, this.slot});

  static const double _radius = 13;
  static const double _wreath = _radius * 2 / LaurelWreath.childShare;
  static const double fullSlot = _wreath;
  static const double shortSlot = 30;

  final _StandingsData item;

  /// Width every row keeps for the avatar, so that the names line up; a narrower one leaves the winner's wreath
  /// reaching over the padding instead of pushing the row wider.
  final double? slot;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final width = slot ?? _radius * 2;
    final avatar = Container(
      // The ring is drawn over the avatar's edge, so every avatar has the same size and position.
      foregroundDecoration: item.isMe
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.accent, width: 2),
            )
          : null,
      child: RacePlayerAvatar(player: item.player, radius: _radius, solverLevel: item.solverLevel),
    );
    if (!item.isFirst) {
      return SizedBox(
        width: width,
        child: Center(child: avatar),
      );
    }
    return SizedBox(
      width: width,
      height: width >= _wreath ? _wreath : _radius * 2,
      child: OverflowBox(
        maxWidth: _wreath,
        maxHeight: _wreath,
        child: LaurelWreath(size: _wreath, color: colors.laurel, child: avatar),
      ),
    );
  }
}

class _StandingsMark extends StatelessWidget {
  const _StandingsMark({required this.item});

  final _StandingsData item;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return switch (item.player) {
      RacePlayer(hasFinished: true) => Icon(Icons.sports_score, size: 18, color: colors.text),
      RacePlayer(gaveUp: true) => Icon(Icons.flag_outlined, size: 18, color: colors.textSecondary),
      RacePlayer(online: false) => Icon(Icons.flag, size: 18, color: colors.customConfig),
      _ when !item.isStarted => Icon(Icons.check, size: 18, color: colors.ok),
      _ => Text(
        '${item.player.placed}/${item.totalPieces}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    };
  }
}
