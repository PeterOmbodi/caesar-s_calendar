import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PuzzleBoardPainter extends CustomPainter {
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
    required this.selectedDate,
  });

  final Iterable<PuzzlePiece> pieces;
  final PuzzleGrid grid;
  final PuzzleBoard board;
  final PuzzlePiece? selectedPiece;
  final bool showGridLines;
  final Offset? previewPosition;
  final bool showPreview;
  final bool previewCollision;
  final bool borderColorMode;
  final DateTime selectedDate;

  @override
  void paint(final Canvas canvas, final Size size) {
    _drawBoard(canvas);
    if (showGridLines) {
      _drawGrid(canvas);
    }
    _drawLabels(canvas);
    if (showPreview && selectedPiece != null && previewPosition != null) {
      _drawPreviewOutline(canvas);
    }

    for (final piece in pieces) {
      final isSelected = piece.id == selectedPiece?.id;
      PiecePaintHelper.drawPiece(canvas, piece, isSelected, borderColorMode);
      if (isSelected) {
        final centerPaint = Paint()
          ..color = AppColors.current.pieceCenterDot
          ..style = PaintingStyle.fill;
        canvas.drawCircle(piece.position + piece.centerPoint, 5.0, centerPaint);
      }
    }
  }

  void _drawGrid(final Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.current.gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // horizontal lines
    for (var i = 0; i <= grid.rows; i++) {
      final y = grid.origin.dy + i * grid.cellSize;
      canvas.drawLine(Offset(grid.origin.dx, y), Offset(grid.origin.dx + grid.columns * grid.cellSize, y), paint);
    }

    // vertical lines
    for (var i = 0; i <= grid.columns; i++) {
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

  void _drawLabels(final Canvas canvas) {
    final forbiddenCells = pieces
        .where((final e) => e.isConfigItem)
        .map((final e) => e.cells(grid.origin, grid.cellSize))
        .expand((final e) => e);

    var cellIndex = 0;
    for (var row = 0; row < grid.rows; row++) {
      final y = grid.origin.dy + row * grid.cellSize;
      for (var column = 0; column < grid.columns; column++) {
        if (forbiddenCells.contains(Cell(row, column))) {
          continue;
        }
        final x = grid.origin.dx + column * grid.cellSize;
        final textPainter = TextPainter(
          text: _getCellTextSpan(cellIndex, selectedDate),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: grid.cellSize);
        final xCenter = x + (grid.cellSize - textPainter.width) / 2;
        final yCenter = y + (grid.cellSize - textPainter.height) / 2;
        final offset = Offset(xCenter, yCenter);
        textPainter.paint(canvas, offset);
        cellIndex++;
        if (cellIndex > 42) {
          break;
        }
      }
    }
  }

  void _drawBoard(final Canvas canvas) {
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

  void _drawPreviewOutline(final Canvas canvas) {
    if (selectedPiece == null || previewPosition == null) return;

    final previewPiece = selectedPiece!.copyWith(position: previewPosition!);
    final previewPath = previewPiece.getTransformedPath();

    final outlineColor = previewCollision
        ? AppColors.current.previewOutlineCollision
        : AppColors.current.previewOutline;
    final fillColor = previewCollision
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
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;

  TextSpan _getCellTextSpan(final int cellIndex, final DateTime today) {
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
