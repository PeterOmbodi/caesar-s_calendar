import 'dart:async';

import 'package:caesar_puzzle/application/race/race_lights.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/widgets/game_background.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({
    super.key,
    required this.startAtMs,
    required this.pauseMs,
    required this.now,
    required this.haptics,
  });

  final int startAtMs;
  final int pauseMs;

  /// Server clock.
  final DateTime Function() now;
  final bool haptics;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  late final Timer _timer;
  late int _lit = _litNow;

  int get _litNow => RaceLights.lit(
    nowMs: widget.now().millisecondsSinceEpoch,
    startAtMs: widget.startAtMs,
    pauseMs: widget.pauseMs,
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final lit = _litNow;
      if (lit == _lit) {
        return;
      }
      if (lit > _lit && widget.haptics) {
        unawaited(HapticFeedback.lightImpact());
      }
      setState(() => _lit = lit);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AbsorbPointer(
    child: GameBackground(
      child: Center(
        child: Semantics(
          label: S.current.raceLightsSemantics(_lit),
          liveRegion: true,
          child: _LightsPanel(lit: _lit),
        ),
      ),
    ),
  );
}

class _LightsPanel extends StatelessWidget {
  const _LightsPanel({required this.lit});

  // A start gantry looks the same in the light and the dark theme.
  static const _panel = Color(0xE6121017);
  static const _panelLine = Color(0x21FFFFFF);
  static const _on = Color(0xFFFF3B30);
  static const _off = Color(0xFF2F2B38);
  static const _offLine = Color(0xFF3D3848);

  final int lit;

  @override
  Widget build(final BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 120);
    return Container(
      width: 312,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _panelLine),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < RaceLights.count; i++)
            AnimatedContainer(
              duration: duration,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: i < lit ? _on : _off,
                shape: BoxShape.circle,
                border: Border.all(color: i < lit ? _on : _offLine),
                boxShadow: [if (i < lit) const BoxShadow(color: Color(0xBFFF3B30), blurRadius: 18)],
              ),
            ),
        ],
      ),
    );
  }
}
