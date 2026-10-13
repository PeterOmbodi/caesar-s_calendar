import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/bloc/history_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_overview.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/session_list.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/statistics_tab.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryContentLayout extends StatelessWidget {
  const HistoryContentLayout({
    super.key,
    required this.state,
    required this.activeTab,
    required this.onTabChanged,
    required this.onStartPuzzle,
    required this.onResumeSession,
    required this.centerSelectionRequest,
  });

  final HistoryState state;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<DateTime> onStartPuzzle;
  final ValueChanged<PuzzleSessionData> onResumeSession;
  final int centerSelectionRequest;

  @override
  Widget build(final BuildContext context) {
    final family = ScreenSpec.of(context).family;
    final glass = family == ChromeFamily.glass;
    final colors = GameColors.of(context);
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final tablet = constraints.maxWidth >= 720;
        final overview = HistoryOverview(
          selectedDate: state.selectedDate,
          rangeStart: state.rangeStart,
          rangeEnd: state.rangeEnd,
          stats: state.calendarStats,
          onDateTap: context.read<HistoryCubit>().selectDate,
          centerSelectionRequest: centerSelectionRequest,
        );
        final sessions = _HistorySessions(
          state: state,
          glass: glass,
          onStartPuzzle: onStartPuzzle,
          onResumeSession: onResumeSession,
        );
        const statistics = StatisticsTab();
        final content = tablet
            ? Row(
                children: [
                  Expanded(child: sessions),
                  VerticalDivider(width: 1, color: colors.gridLine),
                  Expanded(child: statistics),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _HistoryTabSelector(value: activeTab, onChanged: onTabChanged, glass: glass),
                  ),
                  Expanded(
                    child: IndexedStack(index: activeTab, children: [sessions, statistics]),
                  ),
                ],
              );
        return Column(
          children: [
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.errorMessage!, style: TextStyle(color: colors.bad)),
              ),
            Expanded(
              child: Column(
                children: [
                  ConstrainedBox(
                    key: tablet ? const ValueKey('history-tablet-overview') : null,
                    constraints: BoxConstraints(maxHeight: constraints.maxHeight * .38),
                    child: SingleChildScrollView(child: overview),
                  ),
                  Expanded(key: tablet ? const ValueKey('history-tablet-content') : null, child: content),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistorySessions extends StatelessWidget {
  const _HistorySessions({
    required this.state,
    required this.glass,
    required this.onStartPuzzle,
    required this.onResumeSession,
  });

  final HistoryState state;
  final bool glass;
  final ValueChanged<DateTime> onStartPuzzle;
  final ValueChanged<PuzzleSessionData> onResumeSession;

  @override
  Widget build(final BuildContext context) {
    if (state.isSessionsLoading) {
      return Center(child: glass ? const CupertinoActivityIndicator() : const CircularProgressIndicator());
    }
    return SessionList(
      sessions: state.sessions,
      selectedDate: state.selectedDate,
      onStartPuzzleForDay: onStartPuzzle,
      onResumeSession: onResumeSession,
    );
  }
}

class _HistoryTabSelector extends StatelessWidget {
  const _HistoryTabSelector({required this.value, required this.onChanged, required this.glass});

  final int value;
  final ValueChanged<int> onChanged;
  final bool glass;

  @override
  Widget build(final BuildContext context) => glass
      ? _GlassHistoryTabSelector(value: value, onChanged: onChanged)
      : _MaterialHistoryTabSelector(value: value, onChanged: onChanged);
}

class _GlassHistoryTabSelector extends StatelessWidget {
  const _GlassHistoryTabSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoSlidingSegmentedControl<int>(
      groupValue: value,
      onValueChanged: (final next) {
        if (next != null) onChanged(next);
      },
      children: {0: Text(S.current.historyTabSessions), 1: Text(S.current.historyTabStatistics)},
    ),
  );
}

class _MaterialHistoryTabSelector extends StatelessWidget {
  const _MaterialHistoryTabSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(final BuildContext context) => SegmentedButton<int>(
    showSelectedIcon: false,
    segments: [
      ButtonSegment(value: 0, label: Text(S.current.historyTabSessions)),
      ButtonSegment(value: 1, label: Text(S.current.historyTabStatistics)),
    ],
    selected: {value},
    onSelectionChanged: (final values) => onChanged(values.first),
  );
}
