import 'package:flutter/material.dart';

class LaurelBranch extends StatelessWidget {
  const LaurelBranch({super.key, required this.color, required this.mirrored, this.grow = 1});

  final Color color;
  final bool mirrored;

  /// From 0 to 1 while the branch grows.
  final double grow;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: 18,
    height: 28,
    child: CustomPaint(
      painter: _LaurelBranchPainter(color: color, mirrored: mirrored, grow: grow),
    ),
  );
}

/// Drawn as the left branch; [mirrored] gives the right one.
class _LaurelBranchPainter extends CustomPainter {
  const _LaurelBranchPainter({required this.color, required this.mirrored, required this.grow});

  static const int _leaves = 5;

  final Color color;
  final bool mirrored;
  final double grow;

  @override
  void paint(final Canvas canvas, final Size size) {
    if (grow <= 0) {
      return;
    }
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final start = Offset(size.width * 0.9, size.height * 0.95);
    final control = Offset(size.width * 0.05, size.height * 0.65);
    final end = Offset(size.width * 0.6, size.height * 0.1);
    Offset point(final double t) => start * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + end * (t * t);
    Offset tangent(final double t) => (control - start) * (2 * (1 - t)) + (end - control) * (2 * t);

    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final tip = grow.clamp(0.0, 1.0);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= 12; i++) {
      final p = point(tip * i / 12);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stem);

    final leaf = Paint()..color = color;
    final length = size.height * 0.22;
    for (var i = 1; i <= _leaves; i++) {
      final t = i / (_leaves + 1);
      if (t > tip) {
        break;
      }
      final at = point(t);
      final direction = tangent(t).direction;
      final scaled = length * (1 - t * 0.35) * grow;
      _drawLeaf(canvas, leaf, at, direction - 0.7, scaled, 0.4);
      _drawLeaf(canvas, leaf, at, direction + 0.7, scaled, 0.4);
    }
    if (tip >= 1) {
      _drawLeaf(canvas, leaf, end, tangent(1).direction, length * 0.8 * grow, 0.4);
    }
  }

  @override
  bool shouldRepaint(final _LaurelBranchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mirrored != mirrored || oldDelegate.grow != grow;
}

/// An oval leaf growing from [at] in the direction of [angle].
void _drawLeaf(
  final Canvas canvas,
  final Paint paint,
  final Offset at,
  final double angle,
  final double length,
  final double widthRatio,
) {
  canvas
    ..save()
    ..translate(at.dx, at.dy)
    ..rotate(angle)
    ..drawOval(Rect.fromLTWH(0, -length * widthRatio / 2, length, length * widthRatio), paint)
    ..restore();
}
