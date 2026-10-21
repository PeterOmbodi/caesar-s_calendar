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
      startedLabel = _startedLabel(session.startedAt, locale);

  final PuzzleSessionData session;
  final bool solved;
  final bool isCustomConfig;
  final String startedLabel;

  String get statusLabel => solved ? S.current.historySolved : S.current.historyInProgress;

  String get difficultyLabel => '${session.difficulty.stars} ${session.difficulty.label}';

  String get configLabel => isCustomConfig ? S.current.historyConfigCustom : S.current.historyConfigStandard;

  int get hintsUsed => session.moveHistory.whereType<HintMove>().length;

  String get metricsLabel =>
      '${S.current.historyMoves}: ${session.moveIndex} · '
      '${S.current.hintUsed}: $hintsUsed · '
      '${S.current.historyDuration}: ${formatDuration(durationMs(session))}';

  static String _startedLabel(final int startedAt, final String locale) {
    final start = DateTime.fromMillisecondsSinceEpoch(startedAt);
    return '${DateFormat.yMMMd(locale).format(start)} · ${DateFormat.Hm(locale).format(start)}';
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
