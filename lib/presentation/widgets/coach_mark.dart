import 'dart:math' as math;

import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:caesar_puzzle/presentation/widgets/spotlight_painter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shown once per [storageKey]; true if the player went on.
/// [canCancel] false: one button; any dismissal counts as seen.
class CoachMark {
  const CoachMark._();

  static Future<bool> showOnce({
    required final BuildContext context,
    required final String storageKey,
    required final Rect? anchor,
    required final String title,
    required final String message,
    required final String actionLabel,
    final bool canCancel = true,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(storageKey) ?? false) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    final acknowledged = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      pageBuilder: (final dialogContext, _, _) => _CoachMarkOverlay(
        anchor: anchor,
        title: title,
        message: message,
        actionLabel: actionLabel,
        canCancel: canCancel,
        onClose: (final goOn) => Navigator.of(dialogContext).pop(goOn),
      ),
      transitionBuilder: (_, final animation, _, final child) => FadeTransition(opacity: animation, child: child),
    );
    if (canCancel && acknowledged != true) {
      return false;
    }
    await preferences.setBool(storageKey, true);
    return context.mounted;
  }
}

class _CoachMarkOverlay extends StatelessWidget {
  const _CoachMarkOverlay({
    required this.anchor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.canCancel,
    required this.onClose,
  });

  final Rect? anchor;
  final String title;
  final String message;
  final String actionLabel;
  final bool canCancel;
  final ValueChanged<bool> onClose;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final anchor = this.anchor;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: SpotlightPainter(holes: [if (anchor != null) anchor.inflate(4)]),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _BubbleLayout(anchor: anchor, padding: MediaQuery.paddingOf(context)),
            child: GlassSurface(
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: colors.menu,
              allowLiquid: false,
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              height: 22 / 17,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            message,
                            style: TextStyle(fontSize: 15, height: 20 / 15, color: colors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (canCancel)
                            TextButton(
                              onPressed: () => onClose(false),
                              style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
                              child: Text(S.current.onboardingClose),
                            ),
                          TextButton(
                            onPressed: () => onClose(true),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.accent,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            child: Text(actionLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout({required this.anchor, required this.padding});

  static const double _margin = 16;
  static const double _gap = 12;
  static const double _maxWidth = 320;

  final Rect? anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) => BoxConstraints(
    maxWidth: math.min(_maxWidth, constraints.maxWidth - padding.horizontal - 2 * _margin),
    maxHeight: constraints.maxHeight - padding.vertical - 2 * _margin,
  );

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    final anchor = this.anchor;
    if (anchor == null) {
      return Offset((size.width - childSize.width) / 2, (size.height - childSize.height) / 2);
    }
    final safe = padding.deflateRect(Offset.zero & size).deflate(_margin);
    Offset inside(final Offset p) => Offset(
      p.dx.clamp(safe.left, math.max(safe.left, safe.right - childSize.width)),
      p.dy.clamp(safe.top, math.max(safe.top, safe.bottom - childSize.height)),
    );
    // Bottom bar: above the button; rails: beside it.
    if (anchor.center.dy > size.height * 0.75) {
      return inside(Offset(anchor.center.dx - childSize.width / 2, anchor.top - _gap - childSize.height));
    }
    final toLeft = anchor.left > size.width - anchor.right;
    final x = toLeft ? anchor.left - _gap - childSize.width : anchor.right + _gap;
    return inside(Offset(x, anchor.center.dy - childSize.height / 2));
  }

  @override
  bool shouldRelayout(covariant final _BubbleLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.padding != padding;
}
