import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double _height = 50;
const double _materialHeight = 40;

class RacePrimaryButton extends StatelessWidget {
  const RacePrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(_materialHeight)),
        child: Text(label),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: onPressed,
        color: GameColors.of(context).active,
        minimumSize: const Size.fromHeight(_height),
        child: Text(label),
      ),
    );
  }
}

class RaceSecondaryButton extends StatelessWidget {
  const RaceSecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(_materialHeight)),
        child: Text(label),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.tinted(
        onPressed: onPressed,
        color: GameColors.of(context).active,
        minimumSize: const Size.fromHeight(_height),
        child: Text(label),
      ),
    );
  }
}
