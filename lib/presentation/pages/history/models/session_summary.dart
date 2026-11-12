import 'package:caesar_puzzle/application/leaderboard/leaderboard_scoring.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:intl/intl.dart';

class SessionSummary {
  SessionSummary(this.session, {required final String locale})
    : solved = session.status == PuzzleSessionStatus.solved,
      isCustomConfig = session.configId != StandardPuzzleConfig.id,
      timeLabel = _timeLabel(session, locale);

  final PuzzleSessionData session;
  final bool solved;
  final bool isCustomConfig;
  final String timeLabel;

  bool get countsForRecords => LeaderboardScoring.countsForRecords(session);

  String get statusLabel => solved ? S.current.historySolved : S.current.historyInProgress;

  String get difficultyLabel => '${session.difficulty.stars} ${session.difficulty.label}';

  String get configLabel => isCustomConfig ? S.current.historyConfigCustom : S.current.historyConfigStandard;

  int get hintsUsed => session.moveHistory.whereType<HintMove>().length;

  String get metricsLabel =>
      '${S.current.historyMoves}: ${session.moveIndex} · '
      '${S.current.hintUsed}: $hintsUsed · '
      '${S.current.historyDuration}: ${formatDuration(durationMs(session))}';

  static String _timeLabel(final PuzzleSessionData session, final String locale) {
    final start = DateTime.fromMillisecondsSinceEpoch(session.startedAt);
    final startLabel = '${DateFormat.yMMMd(locale).format(start)} · ${DateFormat.Hm(locale).format(start)}';
    final completedAt = session.completedAt;
    if (completedAt == null) {
      return startLabel;
    }
    final end = DateTime.fromMillisecondsSinceEpoch(completedAt);
    final sameDay = end.year == start.year && end.month == start.month && end.day == start.day;
    final endLabel = sameDay
        ? DateFormat.Hm(locale).format(end)
        : '${DateFormat.MMMd(locale).format(end)} · ${DateFormat.Hm(locale).format(end)}';
    return '$startLabel – $endLabel';
  }

  /// Includes the segment that was still running when the session was saved.
  static int durationMs(final PuzzleSessionData session) {
    final segmentEndMs = session.completedAt ?? session.updatedAt;
    final segmentStartMs = session.lastResumedAt ?? (session.activeElapsedMs == 0 ? session.firstMoveAt : null);
    if (segmentStartMs == null) {
      return session.activeElapsedMs;
    }
    final currentSegmentMs = (segmentEndMs - segmentStartMs).clamp(0, 1 << 31).toInt();
    return session.activeElapsedMs + currentSegmentMs;
  }

  static String formatDuration(final int milliseconds) {
    final totalSeconds = (milliseconds / 1000).round();
    final minutes = '${totalSeconds ~/ 60}'.padLeft(2, '0');
    final seconds = '${totalSeconds % 60}'.padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
