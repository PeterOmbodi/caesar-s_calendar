import 'dart:ui';

import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/pages/history/bloc/history_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/history_screen_result.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/date_selector.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/session_list.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/statistics_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  Widget build(final BuildContext context) => BlocProvider(
    create: (_) => HistoryCubit(historyUseCase: getIt<PuzzleHistoryUseCase>())..initialize(initialDate: initialDate),
    child: const _HistoryView(),
  );
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) {
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _HistoryAppBarIconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(S.current.historyTitle),
          actions: [
            _HistoryAppBarIconButton(
              tooltip: S.current.historyPickDate,
              icon: Icons.calendar_month_outlined,
              onPressed: () => _pickDate(context, state.selectedDate),
            ),
          ],
        ),
        body: SafeArea(
          child: isLandscape
              ? _HistoryLandscapeBody(tabController: _tabController)
              : _HistoryPortraitBody(tabController: _tabController),
        ),
      );
    },
  );

  Future<void> _pickDate(final BuildContext context, final DateTime selectedDate) async {
    final historyCubit = context.read<HistoryCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) {
      return;
    }
    historyCubit.selectDate(picked);
  }
}

class _HistoryPortraitBody extends StatelessWidget {
  const _HistoryPortraitBody({required this.tabController});

  final TabController tabController;

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) => Column(
      children: [
        const SizedBox(height: 8),
        DateSelector(
          selectedDate: state.selectedDate,
          rangeStart: state.rangeStart,
          rangeEnd: state.rangeEnd,
          stats: state.calendarStats,
          onDateTap: context.read<HistoryCubit>().selectDate,
        ),
        const SizedBox(height: 8),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        _HistoryTabBar(controller: tabController),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              state.isSessionsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SessionList(
                sessions: state.sessions,
                selectedDate: state.selectedDate,
                onStartPuzzleForDay: (final date) =>
                    Navigator.of(context).pop(HistoryScreenResult.startPuzzleForDate(date)),
                onResumeSession: (final session) =>
                    Navigator.of(context).pop(HistoryScreenResult.resumeSession(session)),
              ),
              const StatisticsTab(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryLandscapeBody extends StatelessWidget {
  const _HistoryLandscapeBody({required this.tabController});

  final TabController tabController;

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) => NestedScrollView(
      headerSliverBuilder: (final context, final innerBoxIsScrolled) => [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _DateSelectorHeaderDelegate(
            selectedDate: state.selectedDate,
            rangeStart: state.rangeStart,
            rangeEnd: state.rangeEnd,
            stats: state.calendarStats,
            isCalendarLoading: state.isCalendarLoading,
            onDateTap: context.read<HistoryCubit>().selectDate,
          ),
        ),
        if (state.errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        SliverPersistentHeader(pinned: true, delegate: _TabBarHeaderDelegate(controller: tabController)),
      ],
      body: TabBarView(
        controller: tabController,
        children: [
          state.isSessionsLoading
              ? const Center(child: CircularProgressIndicator())
              : SessionList(
            sessions: state.sessions,
            selectedDate: state.selectedDate,
            onStartPuzzleForDay: (final date) =>
                Navigator.of(context).pop(HistoryScreenResult.startPuzzleForDate(date)),
            onResumeSession: (final session) =>
                Navigator.of(context).pop(HistoryScreenResult.resumeSession(session)),
          ),
          const StatisticsTab(),
        ],
      ),
    ),
  );
}

class _HistoryTabBar extends StatelessWidget {
  const _HistoryTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(final BuildContext context) => TabBar(
    controller: controller,
    tabs: [
      Tab(text: S.current.historyTabSessions),
      Tab(text: S.current.historyTabStatistics),
    ],
  );
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabBarHeaderDelegate({required this.controller});

  final TabController controller;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(final BuildContext context, final double shrinkOffset, final bool overlapsContent) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: _HistoryTabBar(controller: controller),
  );

  @override
  bool shouldRebuild(final _TabBarHeaderDelegate oldDelegate) => controller != oldDelegate.controller;
}

class _HistoryAppBarIconButton extends StatelessWidget {
  const _HistoryAppBarIconButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(foregroundColor: foreground, backgroundColor: Colors.transparent, elevation: 0),
      icon: Icon(icon),
    );
  }
}

class _DateSelectorHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DateSelectorHeaderDelegate({
    required this.selectedDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.stats,
    required this.isCalendarLoading,
    required this.onDateTap,
  });

  final DateTime selectedDate;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<CalendarDayStats> stats;
  final bool isCalendarLoading;
  final ValueChanged<DateTime> onDateTap;

  @override
  double get minExtent => 142;

  @override
  double get maxExtent => 246;

  @override
  Widget build(final BuildContext context, final double shrinkOffset, final bool overlapsContent) {
    final total = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (shrinkOffset / total).clamp(0.0, 1.0);
    final currentExtent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DateSelector(
          selectedDate: selectedDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          stats: stats,
          onDateTap: onDateTap,
          cellSize: lerpDouble(24, 14, t) ?? 24,
          columnGap: lerpDouble(4, 2, t) ?? 4,
          rowGap: lerpDouble(4, 2, t) ?? 4,
          topDateGap: lerpDouble(6, 2, t) ?? 6,
          monthsToGridGap: lerpDouble(4, 2, t) ?? 4,
          showMonthLabels: currentExtent >= 218,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(final _DateSelectorHeaderDelegate oldDelegate) =>
      selectedDate != oldDelegate.selectedDate ||
          rangeStart != oldDelegate.rangeStart ||
          rangeEnd != oldDelegate.rangeEnd ||
          isCalendarLoading != oldDelegate.isCalendarLoading ||
          stats != oldDelegate.stats;
}