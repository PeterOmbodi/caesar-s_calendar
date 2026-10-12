import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

/// Keyboard shortcut badge, e.g. ⌘Z.
class KeyCap extends StatelessWidget {
  const KeyCap(this.text, {super.key, this.active = false});

  final String text;

  /// Drawn on an active (filled) background.
  final bool active;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final color = active ? colors.onActive : colors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: active ? colors.onActive.withValues(alpha: 0.4) : colors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(text, style: TextStyle(fontSize: 12, height: 1, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }
}
