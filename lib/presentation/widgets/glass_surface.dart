import 'dart:ui' as ui;

import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Frosted panel: blurred backdrop, translucent fill, hairline border and a soft shadow.
/// On native iOS and macOS a panel with equal corners is drawn as Liquid Glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({super.key, required this.borderRadius, required this.child, this.color, this.allowLiquid = true});

  /// Liquid Glass refracts the backdrop, so its tint is lighter than the frosted fill.
  static const double liquidTintScale = 0.5;

  final BorderRadius borderRadius;
  final Widget child;
  final Color? color;

  /// False keeps the frosted fill, for panels with text.
  final bool allowLiquid;

  static bool isLiquid(final BuildContext context) => !kIsWeb && ScreenSpec.of(context).family == ChromeFamily.glass;

  static Widget liquid(
    final BuildContext context, {
    required final LiquidShape shape,
    required final Color fill,
    required final Widget child,
  }) => GlassContainer(
    useOwnLayer: true,
    quality: GlassQuality.premium,
    shape: shape,
    settings: LiquidGlassSettings(
      glassColor: fill.withValues(alpha: fill.a * liquidTintScale),
      blur: ChromeTheme.of(context).blurSigma / 2,
    ),
    child: Theme(
      // iOS buttons highlight on press instead of a Material ripple.
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: GameColors.of(context).icon.withValues(alpha: 0.12),
      ),
      child: child,
    ),
  );

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final chrome = ChromeTheme.of(context);
    final fill = color ?? colors.glass;
    final radius = borderRadius.topLeft;
    if (allowLiquid && isLiquid(context) && radius.x == radius.y && borderRadius == BorderRadius.all(radius)) {
      return liquid(context, shape: LiquidRoundedSuperellipse(borderRadius: radius.x), fill: fill, child: child);
    }
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
              color: fill,
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
