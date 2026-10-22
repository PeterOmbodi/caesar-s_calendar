import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/models/period_stats.dart';
import 'package:caesar_puzzle/application/models/stats_period.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/bloc/history_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) {
      final cubit = context.read<HistoryCubit>();
      final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
      final referenceDate = PeriodRangeResolver.referenceDateFor(state.selectedDate);
      final rangeLabel = _periodRangeLabel(context, state.statsPeriod, referenceDate);
      final tile = _StatTile(
        stats: state.periodStats,
        period: state.statsPeriod,
        referenceDate: referenceDate,
        glass: glass,
      );
      return ListView(
        primary: false,
        padding: EdgeInsets.fromLTRB(16, glass ? 8 : 12, 16, 24),
        children: [
          if (glass)
            _CupertinoFilters(
              yearScope: state.statsYearScope,
              period: state.statsPeriod,
              onYearScope: cubit.setStatsYearScope,
              onPeriod: cubit.setStatsPeriod,
            )
          else
            _MaterialFilters(
              yearScope: state.statsYearScope,
              period: state.statsPeriod,
              onYearScope: cubit.setStatsYearScope,
              onPeriod: cubit.setStatsPeriod,
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: glass ? 12 : 0, vertical: glass ? 14 : 8),
            child: Text(
              rangeLabel ?? '',
              style: TextStyle(fontSize: glass ? 13 : 12, color: GameColors.of(context).textSecondary),
            ),
          ),
          if (state.isPeriodStatsLoading)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (glass)
            _GlassCardTheme(child: tile)
          else
            tile,
        ],
      );
    },
  );

  String? _periodRangeLabel(final BuildContext context, final StatsPeriod period, final DateTime referenceDate) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    switch (period) {
      case StatsPeriod.week:
        final weekRange = PeriodRangeResolver.weekRange(referenceDate);
        return '${DateFormat.MMMd(locale).format(weekRange.start)} – ${DateFormat.MMMd(locale).format(weekRange.end)}';
      case StatsPeriod.month:
        return DateFormat.MMMM(locale).format(referenceDate);
      case StatsPeriod.year:
        return null;
    }
  }
}

class _MaterialFilters extends StatelessWidget {
  const _MaterialFilters({
    required this.yearScope,
    required this.period,
    required this.onYearScope,
    required this.onPeriod,
  });

  final StatsYearScope yearScope;
  final StatsPeriod period;
  final ValueChanged<StatsYearScope> onYearScope;
  final ValueChanged<StatsPeriod> onPeriod;

  @override
  Widget build(final BuildContext context) => Column(
    children: [
      _LabeledChipRow(
        label: S.current.historyStatsSessionsFromLabel,
        child: _YearScopeChips(selected: yearScope, onSelected: onYearScope),
      ),
      const SizedBox(height: 12),
      _LabeledChipRow(
        label: S.current.historyStatsPeriodLabel,
        child: _PeriodChips(selected: period, onSelected: onPeriod),
      ),
    ],
  );
}

class _CupertinoFilters extends StatelessWidget {
  const _CupertinoFilters({
    required this.yearScope,
    required this.period,
    required this.onYearScope,
    required this.onPeriod,
  });

  final StatsYearScope yearScope;
  final StatsPeriod period;
  final ValueChanged<StatsYearScope> onYearScope;
  final ValueChanged<StatsPeriod> onPeriod;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final labelStyle = TextStyle(fontSize: 13, color: colors.textSecondary);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.current.historyStatsSessionsFromLabel, style: labelStyle),
          const SizedBox(height: 8),
          AppSegmentedControl<StatsYearScope>(
            value: yearScope,
            onChanged: onYearScope,
            segments: {
              StatsYearScope.currentYear: S.current.historyYearScopeCurrent,
              StatsYearScope.allYears: S.current.historyYearScopeAll,
            },
          ),
          const SizedBox(height: 16),
          Text(S.current.historyStatsPeriodLabel, style: labelStyle),
          const SizedBox(height: 8),
          AppSegmentedControl<StatsPeriod>(
            value: period,
            onChanged: onPeriod,
            segments: {
              StatsPeriod.week: S.current.historyPeriodWeek,
              StatsPeriod.month: S.current.historyPeriodMonth,
              StatsPeriod.year: S.current.historyPeriodYear,
            },
          ),
        ],
      ),
    );
  }
}

