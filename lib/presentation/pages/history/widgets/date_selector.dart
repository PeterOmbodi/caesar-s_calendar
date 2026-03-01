import 'dart:ui' show PointerDeviceKind;

import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.stats,
    required this.onDateTap,
    this.cellSize = 24,
    this.columnGap = 4,
    this.rowGap = 4,
    this.topDateGap = 6,
    this.monthsToGridGap = 4,
    this.showMonthLabels = true,
  });

  final DateTime selectedDate;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<CalendarDayStats> stats;
  final ValueChanged<DateTime> onDateTap;
  final double cellSize;
  final double columnGap;
  final double rowGap;
  final double topDateGap;
  final double monthsToGridGap;
  final bool showMonthLabels;

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  static const int _calendarYear = 2024; // Leap year to always include Feb 29.

  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final statsByDate = _aggregateByMonthDay(widget.stats);

    final cells = _buildHeatmapCells();
    final columns = <List<DateTime?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      columns.add(cells.sublist(i, (i + 7).clamp(0, cells.length)));
    }
    final monthLabels = _buildMonthLabels(columns);

    final maxSolved = widget.stats.fold<int>(
      0,
      (final max, final item) => item.solvedVariants > max ? item.solvedVariants : max,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.MMMMd(Localizations.localeOf(context).toLanguageTag()).format(widget.selectedDate),
                  style: textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HeatScaleLegend(colorScheme: colorScheme),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.topDateGap),
        ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: kIsWeb || _isDesktop(),
            interactive: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: _buildScrollableContent(
                  columns: columns,
                  monthLabels: monthLabels,
                  statsByDate: statsByDate,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  maxSolved: maxSolved,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isDesktop() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  List<Widget> _buildScrollableContent({
    required final List<List<DateTime?>> columns,
    required final Map<int, String> monthLabels,
    required final Map<String, CalendarDayStats> statsByDate,
    required final TextTheme textTheme,
    required final ColorScheme colorScheme,
    required final int maxSolved,
  }) {
    final children = <Widget>[];

    if (widget.showMonthLabels) {
      children.add(
        Row(children: _buildMonthLabelWidgets(columns, monthLabels, textTheme)),
      );
      children.add(SizedBox(height: widget.monthsToGridGap));
    }

    children.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildGridColumns(columns, statsByDate, colorScheme, maxSolved),
      ),
    );

    return children;
  }

  List<Widget> _buildMonthLabelWidgets(
    final List<List<DateTime?>> columns,
    final Map<int, String> monthLabels,
    final TextTheme textTheme,
  ) {
    final result = <Widget>[];
    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      if (columnIndex > 0) {
        result.add(SizedBox(width: widget.columnGap));
      }
      result.add(
        SizedBox(
          width: widget.cellSize,
          child: Text(
            monthLabels[columnIndex] ?? '',
            style: textTheme.labelSmall,
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        ),
      );
    }
    return result;
  }

  List<Widget> _buildGridColumns(
    final List<List<DateTime?>> columns,
    final Map<String, CalendarDayStats> statsByDate,
    final ColorScheme colorScheme,
    final int maxSolved,
  ) {
    final result = <Widget>[];
    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      if (columnIndex > 0) {
        result.add(SizedBox(width: widget.columnGap));
      }
      result.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildDayCells(
            column: columns[columnIndex],
            statsByDate: statsByDate,
            colorScheme: colorScheme,
            maxSolved: maxSolved,
          ),
        ),
      );
    }
    return result;
  }

  List<Widget> _buildDayCells({
    required final List<DateTime?> column,
    required final Map<String, CalendarDayStats> statsByDate,
    required final ColorScheme colorScheme,
    required final int maxSolved,
  }) {
    final result = <Widget>[];
    for (var rowIndex = 0; rowIndex < column.length; rowIndex++) {
      final day = column[rowIndex];
      result.add(
        _HeatmapDayCell(
          day: day,
          isSelected: day != null && _isSameMonthDay(day, widget.selectedDate),
          stats: day == null ? null : statsByDate[_monthDayKey(day)],
          maxSolved: maxSolved,
          colorScheme: colorScheme,
          onTap: (final tappedDay) => widget.onDateTap(
            DateTime(_calendarYear, tappedDay.month, tappedDay.day),
          ),
          size: widget.cellSize,
        ),
      );
      if (rowIndex < column.length - 1) {
        result.add(SizedBox(height: widget.rowGap));
      }
    }
    return result;
  }

  List<DateTime?> _buildHeatmapCells() {
    final normalizedStart = DateTime(_calendarYear, 1, 1);
    final normalizedEnd = DateTime(_calendarYear, 12, 31);
    final cells = <DateTime?>[];

    var current = normalizedStart;
    while (!current.isAfter(normalizedEnd)) {
      cells.add(current);
      current = current.add(const Duration(days: 1));
    }
    final trailingEmpty = (7 - (cells.length % 7)) % 7;
    if (trailingEmpty > 0) {
      cells.addAll(List<DateTime?>.filled(trailingEmpty, null));
    }
    return cells;
  }

  Map<int, String> _buildMonthLabels(final List<List<DateTime?>> columns) {
    final labels = <int, String>{};
    int? lastMonth;
    for (var i = 0; i < columns.length; i++) {
      final firstDay = columns[i].whereType<DateTime>().firstOrNull;
      if (firstDay == null) continue;
      if (firstDay.month != lastMonth) {
        labels[i] = DateFormat.MMM().format(firstDay);
        lastMonth = firstDay.month;
      }
    }
    return labels;
  }

  Map<String, CalendarDayStats> _aggregateByMonthDay(final List<CalendarDayStats> source) {
    final result = <String, CalendarDayStats>{};
    for (final stat in source) {
      final key = _monthDayKey(stat.date);
      final existing = result[key];
      if (existing == null) {
        result[key] = stat;
        continue;
      }
      result[key] = CalendarDayStats(
        date: existing.date,
        totalSolutions: _sumNullable(existing.totalSolutions, stat.totalSolutions),
        solvedVariants: existing.solvedVariants + stat.solvedVariants,
        unsolvedStarted: existing.unsolvedStarted + stat.unsolvedStarted,
      );
    }
    return result;
  }

  int? _sumNullable(final int? a, final int? b) {
    if (a == null && b == null) return null;
    return (a ?? 0) + (b ?? 0);
  }

  bool _isSameMonthDay(final DateTime a, final DateTime b) =>
      a.month == b.month && a.day == b.day;

  String _monthDayKey(final DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _HeatmapDayCell extends StatelessWidget {
  const _HeatmapDayCell({
    required this.day,
    required this.isSelected,
    required this.stats,
    required this.maxSolved,
    required this.colorScheme,
    required this.onTap,
    required this.size,
  });

  final DateTime? day;
  final bool isSelected;
  final CalendarDayStats? stats;
  final int maxSolved;
  final ColorScheme colorScheme;
  final ValueChanged<DateTime> onTap;
  final double size;

  @override
  Widget build(final BuildContext context) {
    if (day == null) {
      return SizedBox(width: size, height: size);
    }

    return Tooltip(
      message: _tooltipText(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: () => onTap(day!),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _fillColor(),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Color _fillColor() {
    final level = _resolveLevel();
    return colorForLevel(level, colorScheme);
  }

  _HeatLevel _resolveLevel() {
    final solved = stats?.solvedVariants ?? 0;
    final unsolved = stats?.unsolvedStarted ?? 0;
    if (solved > 3) {
      return _HeatLevel.solvedHigh;
    }
    if (solved > 1) {
      return _HeatLevel.solvedMany;
    }
    if (solved == 1) {
      return _HeatLevel.inProgressSolved;
    }
    if (unsolved > 1) {
      return _HeatLevel.inProgressMany;
    }
    if (unsolved == 1) {
      return _HeatLevel.inProgress;
    }
    return _HeatLevel.empty;
  }

  static Color colorForLevel(final _HeatLevel level, final ColorScheme colorScheme) {
    final empty = colorScheme.brightness == Brightness.dark
        ? const Color(0xFF2D333B)
        : colorScheme.surfaceContainerHigh;
    const inProgress = Color(0xFF0E4429);
    const inProgressMany = Color(0xFF006D32);
    const inProgressSolved = Color(0xFF26A641);
    const solvedMany = Color(0xFF39D353);
    const solvedHigh = Color(0xFF56D364);

    switch (level) {
      case _HeatLevel.empty:
        return empty;
      case _HeatLevel.inProgress:
        return inProgress;
      case _HeatLevel.inProgressMany:
        return inProgressMany;
      case _HeatLevel.inProgressSolved:
        return inProgressSolved;
      case _HeatLevel.solvedMany:
        return solvedMany;
      case _HeatLevel.solvedHigh:
        return solvedHigh;
    }
  }

  String _tooltipText(final BuildContext context) {
    final dateText = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(day!);
    final solved = stats?.solvedVariants ?? 0;
    final unsolved = stats?.unsolvedStarted ?? 0;
    return '$dateText • solved: $solved • in progress: $unsolved';
  }
}

enum _HeatLevel {
  empty,
  inProgress,
  inProgressMany,
  inProgressSolved,
  solvedMany,
  solvedHigh,
}

class _HeatScaleLegend extends StatelessWidget {
  const _HeatScaleLegend({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    final levels = <_HeatLevel>[
      _HeatLevel.inProgress,
      _HeatLevel.inProgressMany,
      _HeatLevel.inProgressSolved,
      _HeatLevel.solvedMany,
      _HeatLevel.solvedHigh,
    ];
    final textStyle = Theme.of(context).textTheme.labelSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(S.current.historyLegendLess, style: textStyle),
        const SizedBox(width: 6),
        for (var i = 0; i < levels.length; i++) ...[
          _LegendSquare(color: _HeatmapDayCell.colorForLevel(levels[i], colorScheme)),
          if (i < levels.length - 1) const SizedBox(width: 3),
        ],
        const SizedBox(width: 6),
        Text(S.current.historyLegendMore, style: textStyle),
      ],
    );
  }
}

class _LegendSquare extends StatelessWidget {
  const _LegendSquare({required this.color});

  final Color color;

  @override
  Widget build(final BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.6),
    ),
  );
}
