import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

enum GestureDemoKind { drag, draw, rotate, flip, tray }

class GestureDemo extends StatefulWidget {
  const GestureDemo(this.kind, {super.key});

  static const double cell = 16;
  static const Size size = Size(cell * 8, cell * 4);

  final GestureDemoKind kind;

  @override
  State<GestureDemo> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<GestureDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: GestureDemo.size,
        painter: _GestureDemoPainter(
          kind: widget.kind,
          colors: GameColors.of(context),
          animation: _controller,
          still: MediaQuery.disableAnimationsOf(context) ? _stillFrames[widget.kind] : null,
        ),
      ),
    ),
  );

  static const _stillFrames = {
    GestureDemoKind.drag: 0.33,
    GestureDemoKind.draw: 0.35,
    GestureDemoKind.rotate: 0.34,
    GestureDemoKind.flip: 0.22,
    GestureDemoKind.tray: 0.33,
  };
}

class _GestureDemoPainter extends CustomPainter {
  _GestureDemoPainter({required this.kind, required this.colors, required this.animation, required this.still})
    : super(repaint: animation);

  static const double c = GestureDemo.cell;

  /// Board-sized cell, scaled down: corners match the board.
  static const double _drawCell = 42;
  static const double _trayScale = 0.6;
  static final PuzzlePieceUI _piece = PuzzlePieceUI.fromType(
    PieceType.pShape,
    Offset.zero,
    Offset.zero,
    _drawCell,
  ).copyWith(placeZone: PlaceZone.grid);

  static const _drawnCells = [(5, 1), (4, 1), (3, 1), (3, 2), (4, 2)];

  final GestureDemoKind kind;
  final GameColors colors;
  final Animation<double> animation;
  final double? still;

  @override
  void paint(final Canvas canvas, final Size size) {
    final t = still ?? animation.value;
    switch (kind) {
      case GestureDemoKind.drag:
        _drag(canvas, t, toTray: false);
      case GestureDemoKind.tray:
        _drag(canvas, t, toTray: true);
      case GestureDemoKind.draw:
        _draw(canvas, t);
      case GestureDemoKind.rotate:
        _rotate(canvas, t);
      case GestureDemoKind.flip:
        _flip(canvas, t);
    }
  }

