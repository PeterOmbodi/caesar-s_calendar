import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/session_summary.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class SessionList extends StatelessWidget {
  const SessionList({
    super.key,
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
    final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final summaries = [for (final session in sessions) SessionSummary(session, locale: locale)];
    void start() => onStartPuzzleForDay(selectedDate);
    void open(final SessionSummary summary) => _confirmSessionResume(context, summary, onResumeSession);

    return ListView(
      primary: false,
      padding: EdgeInsets.fromLTRB(16, glass ? 0 : 8, 16, 24),
      children: [
        if (glass) _CupertinoStartButton(onPressed: start) else _MaterialStartButton(onPressed: start),
        const SizedBox(height: 8),
        if (summaries.isEmpty)
          _EmptySessions(glass: glass)
        else if (glass)
          _CupertinoSessionGroup(summaries: summaries, onOpen: open)
        else
          for (final summary in summaries) _MaterialSessionCard(summary: summary, onTap: () => open(summary)),
      ],
    );
  }
}

class _MaterialStartButton extends StatelessWidget {
  const _MaterialStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.play_arrow_rounded),
    label: Text(S.current.historyStartPuzzleForDay),
  );
}

class _CupertinoStartButton extends StatelessWidget {
  const _CupertinoStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.play_fill, size: 14),
          const SizedBox(width: 6),
          Flexible(child: Text(S.current.historyStartPuzzleForDay, style: const TextStyle(fontSize: 14))),
        ],
      ),
    ),
  );
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions({required this.glass});

  final bool glass;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(glass ? CupertinoIcons.clock : Icons.history_toggle_off, size: 28, color: colors.textSecondary),
          const SizedBox(height: 8),
          Text(S.current.historyNoSessions, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _ConfigBadge extends StatelessWidget {
  const _ConfigBadge({required this.summary, this.style});

  final SessionSummary summary;
  final TextStyle? style;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final color = summary.isCustomConfig ? colors.customConfig : colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.extension, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            summary.configLabel,
            style: (style ?? const TextStyle()).copyWith(
              color: color,
              fontWeight: summary.isCustomConfig ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialSessionCard extends StatelessWidget {
  const _MaterialSessionCard({required this.summary, required this.onTap});

  final SessionSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          summary.solved ? Icons.check_circle : Icons.timelapse,
          color: summary.solved ? colors.ok : colors.textSecondary,
        ),
        title: Row(
          children: [
            Expanded(child: Text('${summary.statusLabel} • ${summary.difficultyLabel}')),
            const SizedBox(width: 8),
            Flexible(child: _ConfigBadge(summary: summary)),
          ],
        ),
        subtitle: Text('${summary.startedLabel}\n${summary.metricsLabel}'),
      ),
    );
  }
}

class _CupertinoSessionGroup extends StatelessWidget {
  const _CupertinoSessionGroup({required this.summaries, required this.onOpen});

  final List<SessionSummary> summaries;
  final ValueChanged<SessionSummary> onOpen;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: colors.board,
        child: Column(
          children: [
            for (var index = 0; index < summaries.length; index++) ...[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: Divider(height: 1, color: colors.gridLine),
                ),
              _CupertinoSessionRow(summary: summaries[index], onPressed: () => onOpen(summaries[index])),
            ],
          ],
        ),
      ),
    );
  }
}

class _CupertinoSessionRow extends StatelessWidget {
  const _CupertinoSessionRow({required this.summary, required this.onPressed});

  final SessionSummary summary;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final secondary = TextStyle(fontSize: 13, color: colors.textSecondary);
    return CupertinoButton(
      padding: const EdgeInsets.all(16),
      onPressed: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            summary.solved ? CupertinoIcons.check_mark_circled : CupertinoIcons.clock,
            size: 21,
            color: summary.solved ? colors.ok : colors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.statusLabel,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: colors.text),
                ),
                const SizedBox(height: 5),
                Text(summary.startedLabel, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(summary.difficultyLabel, style: secondary),
                    _ConfigBadge(summary: summary, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(summary.metricsLabel, style: secondary),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(CupertinoIcons.chevron_right, size: 15, color: colors.textSecondary),
        ],
      ),
    );
  }
}

Future<void> _confirmSessionResume(
  final BuildContext context,
  final SessionSummary summary,
  final ValueChanged<PuzzleSessionData> onResumeSession,
) async {
  final isSolved = summary.solved;
  final shouldResume = await showAdaptiveDialog<bool>(
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
    onResumeSession(summary.session);
  }
}
