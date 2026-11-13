import 'dart:ui' show PointerDeviceKind;

import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    this.fitGridToWidth = false,
    this.centerSelectionRequest = 0,
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
  final bool fitGridToWidth;

  /// Increment to reveal the selection after an explicit external navigation.
  final int centerSelectionRequest;

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  static const int _calendarYear = 2024; // Leap year to always include Feb 29.

  late final ScrollController _horizontalController;
  String? _centeredLayout;

  void _centerSelection(final double width, final double cellSize) {
    final layout = '$width/$cellSize/${widget.columnGap}/${widget.centerSelectionRequest}';
    if (_centeredLayout == layout) return;
    _centeredLayout = layout;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontalController.hasClients || _centeredLayout != layout) return;
      final dayIndex = DateTime.utc(
        _calendarYear,
        widget.selectedDate.month,
        widget.selectedDate.day,
      ).difference(DateTime.utc(_calendarYear)).inDays;
      final column = dayIndex ~/ 7;
      final position = _horizontalController.position;
      final offset = 12 + column * (cellSize + widget.columnGap) + cellSize / 2 - position.viewportDimension / 2;
      _horizontalController.jumpTo(offset.clamp(position.minScrollExtent, position.maxScrollExtent));
    });
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (final context, final constraints) {
            final cellSize = widget.fitGridToWidth
                ? _fittedCellSize(constraints.maxWidth, columns.length)
                : widget.cellSize;
            _centerSelection(constraints.maxWidth, cellSize);
            return _HeatmapScroller(
              controller: _horizontalController,
              child: _HeatmapGrid(
                columns: columns,
                monthLabels: monthLabels,
                showMonthLabels: widget.showMonthLabels,
                statsByDate: statsByDate,
                selectedDate: widget.selectedDate,
                maxSolved: maxSolved,
                cellSize: cellSize,
                columnGap: widget.columnGap,
                rowGap: widget.rowGap,
                monthsToGridGap: widget.monthsToGridGap,
                onDayTap: (final day) => widget.onDateTap(DateTime(_calendarYear, day.month, day.day)),
              ),
            );
          },
        ),
      ],
    );
  }

  double _fittedCellSize(final double maxWidth, final int columns) {
    const minCellSize = 16.0;
    const maxCellSize = 32.0;
    final available = maxWidth - 24 - (columns - 1) * widget.columnGap;
    final size = available / columns;
    return size.clamp(minCellSize, maxCellSize);
  }

  List<DateTime?> _buildHeatmapCells() {
    final normalizedStart = DateTime(_calendarYear);
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
        labels[i] = shortMonthName(firstDay.month);
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
}

bool _isSameMonthDay(final DateTime a, final DateTime b) => a.month == b.month && a.day == b.day;

String _monthDayKey(final DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _HeatmapScroller extends StatelessWidget {
  const _HeatmapScroller({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  static bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => true,
    _ => false,
  };

  @override
  Widget build(final BuildContext context) => ScrollConfiguration(
    behavior: const MaterialScrollBehavior().copyWith(
      dragDevices: const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    ),
    child: Scrollbar(
      controller: controller,
      thumbVisibility: kIsWeb || _isDesktop,
      interactive: true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    ),
  );
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.columns,
    required this.monthLabels,
    required this.showMonthLabels,
    required this.statsByDate,
    required this.selectedDate,
    required this.maxSolved,
    required this.cellSize,
    required this.columnGap,
    required this.rowGap,
    required this.monthsToGridGap,
    required this.onDayTap,
  });

  final List<List<DateTime?>> columns;
  final Map<int, String> monthLabels;
  final bool showMonthLabels;
  final Map<String, CalendarDayStats> statsByDate;
  final DateTime selectedDate;
  final int maxSolved;
  final double cellSize;
  final double columnGap;
  final double rowGap;
  final double monthsToGridGap;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(final BuildContext context) => Column(
    children: [
      if (showMonthLabels) ...[
        _MonthLabels(columnCount: columns.length, labels: monthLabels, cellSize: cellSize, columnGap: columnGap),
        SizedBox(height: monthsToGridGap),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) SizedBox(width: columnGap),
            _WeekColumn(
              days: columns[i],
              statsByDate: statsByDate,
              selectedDate: selectedDate,
              maxSolved: maxSolved,
              cellSize: cellSize,
              rowGap: rowGap,
              onDayTap: onDayTap,
            ),
          ],
        ],
      ),
    ],
  );
}

class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.columnCount,
    required this.labels,
    required this.cellSize,
    required this.columnGap,
  });

  final int columnCount;
  final Map<int, String> labels;
  final double cellSize;
  final double columnGap;

  @override
  Widget build(final BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        for (var i = 0; i < columnCount; i++) ...[
          if (i > 0) SizedBox(width: columnGap),
          SizedBox(
            width: cellSize,
            child: Text(labels[i] ?? '', style: style, overflow: TextOverflow.visible, softWrap: false),
          ),
        ],
      ],
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.days,
    required this.statsByDate,
    required this.selectedDate,
    required this.maxSolved,
    required this.cellSize,
    required this.rowGap,
    required this.onDayTap,
  });

  final List<DateTime?> days;
  final Map<String, CalendarDayStats> statsByDate;
  final DateTime selectedDate;
  final int maxSolved;
  final double cellSize;
  final double rowGap;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, day) in days.indexed) ...[
          if (i > 0) SizedBox(height: rowGap),
          _HeatmapDayCell(
            day: day,
            isSelected: day != null && _isSameMonthDay(day, selectedDate),
            stats: day == null ? null : statsByDate[_monthDayKey(day)],
            maxSolved: maxSolved,
            colorScheme: colorScheme,
            onTap: onDayTap,
            size: cellSize,
          ),
        ],
      ],
    );
  }
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

    final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
    return InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: () => onTap(day!),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: glass ? appleColor(_resolveLevel(), GameColors.of(context)) : _fillColor(),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 0.6,
          ),
        ),
      ),
    );
  }

  Color _fillColor() {
    final level = _resolveLevel();
    return colorForLevel(level, colorScheme);
  }

  static Color appleColor(final _HeatLevel level, final GameColors colors) =>
      level == _HeatLevel.empty ? colors.gridLine : Color.lerp(colors.board, colors.active, .25 + level.index * .15)!;

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
}

enum _HeatLevel { empty, inProgress, inProgressMany, inProgressSolved, solvedMany, solvedHigh }

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key, this.large = false});

  final bool large;

  @override
  Widget build(final BuildContext context) {
    final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
    final levels = <_HeatLevel>[
      _HeatLevel.inProgress,
      _HeatLevel.inProgressMany,
      _HeatLevel.inProgressSolved,
      _HeatLevel.solvedMany,
      _HeatLevel.solvedHigh,
    ];
    final textStyle = large
        ? Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 13)
        : Theme.of(context).textTheme.labelSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(S.current.historyLegendLess, style: textStyle),
        const SizedBox(width: 6),
        for (var i = 0; i < levels.length; i++) ...[
          _LegendSquare(
            size: large ? 12 : 10,
            color: glass
                ? _HeatmapDayCell.appleColor(levels[i], GameColors.of(context))
                : _HeatmapDayCell.colorForLevel(levels[i], Theme.of(context).colorScheme),
          ),
          if (i < levels.length - 1) const SizedBox(width: 3),
        ],
        const SizedBox(width: 6),
        Text(S.current.historyLegendMore, style: textStyle),
      ],
    );
  }
}

class _LegendSquare extends StatelessWidget {
  const _LegendSquare({required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(final BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.6),
    ),
  );
}
