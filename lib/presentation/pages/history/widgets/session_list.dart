import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';

class SessionList extends StatelessWidget {
  const SessionList({
    super.key,
    required this.sessions,
    required this.selectedDate,
    required this.onStartPuzzleForDay,
    required this.onResumeSession,
    this.primaryScroll = true,
  });

  final List<PuzzleSessionData> sessions;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onStartPuzzleForDay;
  final ValueChanged<PuzzleSessionData> onResumeSession;
  final bool primaryScroll;

  @override
  Widget build(final BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off, size: 28),
            const SizedBox(height: 8),
            Text(S.current.historyNoSessions),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => onStartPuzzleForDay(selectedDate),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(S.current.historyStartPuzzleForDay),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      shrinkWrap: !primaryScroll,
      physics: primaryScroll ? null : const NeverScrollableScrollPhysics(),
      itemCount: sessions.length + 1,
      separatorBuilder: (final _, final __) => const SizedBox(height: 8),
      itemBuilder: (final context, final index) {
        if (index == 0) {
          return FilledButton.icon(
            onPressed: () => onStartPuzzleForDay(selectedDate),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(S.current.historyStartPuzzleForDay),
          );
        }

        final session = sessions[index - 1];
        final start = DateTime.fromMillisecondsSinceEpoch(session.startedAt);
        final isSolved = session.status == PuzzleSessionStatus.solved;
        final statusLabel = isSolved ? S.current.historySolved : S.current.historyInProgress;
        final durationMs = _displayDurationMs(session);
        final usedHints = session.moveHistory.whereType<HintMove>().length;
        final subtitle =
            '${S.current.historyMoves}: ${session.moveIndex}  |  ${S.current.hintUsed}: $usedHints  |  ${S.current.historyDuration}: ${_formatDuration(durationMs)}';
        final dateLabel = DateFormat.yMMMd().format(session.puzzleDate);
        final difficultyLabel = _difficultyLabel(session.difficulty);
        final difficultyStars = _difficultyStars(session.difficulty);
        final isCustomConfig = _isCustomConfig(session);
        final configLabel = _configLabel(session);
        final configColor =
            isCustomConfig ? AppColors.current.customConfigAccent : null;
        return Card(
          child: ListTile(
            onTap: () => _confirmResumeSession(context, session),
            leading: Icon(isSolved ? Icons.check_circle : Icons.timelapse, color: isSolved ? Colors.green : Colors.red),
            title: Row(
              children: [
                Expanded(child: Text('$statusLabel • $difficultyStars $difficultyLabel')),
                const SizedBox(width: 8),
                Icon(Icons.extension, size: 16, color: configColor),
                const SizedBox(width: 4),
                Text(
                  configLabel,
                  style: isCustomConfig
                      ? TextStyle(
                          color: configColor,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
              ],
            ),
            subtitle: Text(
              '$dateLabel • ${DateFormat.Hm().format(start)}\n'
              '$subtitle',
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(final int milliseconds) {
    final totalSeconds = (milliseconds / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesText = '$minutes'.padLeft(2, '0');
    final secondsText = '$seconds'.padLeft(2, '0');
    return '$minutesText:$secondsText';
  }

  int _displayDurationMs(final PuzzleSessionData session) {
    final segmentEndMs = session.completedAt ?? session.updatedAt;
    final segmentStartMs =
        session.lastResumedAt ?? (session.activeElapsedMs == 0 ? session.firstMoveAt : null);
    if (segmentStartMs == null) {
      return session.activeElapsedMs;
    }

    final currentSegmentMs = (segmentEndMs - segmentStartMs).clamp(0, 1 << 31).toInt();
    return session.activeElapsedMs + currentSegmentMs;
  }

  String _difficultyLabel(final PuzzleSessionDifficulty difficulty) =>
      difficulty == PuzzleSessionDifficulty.hard
      ? S.current.historyDifficultyHard
      : S.current.historyDifficultyEasy;

  String _difficultyStars(final PuzzleSessionDifficulty difficulty) =>
      difficulty == PuzzleSessionDifficulty.hard ? '★★' : '★';

  String _configLabel(final PuzzleSessionData session) =>
      _isCustomConfig(session) ? S.current.historyConfigCustom : S.current.historyConfigStandard;

  bool _isCustomConfig(final PuzzleSessionData session) => session.configId != StandardPuzzleConfig.id;

  Future<void> _confirmResumeSession(final BuildContext context, final PuzzleSessionData session) async {
    final isSolved = session.status == PuzzleSessionStatus.solved;
    final shouldResume = await showDialog<bool>(
      context: context,
      builder: (final dialogContext) => PlatformAlertDialog(
        title: Text(isSolved ? S.current.historyOpenSolvedSessionTitle : S.current.historyResumeSessionTitle),
        content: Text(isSolved ? S.current.historyOpenSolvedSessionContent : S.current.historyResumeSessionContent),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.current.historySessionDialogCancel),
          ),
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isSolved ? S.current.historySessionDialogOpen : S.current.historySessionDialogResume),
          ),
        ],
      ),
    );

    if (shouldResume == true && context.mounted) {
      onResumeSession(session);
    }
  }
}
