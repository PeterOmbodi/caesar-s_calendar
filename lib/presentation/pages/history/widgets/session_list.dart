import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_session_difficulty_x.dart';
import 'package:flutter/cupertino.dart';
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
    if (ScreenSpec.of(context).family == ChromeFamily.glass) {
      return _AppleSessionList(
        sessions: sessions,
        selectedDate: selectedDate,
        onStartPuzzleForDay: onStartPuzzleForDay,
        onResumeSession: onResumeSession,
      );
    }
    final dateFormatter = DateFormat.yMMMd();
    final timeFormatter = DateFormat.Hm();
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
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
        final durationMs = _displaySessionDurationMs(session);
        final usedHints = session.moveHistory.whereType<HintMove>().length;
        final subtitle =
            '${S.current.historyMoves}: ${session.moveIndex}  |  ${S.current.hintUsed}: $usedHints  |  ${S.current.historyDuration}: ${_formatSessionDuration(durationMs)}';
        final dateLabel = dateFormatter.format(session.puzzleDate);
        final isCustomConfig = _isCustomSessionConfig(session);
        final configLabel = _sessionConfigLabel(session);
        final configColor = isCustomConfig ? AppColors.current.customConfigAccent : null;
        return Card(
          child: ListTile(
            onTap: () => _confirmSessionResume(context, session, onResumeSession),
            leading: Icon(isSolved ? Icons.check_circle : Icons.timelapse, color: isSolved ? Colors.green : Colors.red),
            title: Row(
              children: [
                Expanded(child: Text('$statusLabel • ${session.difficulty.stars} ${session.difficulty.label}')),
                const SizedBox(width: 8),
                Icon(Icons.extension, size: 16, color: configColor),
                const SizedBox(width: 4),
                Text(
                  configLabel,
                  style: isCustomConfig ? TextStyle(color: configColor, fontWeight: FontWeight.w600) : null,
                ),
              ],
            ),
            subtitle: Text(
              '$dateLabel • ${timeFormatter.format(start)}\n'
              '$subtitle',
            ),
          ),
        );
      },
    );
  }
}

class _AppleSessionList extends StatelessWidget {
  const _AppleSessionList({
    required this.sessions,
    required this.selectedDate,
    required this.onStartPuzzleForDay,
    required this.onResumeSession,
  });

  final List<PuzzleSessionData> sessions;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onStartPuzzleForDay;
  final ValueChanged<PuzzleSessionData> onResumeSession;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            onPressed: () => onStartPuzzleForDay(selectedDate),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.play_fill, size: 14),
                const SizedBox(width: 6),
                Flexible(child: Text(S.current.historyStartPuzzleForDay, style: const TextStyle(fontSize: 14))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(CupertinoIcons.clock, size: 28, color: colors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  S.current.historyNoSessions,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
              color: colors.board,
              child: Column(
                children: [
                  for (var index = 0; index < sessions.length; index++) ...[
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 46),
                        child: Divider(height: 1, color: colors.gridLine),
                      ),
                    Builder(
                      builder: (final context) {
                        final session = sessions[index];
                        final solved = session.status == PuzzleSessionStatus.solved;
                        final start = DateTime.fromMillisecondsSinceEpoch(session.startedAt);
                        return CupertinoButton(
                          padding: const EdgeInsets.all(16),
                          onPressed: () => _confirmSessionResume(context, session, onResumeSession),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                solved ? CupertinoIcons.check_mark_circled : CupertinoIcons.clock,
                                size: 21,
                                color: solved ? colors.ok : colors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      solved ? S.current.historySolved : S.current.historyInProgress,
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: colors.text),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${DateFormat.yMMMd(locale).format(start)} · ${DateFormat.Hm(locale).format(start)}',
                                      style: TextStyle(fontSize: 14, color: colors.textSecondary),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          '${session.difficulty.stars} ${session.difficulty.label}',
                                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.extension,
                                              size: 16,
                                              color: _isCustomSessionConfig(session)
                                                  ? colors.customConfig
                                                  : colors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _sessionConfigLabel(session),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _isCustomSessionConfig(session)
                                                      ? colors.customConfig
                                                      : colors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${S.current.historyMoves}: ${session.moveIndex} · '
                                      '${S.current.hintUsed}: ${session.moveHistory.whereType<HintMove>().length} · '
                                      '${S.current.historyDuration}: ${_formatSessionDuration(_displaySessionDurationMs(session))}',
                                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(CupertinoIcons.chevron_right, size: 15, color: colors.textSecondary),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _formatSessionDuration(final int milliseconds) {
  final totalSeconds = (milliseconds / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final minutesText = '$minutes'.padLeft(2, '0');
  final secondsText = '$seconds'.padLeft(2, '0');
  return '$minutesText:$secondsText';
}

int _displaySessionDurationMs(final PuzzleSessionData session) {
  final segmentEndMs = session.completedAt ?? session.updatedAt;
  final segmentStartMs = session.lastResumedAt ?? (session.activeElapsedMs == 0 ? session.firstMoveAt : null);
  if (segmentStartMs == null) {
    return session.activeElapsedMs;
  }

  final currentSegmentMs = (segmentEndMs - segmentStartMs).clamp(0, 1 << 31).toInt();
  return session.activeElapsedMs + currentSegmentMs;
}

String _sessionConfigLabel(final PuzzleSessionData session) =>
    _isCustomSessionConfig(session) ? S.current.historyConfigCustom : S.current.historyConfigStandard;

bool _isCustomSessionConfig(final PuzzleSessionData session) => session.configId != StandardPuzzleConfig.id;

Future<void> _confirmSessionResume(
  final BuildContext context,
  final PuzzleSessionData session,
  final ValueChanged<PuzzleSessionData> onResumeSession,
) async {
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
