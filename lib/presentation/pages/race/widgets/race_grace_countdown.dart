import 'dart:async';

import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:material_ui/material_ui.dart';

class RaceGraceCountdown extends StatefulWidget {
  const RaceGraceCountdown({super.key, required this.endsAtMs, required this.now});

  final int endsAtMs;
  final DateTime Function() now;

  @override
  State<RaceGraceCountdown> createState() => _RaceGraceCountdownState();
}

class _RaceGraceCountdownState extends State<RaceGraceCountdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final left = widget.endsAtMs - widget.now().millisecondsSinceEpoch;
    final seconds = left <= 0 ? 0 : (left / 1000).ceil();
    return Semantics(
      label: S.current.raceGraceSemantics(seconds),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: colors.bad),
          const SizedBox(width: 4),
          Text(
            '$seconds',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.bad,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