class _GlassCardTheme extends StatelessWidget {
  const _GlassCardTheme({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        cardTheme: CardThemeData(
          color: colors.board,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: colors.active,
          surfaceContainerHigh: colors.gridLine,
          onSurface: colors.text,
        ),
        textTheme: theme.textTheme.apply(bodyColor: colors.text, displayColor: colors.text),
      ),
      child: child,
    );
  }
}

class _LabeledChipRow extends StatelessWidget {
  const _LabeledChipRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(final BuildContext context) => Row(
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(width: 12),
      Expanded(child: child),
    ],
  );
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.selected, required this.onSelected});

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onSelected;

  @override
  Widget build(final BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    children: [
      ChoiceChip(
        label: Text(S.current.historyPeriodWeek),
        selected: selected == StatsPeriod.week,
        onSelected: (_) => onSelected(StatsPeriod.week),
      ),
      ChoiceChip(
        label: Text(S.current.historyPeriodMonth),
        selected: selected == StatsPeriod.month,
        onSelected: (_) => onSelected(StatsPeriod.month),
      ),
      ChoiceChip(
        label: Text(S.current.historyPeriodYear),
        selected: selected == StatsPeriod.year,
        onSelected: (_) => onSelected(StatsPeriod.year),
      ),
    ],
  );
}

class _YearScopeChips extends StatelessWidget {
  const _YearScopeChips({required this.selected, required this.onSelected});

  final StatsYearScope selected;
  final ValueChanged<StatsYearScope> onSelected;

  @override
  Widget build(final BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    children: [
      ChoiceChip(
        label: Text(S.current.historyYearScopeCurrent),
        selected: selected == StatsYearScope.currentYear,
        onSelected: (_) => onSelected(StatsYearScope.currentYear),
      ),
      ChoiceChip(
        label: Text(S.current.historyYearScopeAll),
        selected: selected == StatsYearScope.allYears,
        onSelected: (_) => onSelected(StatsYearScope.allYears),
      ),
    ],
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stats, required this.period, required this.referenceDate, required this.glass});

  final PeriodStats stats;
  final StatsPeriod period;
  final DateTime referenceDate;
  final bool glass;

  int get _totalDaysInPeriod {
    final range = switch (period) {
      StatsPeriod.week => PeriodRangeResolver.weekRange(referenceDate),
      StatsPeriod.month => PeriodRangeResolver.monthRange(referenceDate),
      StatsPeriod.year => PeriodRangeResolver.yearRange(referenceDate.year),
    };
    return range.dayCount;
  }

  @override
  Widget build(final BuildContext context) {
    final totalDays = _totalDaysInPeriod;
    final daysCoverage = totalDays == 0 ? 0.0 : (stats.solvedDays / totalDays).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ProgressStat(
                    value: stats.progress,
                    label: '${(stats.progress * 100).round()}%',
                    caption: S.current.historyStatsProgressCaption,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ProgressStat(
                    value: daysCoverage,
                    label: '${(daysCoverage * 100).round()}%',
                    caption: '${S.current.historyStatsDaysCoverageCaption} (${stats.solvedDays})',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ProgressStat(
                    value: stats.hardRate,
                    label: '${(stats.hardRate * 100).round()}%',
                    caption: S.current.historyStatsHardRateCaption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatRow(glass: glass, label: S.current.historyStatsStarted, value: '${stats.started}'),
            _StatRow(glass: glass, label: S.current.historyStatsSolved, value: '${stats.solved}'),
            _StatRow(glass: glass, label: S.current.historyStatsSolvedHard, value: '${stats.solvedHard}'),
            _StatRow(glass: glass, label: S.current.historyStatsBestStreak, value: '${stats.bestStreakDays}'),
            _StatRow(glass: glass, label: S.current.historyStatsHintsUsed, value: '${stats.hintsUsed}'),
            _StatRow(
              glass: glass,
              label: S.current.historyStatsTotalTimePlayed,
              value: _formatTotalDuration(stats.totalTimePlayedMs),
            ),
            _StatRow(
              glass: glass,
              label: S.current.historyStatsAvgMovesPerSolve,
              value: stats.avgMovesPerSolve.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTotalDuration(final int milliseconds) {
    final totalMinutes = (milliseconds / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.value, required this.label, required this.caption});

  final double value;
  final String label;
  final String caption;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: colorScheme.surfaceContainerHigh,
              ),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(caption, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.glass});

  final String label;
  final String value;
  final bool glass;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: glass ? 12 : 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
