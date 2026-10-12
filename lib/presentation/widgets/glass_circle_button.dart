import 'dart:ui' as ui;

import 'package:caesar_puzzle/presentation/theme/chrome_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class GlassCircleButton extends StatefulWidget {
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
  State<GlassCircleButton> createState() => _GlassCircleButtonState();
}

class _GlassCircleButtonState extends State<GlassCircleButton> {
  /// Liquid Glass buttons swell while pressed.
  static const double _pressedScale = 1.1;

  bool _pressed = false;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final chrome = ChromeTheme.of(context);
    final tap = InkWell(
      customBorder: const CircleBorder(),
      onTap: widget.onPressed,
      onHighlightChanged: (final value) => setState(() => _pressed = value),
      child: SizedBox.square(dimension: widget.size, child: Center(child: widget.child)),
    );
    final surface = GlassSurface.isLiquid(context)
        ? AnimatedScale(
            scale: _pressed ? _pressedScale : 1,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: GlassSurface.liquid(
              context,
              shape: const LiquidOval(),
              fill: colors.glass,
              child: Material(type: MaterialType.transparency, shape: const CircleBorder(), child: tap),
            ),
          )
        : DecoratedBox(
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
                  child: tap,
                ),
              ),
            ),
          );
    final button = Tooltip(message: widget.tooltip, child: surface);
    final badge = widget.badge;
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
