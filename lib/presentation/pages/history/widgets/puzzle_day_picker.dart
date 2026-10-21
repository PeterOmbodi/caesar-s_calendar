import 'dart:math' as math;

import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/utils/month_label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dates are puzzle month/day identities. The leap-year anchor is never shown.
/// [blocked] are the board cells covered by the current layout.
Future<DateTime?> showPuzzleDayPicker(
  final BuildContext context, {
  required final DateTime selectedDate,
  final Set<Cell>? blocked,
}) {
  final picker = PuzzleDayPicker(selectedDate: selectedDate, blocked: blocked);
  final compact = MediaQuery.sizeOf(context).width < 600 && MediaQuery.sizeOf(context).height > 480;
  if (compact) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => picker,
    );
  }
  return showDialog<DateTime>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: picker),
    ),
  );
}

typedef _Label = ({bool isMonth, int value});

class PuzzleDayPicker extends StatefulWidget {
  const PuzzleDayPicker({super.key, required this.selectedDate, this.blocked});

  final DateTime selectedDate;
  final Set<Cell>? blocked;

  @override
  State<PuzzleDayPicker> createState() => _PuzzleDayPickerState();
}

class _PuzzleDayPickerState extends State<PuzzleDayPicker> {
  static const _labelCount = 12 + 31;

  late int _month = widget.selectedDate.month;
  late int _day = widget.selectedDate.day;
  late final Map<Cell, _Label> _labels = _resolveLabels();

  Map<Cell, _Label> _resolveLabels() {
    final standard = blockedCellsOf(PuzzleConfigJson.standardPlacements);
    final labels = _labelsFor(widget.blocked ?? standard);
    // A board with too few free cells cannot show every date.
    return labels.length < _labelCount ? _labelsFor(standard) : labels;
  }

  /// Same order as on the board: free cells row by row, months first.
  static Map<Cell, _Label> _labelsFor(final Set<Cell> blocked) {
    final labels = <Cell, _Label>{};
    for (var row = 0; row < PuzzleBloc.gridRows; row++) {
      for (var col = 0; col < PuzzleBloc.gridColumns; col++) {
        final cell = Cell(row, col);
        if (blocked.contains(cell) || labels.length == _labelCount) {
          continue;
        }
        final index = labels.length;
        labels[cell] = index < 12 ? (isMonth: true, value: index + 1) : (isMonth: false, value: index - 11);
      }
    }
    return labels;
  }

  static int _daysIn(final int month) => DateTime(2024, month + 1, 0).day;

  void _select(final _Label label) => setState(() {
    if (label.isMonth) {
      _month = label.value;
      _day = math.min(_day, _daysIn(_month));
    } else {
      _day = label.value;
    }
  });

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final material = MaterialLocalizations.of(context);
    final glass = ScreenSpec.of(context).family == ChromeFamily.glass;
    final gridWidth = math.max(240.0, MediaQuery.sizeOf(context).height - 220);

    Widget action(final String label, final VoidCallback onPressed, {final bool primary = false}) => glass
        ? CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: onPressed,
            child: Text(
              label,
              style: TextStyle(color: colors.accent, fontWeight: primary ? FontWeight.w600 : FontWeight.w400),
            ),
          )
        : TextButton(onPressed: onPressed, child: Text(label));

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  action(material.cancelButtonLabel, () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text(
                      S.current.historyPickDate,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: colors.textSecondary),
                    ),
                  ),
                  action(
                    material.okButtonLabel,
                    () => Navigator.of(context).pop(DateTime(2024, _month, _day)),
                    primary: true,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
                child: Text(
                  DateFormat.MMMMd(locale).format(DateTime(2024, _month, _day)),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: gridWidth),
                child: AspectRatio(
                  aspectRatio: PuzzleBloc.gridColumns / PuzzleBloc.gridRows,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.board,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.boardBorder, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.5),
                      child: Column(
                        children: [
                          for (var row = 0; row < PuzzleBloc.gridRows; row++)
                            Expanded(
                              child: Row(
                                children: [
                                  for (var col = 0; col < PuzzleBloc.gridColumns; col++)
                                    Expanded(child: _cell(colors, locale, Cell(row, col))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(final GameColors colors, final String locale, final Cell cell) {
    final label = _labels[cell];
    if (label == null) {
      return ColoredBox(color: colors.blockedCell);
    }
    final available = label.isMonth || label.value <= _daysIn(_month);
    final selected = label.isMonth ? label.value == _month : label.value == _day;
    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      excludeSemantics: true,
      label: label.isMonth
          ? DateFormat.MMMM(locale).format(DateTime(2024, label.value))
          : DateFormat.MMMMd(locale).format(DateTime(2024, _month, label.value)),
      child: GestureDetector(
        key: ValueKey('${label.isMonth ? 'month' : 'day'}-${label.value}'),
        behavior: HitTestBehavior.opaque,
        onTap: available ? () => _select(label) : null,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: colors.gridLine, width: 0.5)),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.target : colors.target.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.targetLine : colors.targetLine.withValues(alpha: 0), width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label.isMonth ? shortMonthName(label.value) : '${label.value}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colors.accent
                          : available
                          ? colors.cellLabel
                          : colors.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