  void _drag(final Canvas canvas, final double t, {required final bool toTray}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(1, 1, 3 * c - 2, 4 * c - 2), const Radius.circular(6)),
      Paint()..color = colors.background,
    );
    _grid(canvas, const Rect.fromLTWH(4 * c, 0, 4 * c, 4 * c));

    const trayCenter = Offset(1.5 * c, 2 * c);
    const gridCenter = Offset(5.5 * c, 2 * c);
    final move = _ease(t, 0.16, 0.5);
    final center = toTray ? Offset.lerp(gridCenter, trayCenter, move)! : Offset.lerp(trayCenter, gridCenter, move)!;
    final scale = toTray ? lerpDouble(1, _trayScale, move)! : lerpDouble(_trayScale, 1, move)!;
    final held = t > 0.1 && t < 0.54;
    _pieceAt(canvas, center, scale: scale, look: held ? PieceLook.lifted : PieceLook.normal, opacity: _loopOpacity(t));
    _touch(canvas, center, press: held ? 1 : 0, opacity: math.min(_ease(t, 0.04, 0.1), 1 - _ease(t, 0.52, 0.58)));
  }

  void _draw(final Canvas canvas, final double t) {
    _grid(canvas, Offset.zero & GestureDemo.size);
    Offset cellCenter(final (int, int) cell) => Offset((cell.$1 + 0.5) * c, (cell.$2 + 0.5) * c);
    final opacity = _loopOpacity(t);
    final trace = _linear(t, 0.1, 0.5) * (_drawnCells.length - 1);

    if (t < 0.76) {
      final count = trace.floor() + 1;
      final color = count == _drawnCells.length ? colors.ok : colors.textSecondary;
      for (final cell in _drawnCells.take(count)) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: cellCenter(cell), width: c - 3, height: c - 3),
          const Radius.circular(3),
        );
        canvas
          ..drawRRect(rect, Paint()..color = color.withValues(alpha: 0.25 * opacity))
          ..drawRRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = color.withValues(alpha: opacity),
          );
      }
    } else {
      _pieceAt(canvas, const Offset(4.5 * c, 2 * c), opacity: opacity);
    }

    if (t < 0.6) {
      final i = trace.floor().clamp(0, _drawnCells.length - 2);
      final dot = Offset.lerp(cellCenter(_drawnCells[i]), cellCenter(_drawnCells[i + 1]), trace - i)!;
      _touch(canvas, dot, press: 1, opacity: math.min(_ease(t, 0.04, 0.1), 1 - _ease(t, 0.5, 0.56)));
    } else {
      final tap = math.max(_tap(t, 0.63), _tap(t, 0.72));
      _touch(canvas, cellCenter(_drawnCells[1]), press: tap, opacity: tap);
    }
  }

  void _rotate(final Canvas canvas, final double t) {
    _grid(canvas, Offset.zero & GestureDemo.size);
    // Turned 3×2 piece is half a cell off the grid.
    final snap = _ease(t, 0.56, 0.64);
    _pieceAt(
      canvas,
      const Offset(4.5 * c, 2 * c) + const Offset(-0.5 * c, 0.5 * c) * snap,
      turns: _ease(t, 0.38, 0.56),
      look: t > 0.16 ? PieceLook.selected : PieceLook.normal,
      opacity: _loopOpacity(t),
    );
    final tap = math.max(_tap(t, 0.14), _tap(t, 0.34));
    _touch(canvas, const Offset(4.5 * c, 1.5 * c), press: tap, opacity: tap);
  }

  void _flip(final Canvas canvas, final double t) {
    _grid(canvas, Offset.zero & GestureDemo.size);
    _pieceAt(
      canvas,
      const Offset(4.5 * c, 2 * c),
      scaleX: 1 - 2 * _ease(t, 0.28, 0.48),
      look: t > 0.12 ? PieceLook.selected : PieceLook.normal,
      opacity: _loopOpacity(t),
    );
    final tap = math.max(_tap(t, 0.13), _tap(t, 0.22));
    _touch(canvas, const Offset(4.5 * c, 1.5 * c), press: tap, opacity: tap);
  }

  void _grid(final Canvas canvas, final Rect rect) {
    final line = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 1;
    for (var x = rect.left + c; x < rect.right - 1; x += c) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), line);
    }
    for (var y = rect.top + c; y < rect.bottom - 1; y += c) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = colors.boardBorder,
    );
  }

  void _pieceAt(
    final Canvas canvas,
    final Offset center, {
    final double scale = 1,
    final double turns = 0,
    final double scaleX = 1,
    final PieceLook look = PieceLook.normal,
    final double opacity = 1,
  }) {
    if (opacity <= 0) {
      return;
    }
    final k = scale * c / _drawCell;
    final sx = scaleX.abs() < 0.01 ? 0.01 : scaleX;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turns * math.pi / 2)
      ..scale(k * sx, k)
      ..translate(-1.5 * _drawCell, -_drawCell);
    if (opacity < 1) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    }
    PiecePaintHelper.drawPiece(canvas, _piece, cellSize: _drawCell, look: look);
    if (opacity < 1) {
      canvas.restore();
    }
    canvas.restore();
  }

  void _touch(final Canvas canvas, final Offset at, {required final double press, required final double opacity}) {
    if (opacity <= 0) {
      return;
    }
    final radius = 8 - 2 * press;
    canvas
      ..drawCircle(at, radius, Paint()..color = colors.text.withValues(alpha: 0.2 * opacity))
      ..drawCircle(
        at,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = colors.text.withValues(alpha: 0.6 * opacity),
      );
  }

  static double _linear(final double t, final double from, final double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  static double _ease(final double t, final double from, final double to) =>
      Curves.easeInOut.transform(_linear(t, from, to));

  /// 0 → 1 at [at] → 0.
  static double _tap(final double t, final double at) => 1 - ((t - at).abs() / 0.04).clamp(0.0, 1.0);

  static double _loopOpacity(final double t) => math.min(_ease(t, 0, 0.06), 1 - _ease(t, 0.9, 0.97));

  @override
  bool shouldRepaint(covariant final _GestureDemoPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.colors != colors || oldDelegate.still != still;
}
