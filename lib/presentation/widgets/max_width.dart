import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Centres [child] in at most [maxWidth] and keeps the full height.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final context, final constraints) => Padding(
      padding: EdgeInsets.symmetric(horizontal: math.max(0, (constraints.maxWidth - maxWidth) / 2)),
      child: child,
    ),
  );
}
