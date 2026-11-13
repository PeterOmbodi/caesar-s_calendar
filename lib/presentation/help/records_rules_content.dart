import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/help/how_to_play_content.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:flutter/material.dart';

HelpSection recordsRulesSection({final bool titled = true}) {
  final medium = PuzzleSessionDifficulty.medium.label;
  final hard = PuzzleSessionDifficulty.hard.label;
  return HelpSection(
    title: titled ? S.current.helpRecordsTitle : null,
    items: [
      HelpItem(icon: Icons.verified_outlined, title: S.current.helpCleanTitle, body: S.current.helpCleanBody),
      HelpItem(
        icon: Icons.leaderboard_outlined,
        title: S.current.leaderboardTitle,
        body: S.current.helpBoardsBody(medium, hard),
      ),
      HelpItem(icon: Icons.timer_outlined, title: S.current.leaderboardToday, body: S.current.helpTodayBody),
      HelpItem(icon: Icons.star_outline, title: S.current.helpPointsTitle, body: S.current.helpPointsBody),
      HelpItem(
        icon: Icons.local_fire_department_outlined,
        title: S.current.leaderboardStreaks,
        body: S.current.helpStreaksBody(medium, hard),
      ),
      HelpItem(
        icon: Icons.local_fire_department,
        title: S.current.historyCountsForRecords,
        body: S.current.helpFlameBody,
      ),
    ],
    footer: S.current.helpRecordsFooter(S.current.accountLeaderboardVisibility),
  );
}

HelpSection achievementsRulesSection({final bool titled = true}) => HelpSection(
  title: titled ? S.current.achievementsTitle : null,
  items: [
    HelpItem(
      icon: Icons.emoji_events_outlined,
      title: S.current.helpAchievementsCountTitle,
      body: S.current.helpAchievementsBody(PuzzleSessionDifficulty.hard.label),
    ),
  ],
);
