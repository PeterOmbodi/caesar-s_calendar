import 'package:caesar_puzzle/core/models/puzzle_piece_base.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_utils.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

enum PieceType { lShape, square, zShape, yShape, uShape, pShape, nShape, vShape, zone1, zone2 }

Color colorForType(PieceType type) {
  switch (type) {
    case PieceType.lShape:
      return Colors.teal.withValues(alpha: 0.8);
    case PieceType.square:
      return Colors.indigo.withValues(alpha: 0.8);
    case PieceType.zShape:
      return Colors.brown.withValues(alpha: 0.8);
    case PieceType.yShape:
      return Colors.blueGrey.withValues(alpha: 0.8);
    case PieceType.uShape:
      return Colors.grey.withValues(alpha: 0.8);
    case PieceType.pShape:
      return Colors.deepPurple.withValues(alpha: 0.8);
    case PieceType.nShape:
      return Colors.blue.withValues(alpha: 0.8);
    case PieceType.vShape:
      return Colors.cyan.withValues(alpha: 0.8);
    case PieceType.zone1:
    case PieceType.zone2:
      return AppColors.current.primary.withAlpha(50);
  }
}

String idForType(PieceType type) {
  switch (type) {
    case PieceType.lShape:
      return 'L-Shape';
    case PieceType.square:
      return 'Square';
    case PieceType.zShape:
      return 'Z-Shape';
    case PieceType.yShape:
      return 'Y-Shape';
    case PieceType.uShape:
      return 'U-Shape';
    case PieceType.pShape:
      return 'P-Shape';
    case PieceType.nShape:
      return 'N-Shape';
    case PieceType.vShape:
      return 'V-Shape';
    case PieceType.zone1:
      return 'zone1';
    case PieceType.zone2:
      return 'zone2';
  }
}

bool isForbiddenType(PieceType type) {
  return type == PieceType.zone1 || type == PieceType.zone2;
}

double borderRadiusForType(PieceType type) {
  return isForbiddenType(type) ? 0 : 8.0;
}

typedef GetPieceColor = Color Function();

class PuzzlePiece extends PuzzlePieceBase {
  final PieceType type;
  final Path originalPath;
  final GetPieceColor color;
  final Offset centerPoint;
  final double borderRadius;
  final bool isForbidden;
  final bool isUserMove;

  PuzzlePiece({
    required super.id,
    required super.position,
    super.rotation = 0.0,
    super.isFlipped = false,
    required super.placeZone,
    required this.type,
    required this.originalPath,
    required this.color,
    required this.centerPoint,
    this.borderRadius = 8.0,
    this.isForbidden = false,
    this.isUserMove = true,
  });

  factory PuzzlePiece.fromType(PieceType type, Offset position, Offset centerPoint, double cellSize) {
    final isForbidden = isForbiddenType(type);
    return PuzzlePiece(
      type: type,
      originalPath: generatePathForType(type, cellSize),
      color: () => colorForType(type),
      id: idForType(type),
      position: position,
      centerPoint: centerPoint,
      borderRadius: borderRadiusForType(type),
      isForbidden: isForbidden,
      placeZone: isForbidden ? PlaceZone.grid : PlaceZone.board,
    );
  }

  PuzzlePiece copyWith({
    Offset? position,
    Offset? centerPoint,
    double? rotation,
    bool? isFlipped,
    bool? isForbidden,
    Path? originalPath,
    PlaceZone? placeZone,
    bool? isUserMove,
  }) {
    return PuzzlePiece(
      type: type,
      originalPath: originalPath ?? this.originalPath,
      color: color,
      id: id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      centerPoint: centerPoint ?? this.centerPoint,
      isFlipped: isFlipped ?? this.isFlipped,
      borderRadius: borderRadius,
      isForbidden: isForbidden ?? this.isForbidden,
      placeZone: placeZone ?? this.placeZone,
      isUserMove: isUserMove ?? this.isUserMove,
    );
  }

  Color borderColor(bool borderColorMode) =>
      isUserMove || !borderColorMode ? AppColors.current.pieceBorder : Colors.transparent;
}
