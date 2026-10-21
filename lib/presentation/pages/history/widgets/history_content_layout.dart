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

  static const double _wideMinWidth = 720;
  static const double _sidebarMaxHeight = 600;

  final HistoryState state;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<DateTime> onStartPuzzle;
  final ValueChanged<PuzzleSessionData> onResumeSession;
  final int centerSelectionRequest;

  @override
  Widget build(final BuildContext context) {
    final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
    final colors = GameColors.of(context);
    return LayoutBuilder(
      builder: (final context, final constraints) {
        // Phones in landscape; tablets keep the overview on top.
        final landscape = constraints.maxWidth > constraints.maxHeight && constraints.maxHeight < _sidebarMaxHeight;
        final wide = !landscape && constraints.maxWidth >= _wideMinWidth;
        HistoryOverview overview({final bool sidebar = false, final double cellSize = 24}) => HistoryOverview(
          selectedDate: state.selectedDate,
          rangeStart: state.rangeStart,
          rangeEnd: state.rangeEnd,
          stats: state.calendarStats,
          onDateTap: context.read<HistoryCubit>().selectDate,
          centerSelectionRequest: centerSelectionRequest,
          sidebar: sidebar,
          cellSize: cellSize,
        );
        final sessions = _HistorySessions(
          state: state,
          onStartPuzzle: onStartPuzzle,
          onResumeSession: onResumeSession,
        );
        const statistics = StatisticsTab();
        final tabs = _HistoryTabs(
          glass: glass,
          activeTab: activeTab,
          onTabChanged: onTabChanged,
          children: [sessions, statistics],
        );
        final Widget body;
        if (landscape) {
          // Seven heatmap rows fit the height without scrolling.
          final cellSize = ((constraints.maxHeight - 160) / 7).clamp(16.0, 40.0);
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                key: const ValueKey('history-landscape-overview'),
                child: SingleChildScrollView(child: overview(sidebar: true, cellSize: cellSize)),
              ),
              Expanded(
                key: const ValueKey('history-landscape-content'),
                child: Padding(padding: const EdgeInsets.only(top: 8), child: tabs),
              ),
            ],
          );
        } else {
          body = Column(
            children: [
              ConstrainedBox(
                key: wide ? const ValueKey('history-tablet-overview') : null,
                constraints: BoxConstraints(maxHeight: constraints.maxHeight * .38),
                child: SingleChildScrollView(child: overview()),
              ),
              Expanded(
                key: wide ? const ValueKey('history-tablet-content') : null,
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: sessions),
                          VerticalDivider(width: 1, color: colors.gridLine),
                          const Expanded(child: statistics),
                        ],
                      )
                    : tabs,
              ),
            ],
          );
        }
        return Column(
          children: [
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.errorMessage!, style: TextStyle(color: colors.bad)),
              ),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

class _HistorySessions extends StatelessWidget {
  const _HistorySessions({
    required this.state,
    required this.onStartPuzzle,
    required this.onResumeSession,
  });

  final HistoryState state;
  final ValueChanged<DateTime> onStartPuzzle;
  final ValueChanged<PuzzleSessionData> onResumeSession;

  @override
  Widget build(final BuildContext context) {
    if (state.isSessionsLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return SessionList(
      sessions: state.sessions,
      selectedDate: state.selectedDate,
      onStartPuzzleForDay: onStartPuzzle,
      onResumeSession: onResumeSession,
    );
  }
}

/// Sessions and statistics, one at a time.
class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({
    required this.glass,
    required this.activeTab,
    required this.onTabChanged,
    required this.children,
  });

  final bool glass;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    if (!glass) {
      return _MaterialHistoryTabs(activeTab: activeTab, onTabChanged: onTabChanged, children: children);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: activeTab,
              onValueChanged: (final next) {
                if (next != null) onTabChanged(next);
              },
              children: {0: Text(S.current.historyTabSessions), 1: Text(S.current.historyTabStatistics)},
            ),
          ),
        ),
        Expanded(child: IndexedStack(index: activeTab, children: children)),
      ],
    );
  }
}

class _MaterialHistoryTabs extends StatefulWidget {
  const _MaterialHistoryTabs({required this.activeTab, required this.onTabChanged, required this.children});

  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final List<Widget> children;

  @override
  State<_MaterialHistoryTabs> createState() => _MaterialHistoryTabsState();
}

class _MaterialHistoryTabsState extends State<_MaterialHistoryTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.children.length,
    initialIndex: widget.activeTab,
    vsync: this,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (!_controller.indexIsChanging && _controller.index != widget.activeTab) {
      widget.onTabChanged(_controller.index);
    }
  }

  @override
  void didUpdateWidget(final _MaterialHistoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTab != _controller.index) {
      _controller.index = widget.activeTab;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Column(
    children: [
      TabBar(
        controller: _controller,
        tabs: [
          Tab(text: S.current.historyTabSessions),
          Tab(text: S.current.historyTabStatistics),
        ],
      ),
      Expanded(child: TabBarView(controller: _controller, children: widget.children)),
    ],
  );
}
