import 'package:caesar_puzzle/puzzle/puzzle_grid.dart';
import 'package:caesar_puzzle/puzzle/puzzle_piece.dart';
import 'package:flutter/material.dart';

class PuzzleBoardPainter extends CustomPainter {
  final List<PuzzlePiece> pieces;
  final PuzzleGrid grid;
  final PuzzlePiece? selectedPiece;

  PuzzleBoardPainter({
    required this.pieces,
    required this.grid,
    this.selectedPiece,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas);

    for (var piece in pieces) {
      final paint = Paint()
        ..color = piece == selectedPiece ? piece.color.withOpacity(0.9) : piece.color
        ..style = PaintingStyle.fill;

      final transformedPath = piece.getTransformedPath();
      canvas.drawPath(transformedPath, paint);

      final borderPaint = Paint()
        ..color = piece == selectedPiece ? Colors.yellow : Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = piece == selectedPiece ? 3.0 : 2.0;
      canvas.drawPath(transformedPath, borderPaint);

      if (piece == selectedPiece) {
        final centerPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

        canvas.drawCircle(piece.position + piece.centerPoint, 5.0, centerPaint);
      }
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // horizontal lines
    for (int i = 0; i <= grid.rows; i++) {
      final y = grid.origin.dy + i * grid.cellSize;
      canvas.drawLine(
        Offset(grid.origin.dx, y),
        Offset(grid.origin.dx + grid.columns * grid.cellSize, y),
        paint,
      );
    }

    // vertical lines
    for (int i = 0; i <= grid.columns; i++) {
      final x = grid.origin.dx + i * grid.cellSize;
      canvas.drawLine(
        Offset(x, grid.origin.dy),
        Offset(x, grid.origin.dy + grid.rows * grid.cellSize),
        paint,
      );
    }

    // game board borders
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
        Rect.fromLTWH(grid.origin.dx, grid.origin.dy, grid.cellSize * grid.columns, grid.cellSize * grid.rows),
        borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
