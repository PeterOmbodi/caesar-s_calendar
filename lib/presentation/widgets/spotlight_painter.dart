import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Dims the screen except [holes].
class SpotlightPainter extends CustomPainter {
  const SpotlightPainter({this.holes = const []});

  static const Color dim = Color.fromARGB(133, 0, 0, 0);

  final List<Rect> holes;

  @override
  void paint(final Canvas canvas, final Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final hole in holes) {
      path.addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(14)));
    }
    canvas.drawPath(path, Paint()..color = dim);
  }

  @override
  bool shouldRepaint(covariant final SpotlightPainter oldDelegate) => !listEquals(oldDelegate.holes, holes);
}
