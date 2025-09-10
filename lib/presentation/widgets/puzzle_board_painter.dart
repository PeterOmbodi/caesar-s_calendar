import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
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
  final bool borderColorMode;

  PuzzleBoardPainter({
    required this.pieces,
    required this.grid,
    required this.board,
    this.selectedPiece,
    this.showGridLines = true,
    this.previewPosition,
    this.showPreview = false,
    this.previewCollision = false,
    required this.borderColorMode,
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
        ..color = piece == selectedPiece ? piece.color().withValues(alpha: 0.9) : piece.color()
        ..style = PaintingStyle.fill;

      final transformedPath = piece.getTransformedPath();
      canvas.drawPath(transformedPath, paint);

      final borderPaint = Paint()
        ..color = piece == selectedPiece ? AppColors.current.pieceBorderSelected : piece.borderColor(borderColorMode)
        ..style = PaintingStyle.stroke
        ..strokeWidth = piece == selectedPiece ? 3.0 : 1.5;
      canvas.drawPath(transformedPath, borderPaint);

      if (piece == selectedPiece) {
        final centerPaint = Paint()
          ..color = AppColors.current.pieceCenterDot
          ..style = PaintingStyle.fill;

        canvas.drawCircle(piece.position + piece.centerPoint, 5.0, centerPaint);
      }
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.current.gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // horizontal lines
    for (int i = 0; i <= grid.rows; i++) {
      final y = grid.origin.dy + i * grid.cellSize;
      canvas.drawLine(Offset(grid.origin.dx, y), Offset(grid.origin.dx + grid.columns * grid.cellSize, y), paint);
    }

    // vertical lines
    for (int i = 0; i <= grid.columns; i++) {
      final x = grid.origin.dx + i * grid.cellSize;
      canvas.drawLine(Offset(x, grid.origin.dy), Offset(x, grid.origin.dy + grid.rows * grid.cellSize), paint);
    }

    // game board borders
    final borderPaint = Paint()
      ..color = AppColors.current.gridBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(grid.getBounds, borderPaint);
  }

  void _drawLabels(Canvas canvas) {
    final today = DateTime.now();

    final forbiddenCells = pieces
        .where((e) => e.isForbidden)
        .map((e) => e.cells(grid.origin, grid.cellSize))
        .expand((e) => e);

    var cellIndex = 0;
    for (int row = 0; row < grid.rows; row++) {
      final y = grid.origin.dy + row * grid.cellSize;
      for (int column = 0; column < grid.columns; column++) {
        if (forbiddenCells.contains(Cell(row, column))) {
          continue;
        }
        final x = grid.origin.dx + column * grid.cellSize;
        final textPainter = TextPainter(text: _getCellTextSpan(cellIndex, today), textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: grid.cellSize);
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
      ..color = AppColors.current.boardBackground
      ..style = PaintingStyle.fill;

    canvas.drawRect(board.getBounds, bgPaint);

    // Draw board border
    final borderPaint = Paint()
      ..color = AppColors.current.boardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(board.getBounds, borderPaint);
  }

  void _drawPreviewOutline(Canvas canvas) {
    if (selectedPiece == null || previewPosition == null) return;

    final previewPiece = selectedPiece!.copyWith(position: previewPosition!);
    final previewPath = previewPiece.getTransformedPath();

    final Color outlineColor = previewCollision
        ? AppColors.current.previewOutlineCollision
        : AppColors.current.previewOutline;
    final Color fillColor = previewCollision
        ? AppColors.current.previewFillCollision.withValues(alpha: 0.2)
        : AppColors.current.previewFill.withValues(alpha: 0.2);

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
      color: isTodayLabel ? AppColors.current.todayLabel : AppColors.current.cellLabel,
      fontSize: 14,
      fontWeight: isTodayLabel ? FontWeight.w700 : FontWeight.w400,
    );

    return TextSpan(text: label, style: textStyle);
  }
}
