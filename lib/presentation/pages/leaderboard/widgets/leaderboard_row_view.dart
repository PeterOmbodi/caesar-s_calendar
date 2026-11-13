import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/session_summary.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/bloc/leaderboard_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

class LeaderboardRowView extends StatelessWidget {
  const LeaderboardRowView({super.key, required this.row});

  final LeaderboardRow row;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final palette = colors.pieces.values.toList();
    final (primary, secondary) = switch (row.value) {
      TimeValue(:final timeMs, :final extraSolutions) => (
        SessionSummary.formatDuration(timeMs),
        extraSolutions > 0 ? '+$extraSolutions' : null,
      ),
      PointsValue(:final points, :final days) => ('$points', '$days'),
      StreakValue(:final best, :final current) => ('$best', current > 0 ? '$current' : null),
    };
    const figures = [FontFeature.tabularFigures()];
    return Semantics(
      label: _semanticLabel,
      excludeSemantics: true,
      child: ColoredBox(
        color: row.isMe ? colors.accent.withValues(alpha: 0.12) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 16, 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${row.rank}',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 15, color: colors.textSecondary, fontFeatures: figures),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 14,
                backgroundColor: palette.isEmpty ? colors.accent : palette[row.colorIndex % palette.length],
                child: Text(
                  row.nickname.isEmpty ? '?' : String.fromCharCode(row.nickname.runes.first).toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: row.nickname,
                    children: [
                      if (row.isMe)
                        TextSpan(
                          text: ' · ${S.current.leaderboardYou}',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: row.isMe ? FontWeight.w600 : FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    primary,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                      fontFeatures: figures,
                    ),
                  ),
                  if (secondary != null)
                    Text(
                      secondary,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFeatures: figures),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _semanticLabel => [
    S.current.leaderboardRowPlace(row.rank),
    row.nickname,
    if (row.isMe) S.current.leaderboardYou,
    switch (row.value) {
      TimeValue(:final timeMs, :final extraSolutions) => S.current.leaderboardRowTime(
        SessionSummary.formatDuration(timeMs),
        extraSolutions,
      ),
      PointsValue(:final points, :final days) => S.current.leaderboardRowPoints(points, days),
      StreakValue(:final best, :final current) => S.current.leaderboardRowStreaks(best, current),
    },
  ].join(', ');
}
