import 'dart:async';
import 'dart:math';

import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/puzzle_header.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_time_format.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_circle_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class RaceHeader extends StatelessWidget {
  const RaceHeader({
    super.key,
    required this.date,
    required this.isStarted,
    required this.startAtMs,
    required this.stoppedAtMs,
    required this.now,
    required this.onLeave,
    this.firstFinisher,
    this.graceEndsAtMs,
  });

  static const double _sideWidth = 64;

  final DateTime date;
  final bool isStarted;
  final int startAtMs;

  /// Server time; the clock stops there.
  final int? stoppedAtMs;

  /// Server clock.
  final DateTime Function() now;
  final VoidCallback onLeave;
  final String? firstFinisher;
  final int? graceEndsAtMs;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _sideWidth,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: GlassCircleButton(
              tooltip: S.current.raceLeaveTooltip,
              onPressed: onLeave,
              child: Icon(Icons.close, size: 22, color: GameColors.of(context).icon),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PuzzleHeaderTexts(
              title: isStarted ? intl.DateFormat.MMMMd().format(date) : S.current.raceTitle,
              subtitle: [
                if (firstFinisher case final name?)
                  TextSpan(
                    text: S.current.raceFirstFinish(name),
                    style: TextStyle(fontWeight: FontWeight.w600, color: GameColors.of(context).bad),
                  )
                else
                  TextSpan(text: S.current.raceNoHints),
              ],
              goal: isStarted ? PuzzleHeader.goalSpans(context, date) : [TextSpan(text: S.current.raceLightsHint)],
            ),
          ),
        ),
        SizedBox(
          width: _sideWidth,
          height: GlassCircleButton.defaultSize,
          child: isStarted
              ? _RaceClock(startAtMs: startAtMs, stoppedAtMs: stoppedAtMs, graceEndsAtMs: graceEndsAtMs, now: now)
              : null,
        ),
      ],
    ),
  );
}

class _RaceClock extends StatefulWidget {
  const _RaceClock({
    required this.startAtMs,
    required this.stoppedAtMs,
    required this.graceEndsAtMs,
    required this.now,
  });

  final int startAtMs;
  final int? stoppedAtMs;
  final int? graceEndsAtMs;
  final DateTime Function() now;

  @override
  State<_RaceClock> createState() => _RaceClockState();
}

class _RaceClockState extends State<_RaceClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (widget.stoppedAtMs == null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final nowMs = widget.now().millisecondsSinceEpoch;
    final graceEndsAt = widget.stoppedAtMs == null ? widget.graceEndsAtMs : null;
    final elapsed = (widget.stoppedAtMs ?? nowMs) - widget.startAtMs;
    // Rounded up, so that it shows 0:00 only when the time is out.
    final secondsLeft = graceEndsAt == null ? 0 : max(0, (graceEndsAt - nowMs + 999) ~/ 1000);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.glass,
        border: Border.all(color: colors.glassLine),
        borderRadius: BorderRadius.circular(GlassCircleButton.defaultSize / 2),
      ),
      child: Center(
        child: Text(
          formatRaceTime(graceEndsAt == null ? elapsed : secondsLeft * 1000),
          semanticsLabel: graceEndsAt == null ? null : S.current.raceGraceSemantics(secondsLeft),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: graceEndsAt == null ? colors.text : colors.bad,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
