import 'dart:ui' as ui;

import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

/// Frosted panel: blurred backdrop, translucent fill, hairline border and a soft shadow.
class GlassSurface extends StatelessWidget {
  const GlassSurface({super.key, required this.borderRadius, required this.child, this.color});

  final BorderRadius borderRadius;
  final Widget child;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final chrome = ChromeTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: chrome.blurSigma, sigmaY: chrome.blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? colors.glass,
              borderRadius: borderRadius,
              border: Border.all(color: colors.glassLine),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
