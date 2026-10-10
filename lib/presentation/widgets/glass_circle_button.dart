import 'dart:ui' as ui;

import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.size = defaultSize,
    this.badge,
  });

  static const double defaultSize = 44;

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final double size;

  /// Drawn outside the round clip.
  final Widget? badge;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final chrome = ChromeTheme.of(context);
    final button = Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: chrome.blurSigma, sigmaY: chrome.blurSigma),
            child: Material(
              color: colors.glass,
              shape: CircleBorder(side: BorderSide(color: colors.glassLine)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox.square(dimension: size, child: Center(child: child)),
              ),
            ),
          ),
        ),
      ),
    );
    final badge = this.badge;
    if (badge == null) {
      return button;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(right: -2, bottom: -2, child: IgnorePointer(child: badge)),
      ],
    );
  }
}
