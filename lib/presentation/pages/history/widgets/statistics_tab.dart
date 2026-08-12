import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/models/period_stats.dart';
import 'package:caesar_puzzle/application/models/stats_period.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/history/bloc/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) {
      final cubit = context.read<HistoryCubit>();
      final referenceDate = PeriodRangeResolver.referenceDateFor(state.selectedDate);
      final rangeLabel = _periodRangeLabel(context, state.statsPeriod, referenceDate);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _LabeledChipRow(
            label: S.current.historyStatsSessionsFromLabel,
            child: _YearScopeChips(selected: state.statsYearScope, onSelected: cubit.setStatsYearScope),
          ),
          const SizedBox(height: 12),
          _LabeledChipRow(
            label: S.current.historyStatsPeriodLabel,
            child: _PeriodChips(selected: state.statsPeriod, onSelected: cubit.setStatsPeriod),
          ),
          const SizedBox(height: 8),
          Text(
            rangeLabel ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _StatTile(stats: state.periodStats, period: state.statsPeriod, referenceDate: referenceDate),
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
  const _StatTile({required this.stats, required this.period, required this.referenceDate});

  final PeriodStats stats;
  final StatsPeriod period;
  final DateTime referenceDate;

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
            _StatRow(label: S.current.historyStatsStarted, value: '${stats.started}'),
            _StatRow(label: S.current.historyStatsSolved, value: '${stats.solved}'),
            _StatRow(label: S.current.historyStatsSolvedHard, value: '${stats.solvedHard}'),
            _StatRow(label: S.current.historyStatsBestStreak, value: '${stats.bestStreakDays}'),
            _StatRow(label: S.current.historyStatsHintsUsed, value: '${stats.hintsUsed}'),
            _StatRow(
              label: S.current.historyStatsTotalTimePlayed,
              value: _formatTotalDuration(stats.totalTimePlayedMs),
            ),
            _StatRow(
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
        Text(
          caption,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
