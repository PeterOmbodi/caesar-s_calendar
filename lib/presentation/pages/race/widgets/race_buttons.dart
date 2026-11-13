import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

const double _height = 56;
const _shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));
const _textStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

class RacePrimaryButton extends StatelessWidget {
  const RacePrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(_height),
        backgroundColor: colors.active,
        foregroundColor: colors.onActive,
        disabledBackgroundColor: colors.gridLine,
        disabledForegroundColor: colors.textSecondary,
        shape: _shape,
        textStyle: _textStyle,
      ),
      child: Text(label),
    );
  }
}

class RaceSecondaryButton extends StatelessWidget {
  const RaceSecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(_height),
        backgroundColor: colors.glass,
        foregroundColor: colors.text,
        side: BorderSide(color: colors.glassLine),
        shape: _shape,
        textStyle: _textStyle,
      ),
      child: Text(label),
    );
  }
}
