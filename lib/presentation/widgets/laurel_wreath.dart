import 'dart:math';

import 'package:flutter/material.dart';

/// Two branches along a circle, open at the top, as an icon.
class LaurelWreath extends StatelessWidget {
  const LaurelWreath({super.key, required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(final BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LaurelWreathPainter(color: color)),
  );
}

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

class _LaurelWreathPainter extends CustomPainter {
  const _LaurelWreathPainter({required this.color});

  static const int _leaves = 5;
  static const double _from = 25 * pi / 180;
  static const double _to = 150 * pi / 180;

  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    final radius = side * 0.37;
    final length = side * 0.19;
    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.055
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = color;

    // Angles are counted from the bottom of the circle, up both sides.
    for (final sign in const [-1.0, 1.0]) {
      Offset point(final double angle) => center + Offset(sign * radius * sin(angle), radius * cos(angle));
      double upwards(final double angle) => atan2(-sin(angle), sign * cos(angle));

      final path = Path()..moveTo(point(_from).dx, point(_from).dy);
      for (var i = 1; i <= 24; i++) {
        final p = point(_from + (_to - _from) * i / 24);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, stem);

      for (var i = 0; i < _leaves; i++) {
        final angle = _from + (_to - _from) * (i + 0.5) / _leaves;
        final scale = 1 - 0.3 * i / _leaves;
        _drawLeaf(canvas, leaf, point(angle), upwards(angle) - sign * 0.7, length * scale, 0.44);
        _drawLeaf(canvas, leaf, point(angle), upwards(angle) + sign * 0.7, length * scale * 0.85, 0.44);
      }
      _drawLeaf(canvas, leaf, point(_to), upwards(_to), length * 0.7, 0.44);
    }
  }

  @override
  bool shouldRepaint(final _LaurelWreathPainter oldDelegate) => oldDelegate.color != color;
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
