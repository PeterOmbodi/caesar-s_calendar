import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:flutter/material.dart';

Path generatePathForType(final PieceType type, final double cellSize) {
  switch (type) {
    case PieceType.lShape:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(cellSize, 0)
        ..lineTo(cellSize, cellSize)
        ..lineTo(4 * cellSize, cellSize)
        ..lineTo(4 * cellSize, 2 * cellSize)
        ..lineTo(0, 2 * cellSize)
        ..close();
    case PieceType.square:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(2 * cellSize, 0)
        ..lineTo(2 * cellSize, 3 * cellSize)
        ..lineTo(0, 3 * cellSize)
        ..close();
    case PieceType.zShape:
      return Path()
        ..moveTo(0, cellSize)
        ..lineTo(2 * cellSize, cellSize)
        ..lineTo(2 * cellSize, 0)
        ..lineTo(3 * cellSize, 0)
        ..lineTo(3 * cellSize, 2 * cellSize)
        ..lineTo(cellSize, 2 * cellSize)
        ..lineTo(cellSize, 3 * cellSize)
        ..lineTo(0, 3 * cellSize)
        ..lineTo(0, cellSize)
        ..close();
    case PieceType.yShape:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(4 * cellSize, 0)
        ..lineTo(4 * cellSize, cellSize)
        ..lineTo(3 * cellSize, cellSize)
        ..lineTo(3 * cellSize, 2 * cellSize)
        ..lineTo(2 * cellSize, 2 * cellSize)
        ..lineTo(2 * cellSize, cellSize)
        ..lineTo(0, cellSize)
        ..lineTo(0, 0)
        ..close();
    case PieceType.uShape:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(cellSize, 0)
        ..lineTo(cellSize, cellSize)
        ..lineTo(2 * cellSize, cellSize)
        ..lineTo(2 * cellSize, 0)
        ..lineTo(3 * cellSize, 0)
        ..lineTo(3 * cellSize, 2 * cellSize)
        ..lineTo(0, 2 * cellSize)
        ..close();
    case PieceType.pShape:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(3 * cellSize, 0)
        ..lineTo(3 * cellSize, cellSize)
        ..lineTo(2 * cellSize, cellSize)
        ..lineTo(2 * cellSize, 2 * cellSize)
        ..lineTo(0, 2 * cellSize)
        ..lineTo(0, 0)
        ..close();
    case PieceType.nShape:
      return Path()
        ..moveTo(0, cellSize)
        ..lineTo(cellSize, cellSize)
        ..lineTo(cellSize, 0)
        ..lineTo(4 * cellSize, 0)
        ..lineTo(4 * cellSize, cellSize)
        ..lineTo(2 * cellSize, cellSize)
        ..lineTo(2 * cellSize, 2 * cellSize)
        ..lineTo(0, 2 * cellSize)
        ..lineTo(0, cellSize)
        ..close();
    case PieceType.vShape:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(cellSize, 0)
        ..lineTo(cellSize, 2 * cellSize)
        ..lineTo(3 * cellSize, 2 * cellSize)
        ..lineTo(3 * cellSize, 3 * cellSize)
        ..lineTo(0, 3 * cellSize)
        ..close();
    case PieceType.zone1:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(1 * cellSize, 0)
        ..lineTo(1 * cellSize, 2 * cellSize)
        ..lineTo(0, 2 * cellSize)
        ..close();
    case PieceType.zone2:
      return Path()
        ..moveTo(0, 0)
        ..lineTo(4 * cellSize, 0)
        ..lineTo(4 * cellSize, 1 * cellSize)
        ..lineTo(0, 1 * cellSize)
        ..close();
  }
} 