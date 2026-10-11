import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/cell_outline.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PuzzleBoardPainter extends CustomPainter {
  PuzzleBoardPainter({
    required this.pieces,
    required this.grid,
    this.selectedPiece,
    this.showGridLines = true,
    this.previewPosition,
    this.showPreview = false,
    this.previewCollision = false,
    this.drawnGroup,
    this.drawnGroupCommitStatus = DrawnGroupCommitStatus.tooSmall,
    required this.borderColorMode,
    required this.selectedDate,
    this.isSolved = false,
    this.trayDim = noTrayDim,
    this.editingLayout = false,
  });

  final Iterable<PuzzlePieceUI> pieces;
  final PuzzleGridEntity grid;
  final PuzzlePieceUI? selectedPiece;
  final bool showGridLines;
  final Offset? previewPosition;
  final bool showPreview;
  final bool previewCollision;
  final DrawnGroup? drawnGroup;
  final DrawnGroupCommitStatus drawnGroupCommitStatus;
  final bool borderColorMode;
  final DateTime selectedDate;
  final bool isSolved;
  final TrayDim trayDim;
  final bool editingLayout;

  static const double boardRadius = PiecePaintHelper.radius + PiecePaintHelper.inset;
  static const double labelScale = 0.33;
  static const double markFillAlpha = 0.2;
  static const double markStroke = 2;
  static const List<double> markDash = [5, 4];

  static double cellLabelFontSize(final double cellSize) => (cellSize * labelScale).clamp(12.0, 30.0);

  @override
  void paint(final Canvas canvas, final Size size) {
    _drawGrid(canvas);
    _drawDrawnGroup(canvas);
    if (showPreview && selectedPiece != null && previewPosition != null) {
      _drawPreview(canvas);
    }

    final selectedId = selectedPiece?.id;
    final paintOrder = [
      ...pieces.where((final p) => p.id != selectedId),
      ...pieces.where((final p) => p.id == selectedId),
    ];
    for (final piece in paintOrder) {
      final isSelected = piece.id == selectedId;
      if (piece.isConfigItem && !isSelected && !editingLayout) {
        continue;
      }
      final dim = PiecePaintHelper.saveTrayDim(canvas, piece, trayDim);
      PiecePaintHelper.drawPiece(
        canvas,
        piece,
        cellSize: grid.cellSize,
        look: isSelected ? PieceLook.selected : PieceLook.normal,
        showHintBadge: borderColorMode && !piece.isUsersItem,
        hatched: editingLayout,
      );
      if (dim) {
        canvas.restore();
      }
    }
  }

  void _drawGrid(final Canvas canvas) {
    final colors = AppColors.current.game;
    final bounds = grid.getBounds;
    final shape = RRect.fromRectAndRadius(bounds, const Radius.circular(boardRadius));
    final blockedCells = {
      for (final piece in pieces.where((final p) => p.isConfigItem && p.id != selectedPiece?.id))
        ...piece.cells(grid.origin, grid.cellSize),
    };

    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(bounds, Paint()..color = colors.board);
    for (final cell in blockedCells) {
      canvas.drawRect(_cellRect(cell), Paint()..color = colors.blockedCell);
    }
    if (showGridLines) {
      _drawGridLines(canvas);
    }
    _drawTargetsAndLabels(canvas);
    canvas
      ..restore()
      ..drawRRect(
        shape.inflate(0.75),
        Paint()
          ..color = colors.boardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  void _drawGridLines(final Canvas canvas) {
    final paint = Paint()..color = AppColors.current.gridLine;
    final width = grid.columns * grid.cellSize;
    final height = grid.rows * grid.cellSize;
    for (var i = 1; i < grid.rows; i++) {
      final y = grid.origin.dy + i * grid.cellSize;
      canvas.drawRect(Rect.fromLTWH(grid.origin.dx, y - 0.5, width, 1), paint);
    }
    for (var i = 1; i < grid.columns; i++) {
      final x = grid.origin.dx + i * grid.cellSize;
      canvas.drawRect(Rect.fromLTWH(x - 0.5, grid.origin.dy, 1, height), paint);
    }
  }

  void _drawTargetsAndLabels(final Canvas canvas) {
    final colors = AppColors.current.game;
    final forbiddenCells = pieces
        .where((final e) => e.isConfigItem)
        .expand((final e) => e.cells(grid.origin, grid.cellSize))
        .toSet();

    final labels = <({Rect rect, String text, bool isTarget})>[];
    var cellIndex = 0;
    for (var row = 0; row < grid.rows && cellIndex <= 42; row++) {
      for (var column = 0; column < grid.columns && cellIndex <= 42; column++) {
        final cell = Cell(row, column);
        if (forbiddenCells.contains(cell)) {
          continue;
        }
        labels.add((rect: _cellRect(cell), text: _labelText(cellIndex), isTarget: _isTarget(cellIndex)));
        cellIndex++;
      }
    }

    final targetFill = Paint()..color = colors.target;
    final targetStroke = Paint()
      ..color = isSolved ? colors.ok : colors.targetLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final label in labels.where((final l) => l.isTarget)) {
      final target = RRect.fromRectAndRadius(
        label.rect.deflate(PiecePaintHelper.inset),
        const Radius.circular(PiecePaintHelper.radius),
      );
      canvas
        ..drawRRect(target, targetFill)
        ..drawRRect(target, targetStroke);
    }

    final fontSize = cellLabelFontSize(grid.cellSize);
    for (final label in labels) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.isTarget ? colors.accent : colors.cellLabel,
            fontSize: fontSize,
            fontWeight: label.isTarget ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: grid.cellSize);
      textPainter.paint(
        canvas,
        label.rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawDrawnGroup(final Canvas canvas) {
    final group = drawnGroup;
    if (group == null || group.cells.isEmpty) {
      return;
    }
    final outline = cellOutlinePath(
      group.cells.map((final c) => c.cell),
      grid.cellSize,
      inset: PiecePaintHelper.inset,
      radius: PiecePaintHelper.radius,
    ).shift(Offset(grid.origin.dx, grid.origin.dy));
    final colors = AppColors.current.game;
    switch (drawnGroupCommitStatus) {
      case DrawnGroupCommitStatus.tooSmall:
        _drawMark(canvas, outline, colors.textSecondary, dashed: true);
      case DrawnGroupCommitStatus.committable:
        _drawMark(canvas, outline, colors.ok);
      case DrawnGroupCommitStatus.invalid:
        _drawMark(canvas, outline, colors.bad);
    }
  }

  void _drawPreview(final Canvas canvas) {
    final previewPiece = selectedPiece!.copyWith(position: previewPosition);
    final colors = AppColors.current.game;
    _drawMark(
      canvas,
      PiecePaintHelper.outlinePath(previewPiece, grid.cellSize),
      previewCollision ? colors.bad : colors.ok,
    );
  }

  void _drawMark(final Canvas canvas, final Path outline, final Color color, {final bool dashed = false}) {
    canvas.drawPath(outline, Paint()..color = color.withValues(alpha: markFillAlpha));
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = markStroke;
    canvas.drawPath(dashed ? _dashed(outline, markDash) : outline, stroke);
  }

  static Path _dashed(final Path source, final List<double> pattern) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      var i = 0;
      while (distance < metric.length) {
        final length = pattern[i % pattern.length];
        if (draw) {
          result.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
        i++;
      }
    }
    return result;
  }

  Rect _cellRect(final Cell cell) {
    final topLeft = grid.cellTopLeft(cell);
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, grid.cellSize, grid.cellSize);
  }

  String _labelText(final int cellIndex) =>
      cellIndex < 12 ? intl.DateFormat('MMM').format(DateTime(0, cellIndex + 1)) : '${cellIndex - 11}';

  bool _isTarget(final int cellIndex) =>
      cellIndex < 12 && selectedDate.month == cellIndex + 1 || cellIndex - 11 == selectedDate.day;

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;
}
