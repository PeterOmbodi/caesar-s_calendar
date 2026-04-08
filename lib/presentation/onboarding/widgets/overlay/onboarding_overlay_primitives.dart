import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';

class OnboardingOverlayDimmer extends StatelessWidget {
  const OnboardingOverlayDimmer({
    super.key,
    this.interactionHole,
    this.spotlightHoles = const [],
  });

  final Rect? interactionHole;
  final List<Rect> spotlightHoles;

  @override
  Widget build(final BuildContext context) {
    if (interactionHole == null && spotlightHoles.isEmpty) {
      return const Positioned.fill(
        child: AbsorbPointer(
          child: ColoredBox(color: Color.fromARGB(133, 0, 0, 0)),
        ),
      );
    }

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: interactionHole == null,
        child: IgnorePointer(
          ignoring: interactionHole != null,
          child: CustomPaint(
            painter: OnboardingOverlayDimmerPainter(
              interactionHole: interactionHole,
              spotlightHoles: spotlightHoles,
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingOverlayDimmerPainter extends CustomPainter {
  const OnboardingOverlayDimmerPainter({
    required this.interactionHole,
    required this.spotlightHoles,
  });

  final Rect? interactionHole;
  final List<Rect> spotlightHoles;

  @override
  void paint(final Canvas canvas, final Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    if (interactionHole != null) {
      overlayPath.addRRect(RRect.fromRectAndRadius(interactionHole!, const Radius.circular(18)));
    }
    for (final hole in spotlightHoles) {
      overlayPath.addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(14)));
    }

    final paint = Paint()
      ..color = const Color.fromARGB(133, 0, 0, 0)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath..fillType = PathFillType.evenOdd, paint);
  }

  @override
  bool shouldRepaint(covariant final OnboardingOverlayDimmerPainter oldDelegate) =>
      oldDelegate.interactionHole != interactionHole ||
      oldDelegate.spotlightHoles.length != spotlightHoles.length ||
      !sameRects(oldDelegate.spotlightHoles, spotlightHoles);
}

class OnboardingHighlightFrame extends StatelessWidget {
  const OnboardingHighlightFrame({
    super.key,
    required this.rect,
    this.showGlow = true,
  });

  final Rect rect;
  final bool showGlow;

  @override
  Widget build(final BuildContext context) => Positioned(
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade300, width: 3),
          boxShadow: showGlow
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 4)]
              : const [],
        ),
      ),
    ),
  );
}

class OnboardingPieceContourHighlight extends StatelessWidget {
  const OnboardingPieceContourHighlight({
    super.key,
    required this.piece,
    this.opacity = 1,
  });

  final PuzzlePieceUI piece;
  final double opacity;

  @override
  Widget build(final BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(painter: OnboardingPieceContourHighlightPainter(piece: piece)),
      ),
    ),
  );
}

class OnboardingPieceContourHighlightPainter extends CustomPainter {
  const OnboardingPieceContourHighlightPainter({required this.piece});

  final PuzzlePieceUI piece;

  @override
  void paint(final Canvas canvas, final Size size) {
    final path = piece.getTransformedPath();
    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final strokePaint = Paint()
      ..color = Colors.amber.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant final OnboardingPieceContourHighlightPainter oldDelegate) =>
      oldDelegate.piece != piece;
}

class OnboardingPieceContourFlipHighlight extends StatelessWidget {
  const OnboardingPieceContourFlipHighlight({
    super.key,
    required this.piece,
    required this.scaleX,
    required this.opacity,
  });

  final PuzzlePieceUI piece;
  final double scaleX;
  final double opacity;

  @override
  Widget build(final BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: OnboardingPieceContourFlipHighlightPainter(
            piece: piece,
            scaleX: scaleX,
          ),
        ),
      ),
    ),
  );
}

class OnboardingPieceContourFlipHighlightPainter extends CustomPainter {
  const OnboardingPieceContourFlipHighlightPainter({
    required this.piece,
    required this.scaleX,
  });

  final PuzzlePieceUI piece;
  final double scaleX;

  @override
  void paint(final Canvas canvas, final Size size) {
    final path = piece.getTransformedPath();
    final centerWorld = piece.position + piece.centerPoint;
    final safeScale = scaleX.abs() < 1e-3 ? (scaleX.isNegative ? -1e-3 : 1e-3) : scaleX;

    canvas
      ..save()
      ..translate(centerWorld.dx, centerWorld.dy)
      ..scale(safeScale, 1)
      ..translate(-centerWorld.dx, -centerWorld.dy);

    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final strokePaint = Paint()
      ..color = Colors.amber.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant final OnboardingPieceContourFlipHighlightPainter oldDelegate) =>
      oldDelegate.piece != piece || oldDelegate.scaleX != scaleX;
}

class OnboardingDemoHandBubble extends StatelessWidget {
  const OnboardingDemoHandBubble({super.key});

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, spreadRadius: 1)],
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(Icons.touch_app, color: Colors.deepOrange.shade400, size: 22),
    ),
  );
}

bool sameRects(final List<Rect> a, final List<Rect> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
