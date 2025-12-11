import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

class PiecePaintHelper {
  static void drawPiece(final Canvas canvas, final PuzzlePiece piece, final bool isSelected, final bool borderColorMode) {
    final transformedPath = piece.getTransformedPath();

    final fill = Paint()
      ..isAntiAlias = true
      ..color = isSelected ? piece.color().withValues(alpha: 0.9) : piece.color()
      ..style = PaintingStyle.fill;

    const inset = 2.0;
    const innerThickness = 2.0;
    final bounds = transformedPath.getBounds().inflate(inset + innerThickness + 2);
    final smallerBorderColor = borderColorMode && !piece.isUsersItem
        ? Colors.orangeAccent
        : AppColors.current.pieceBorder.withValues(alpha: 0.1);
    final smallerBorder = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * (inset + innerThickness)
      ..strokeJoin = StrokeJoin.round
      ..color = smallerBorderColor;

    canvas
      ..drawPath(transformedPath, fill)
      ..save()
      ..clipPath(transformedPath)
      ..saveLayer(bounds, Paint())
      ..drawPath(transformedPath, smallerBorder);

    final clearPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * inset
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.clear;
    final borderBigger = Paint()
      ..color = isSelected ? AppColors.current.pieceBorderSelected : AppColors.current.pieceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5;
    canvas
      ..drawPath(transformedPath, clearPaint)
      ..restore()
      ..restore()
      ..drawPath(transformedPath, borderBigger);
  }
}
