
import 'package:caesar_puzzle/puzzle/puzzle_piece.dart';
import 'package:flutter/material.dart';

class PuzzlePiecePainter extends CustomPainter {
  final List<PuzzlePiece> pieces;

  PuzzlePiecePainter({required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in pieces) {
      final paint = Paint()
        ..color = piece.color
        ..style = PaintingStyle.fill;

      canvas.drawPath(piece.path.shift(piece.position), paint);

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(piece.path.shift(piece.position), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

