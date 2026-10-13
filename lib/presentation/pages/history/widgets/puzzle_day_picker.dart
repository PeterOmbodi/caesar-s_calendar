import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dates are puzzle month/day identities. The leap-year anchor is never shown.
Future<DateTime?> showPuzzleDayPicker(final BuildContext context, {required final DateTime selectedDate}) {
  final compact = MediaQuery.sizeOf(context).width < 600 && MediaQuery.sizeOf(context).height > 480;
  if (compact) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PuzzleDayPicker(selectedDate: selectedDate),
    );
  }
  return showDialog<DateTime>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PuzzleDayPicker(selectedDate: selectedDate),
      ),
    ),
  );
}

class PuzzleDayPicker extends StatefulWidget {
  const PuzzleDayPicker({super.key, required this.selectedDate});
  final DateTime selectedDate;

  @override
  State<PuzzleDayPicker> createState() => _PuzzleDayPickerState();
}

class _PuzzleDayPickerState extends State<PuzzleDayPicker> {
  late int _month = widget.selectedDate.month;
  late int _day = widget.selectedDate.day;
  bool _choosingMonth = false;

  void _selectMonth(final int month) => setState(() {
    _month = (month - 1) % 12 + 1;
    _day = _day.clamp(1, DateTime(2024, _month + 1, 0).day);
    _choosingMonth = false;
  });

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final material = MaterialLocalizations.of(context);
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
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(material.cancelButtonLabel, style: TextStyle(color: colors.accent)),
                  ),
                  Expanded(
                    child: Text(
                      S.current.historyPickDate,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.text),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => Navigator.of(context).pop(DateTime(2024, _month, _day)),
                    child: Text(material.okButtonLabel, style: TextStyle(color: colors.accent)),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () => setState(() => _choosingMonth = !_choosingMonth),
                      child: Text(
                        DateFormat.MMMM(locale).format(DateTime(2024, _month)),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    key: const ValueKey('previous-month'),
                    onPressed: () => _selectMonth(_month - 1),
                    child: Icon(CupertinoIcons.chevron_left, semanticLabel: material.previousMonthTooltip),
                  ),
                  CupertinoButton(
                    key: const ValueKey('next-month'),
                    onPressed: () => _selectMonth(_month + 1),
                    child: Icon(CupertinoIcons.chevron_right, semanticLabel: material.nextMonthTooltip),
                  ),
                ],
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: LayoutBuilder(
                    builder: (final context, final constraints) {
                      final columns = _choosingMonth ? 3 : 7;
                      final count = _choosingMonth ? 12 : DateTime(2024, _month + 1, 0).day;
                      return Wrap(
                        children: List.generate(count, (final index) {
                          final value = index + 1;
                          final selected = value == (_choosingMonth ? _month : _day);
                          return SizedBox(
                            width: constraints.maxWidth / columns,
                            height: 48,
                            child: Semantics(
                              selected: selected,
                              label: _choosingMonth
                                  ? DateFormat.MMMM(locale).format(DateTime(2024, value))
                                  : DateFormat.MMMMd(locale).format(DateTime(2024, _month, value)),
                              child: CupertinoButton(
                                key: ValueKey('${_choosingMonth ? 'month' : 'day'}-$value'),
                                padding: EdgeInsets.zero,
                                onPressed: () => _choosingMonth ? _selectMonth(value) : setState(() => _day = value),
                                child: Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: selected ? colors.active : null,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Text(
                                    _choosingMonth ? DateFormat.MMM(locale).format(DateTime(2024, value)) : '$value',
                                    style: TextStyle(fontSize: 17, color: selected ? colors.onActive : colors.text),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
