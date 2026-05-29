import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InsetCupertinoAlertDialog extends StatelessWidget {
  const InsetCupertinoAlertDialog({
    super.key,
    required this.insetPadding,
    required this.title,
    required this.content,
    required this.actionLabel,
    required this.onPressed,
  });

  final EdgeInsets insetPadding;
  final Widget title;
  final Widget content;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final resolvedDividerColor = CupertinoDynamicColor.resolve(CupertinoColors.separator, context);
    final resolvedBackgroundColor = CupertinoDynamicColor.resolve(
      const CupertinoDynamicColor.withBrightness(color: Color(0xCCF2F2F2), darkColor: Color(0xCC2D2D2D)),
      context,
    );

    final titleStyle = const TextStyle(
      fontFamily: 'CupertinoSystemText',
      inherit: false,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.5,
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(color: CupertinoDynamicColor.resolve(CupertinoColors.label, context));

    final contentStyle = const TextStyle(
      fontFamily: 'CupertinoSystemText',
      inherit: false,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: -0.2,
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(color: CupertinoDynamicColor.resolve(CupertinoColors.label, context));

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
        final availableWidth = constraints.maxWidth - insetPadding.horizontal;
        final dialogWidth = math.min(availableWidth, 560.0);
        return AnimatedPadding(
          padding: MediaQuery.viewInsetsOf(context) + insetPadding,
          duration: const Duration(milliseconds: 100),
          curve: Curves.decelerate,
          child: MediaQuery.removeViewInsets(
            removeLeft: true,
            removeTop: true,
            removeRight: true,
            removeBottom: true,
            context: context,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: maxHeight - insetPadding.vertical),
                  child: CupertinoPopupSurface(
                    isSurfacePainted: false,
                    child: ColoredBox(
                      color: resolvedBackgroundColor,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: DefaultTextStyle(
                                style: contentStyle,
                                textAlign: TextAlign.center,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DefaultTextStyle(style: titleStyle, textAlign: TextAlign.center, child: title),
                                      const SizedBox(height: 8),
                                      content,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: resolvedDividerColor)),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  onPressed: onPressed,
                                  child: Text(actionLabel),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
