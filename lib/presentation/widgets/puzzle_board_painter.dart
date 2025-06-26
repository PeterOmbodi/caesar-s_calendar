import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PuzzleBoardPainter extends CustomPainter {
  final List<PuzzlePiece> pieces;
  final PuzzleGrid grid;
  final PuzzleBoard board;
  final PuzzlePiece? selectedPiece;
  final bool showGridLines;
  final Offset? previewPosition;
  final bool showPreview;
  final bool previewCollision;

  PuzzleBoardPainter({
    required this.pieces,
    required this.grid,
    required this.board,
    this.selectedPiece,
    this.showGridLines = true,
    this.previewPosition,
    this.showPreview = false,
    this.previewCollision = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoard(canvas);
    if (showGridLines) {
      _drawGrid(canvas);
    }
    _drawLabels(canvas);
    if (showPreview && selectedPiece != null && previewPosition != null) {
      _drawPreviewOutline(canvas);
    }

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

    canvas.drawRect(grid.getBounds(), borderPaint);
  }

  void _drawLabels(Canvas canvas) {
    final today = DateTime.now();

    var cellIndex = 0;
    for (int iy = 0; iy < grid.rows; iy++) {
      final y = grid.origin.dy + iy * grid.cellSize;
      for (int ix = 0; ix < grid.columns; ix++) {
        if ((iy == 0 && ix == 6) ||
            (iy == 1 && ix == 6) ||
            (iy == 6 && ix == 3) ||
            (iy == 6 && ix == 4) ||
            (iy == 6 && ix == 5) ||
            (iy == 6 && ix == 6)) {
          continue;
        }
        final x = grid.origin.dx + ix * grid.cellSize;
        final textPainter = TextPainter(
          text: _getCellTextSpan(cellIndex, today),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: grid.cellSize,
        );
        final xCenter = x + (grid.cellSize - textPainter.width) / 2;
        final yCenter = y + (grid.cellSize - textPainter.height) / 2;
        final offset = Offset(xCenter, yCenter);
        textPainter.paint(canvas, offset);
        cellIndex++;
      }
    }
  }

  void _drawBoard(Canvas canvas) {
    // Draw board background
    final bgPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(board.getBounds(), bgPaint);

    // Draw board border
    final borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(board.getBounds(), borderPaint);

    // Draw board label
    const textStyle = TextStyle(
      color: Colors.black54,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: 'Shapes',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        board.origin.dx + 10,
        board.origin.dy + 10,
      ),
    );
  }

  void _drawPreviewOutline(Canvas canvas) {
    if (selectedPiece == null || previewPosition == null) return;

    final previewPiece = selectedPiece!.copyWith(newPosition: previewPosition!);
    final previewPath = previewPiece.getTransformedPath();

    final Color outlineColor = previewCollision ? Colors.red : Colors.green;
    final Color fillColor = previewCollision ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2);

    final dashPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(previewPath, dashPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(previewPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  TextSpan _getCellTextSpan(int cellIndex, DateTime today) {
    final label = cellIndex < 12 ? intl.DateFormat('MMM').format(DateTime(0, cellIndex + 1)) : '${cellIndex - 11}';

    final isTodayLabel = cellIndex < 12 && today.month == cellIndex + 1 || cellIndex - 11 == today.day;

    final textStyle = TextStyle(
      color: isTodayLabel ? Colors.blue : Colors.black,
      fontSize: 14,
      fontWeight: isTodayLabel ? FontWeight.w700 : FontWeight.w400,
    );

    return TextSpan(
      text: label,
      style: textStyle,
    );
  }
}
