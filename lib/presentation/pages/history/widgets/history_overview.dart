import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/date_selector.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryOverview extends StatelessWidget {
  const HistoryOverview({
    super.key,
    required this.selectedDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.stats,
    required this.onDateTap,
    this.sidebar = false,
    this.centerSelectionRequest = 0,
  });

  final DateTime selectedDate;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<CalendarDayStats> stats;
  final ValueChanged<DateTime> onDateTap;
  final bool sidebar;
  final int centerSelectionRequest;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.MMMMd(locale).format(selectedDate);
    return Semantics(
      container: true,
      label: '${S.current.historyTitle}: $dateLabel',
      child: Padding(
        padding: sidebar ? const EdgeInsets.fromLTRB(4, 8, 8, 8) : const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HistoryOverviewHeader(dateLabel: dateLabel, glass: glass, stacked: sidebar),
                ExcludeSemantics(
                  child: DateSelector(
                    selectedDate: selectedDate,
                    rangeStart: rangeStart,
                    rangeEnd: rangeEnd,
                    stats: stats,
                    onDateTap: onDateTap,
                    centerSelectionRequest: centerSelectionRequest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryOverviewHeader extends StatelessWidget {
  const _HistoryOverviewHeader({required this.dateLabel, required this.glass, required this.stacked});

  final String dateLabel;
  final bool glass;
  final bool stacked;

  @override
  Widget build(final BuildContext context) {
    if (glass) {
      return _GlassHistoryOverviewHeader(dateLabel: dateLabel, stacked: stacked);
    }
    return _MaterialHistoryOverviewHeader(dateLabel: dateLabel);
  }
}

class _GlassHistoryOverviewHeader extends StatelessWidget {
  const _GlassHistoryOverviewHeader({required this.dateLabel, required this.stacked});

  final String dateLabel;
  final bool stacked;

  @override
  Widget build(final BuildContext context) {
    final style = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: GameColors.of(context).text);
    if (stacked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: style),
            const SizedBox(height: 8),
            const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: HeatmapLegend(large: true)),
          ],
        ),
      );
    }
    return _HistoryOverviewHeaderRow(dateLabel: dateLabel, style: style);
  }
}

class _MaterialHistoryOverviewHeader extends StatelessWidget {
  const _MaterialHistoryOverviewHeader({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(final BuildContext context) =>
      _HistoryOverviewHeaderRow(dateLabel: dateLabel, style: Theme.of(context).textTheme.labelMedium);
}

class _HistoryOverviewHeaderRow extends StatelessWidget {
  const _HistoryOverviewHeaderRow({required this.dateLabel, required this.style});

  final String dateLabel;
  final TextStyle? style;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Expanded(child: Text(dateLabel, style: style)),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: const FittedBox(fit: BoxFit.scaleDown, child: HeatmapLegend()),
          ),
        ),
      ],
    ),
  );
}
