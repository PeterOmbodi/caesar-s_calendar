import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_utils.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

Color colorForType(final PieceType type) {
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

String idForType(final PieceType type) {
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

bool isConfigType(final PieceType type) => type == PieceType.zone1 || type == PieceType.zone2;

double borderRadiusForType(final PieceType type) => isConfigType(type) ? 0 : 8.0;

typedef GetPieceColor = Color Function();

class PuzzlePiece {
  PuzzlePiece({
    required this.id,
    required this.position,
    this.rotation = 0.0,
    this.isFlipped = false,
    required this.placeZone,
    required this.type,
    required this.originalPath,
    required this.color,
    required this.centerPoint,
    this.borderRadius = 8.0,
    this.isConfigItem = false,
    this.isUsersItem = true,
  });

  factory PuzzlePiece.fromType(final PieceType type, final Offset position, final Offset centerPoint, final double cellSize) {
    final isForbidden = isConfigType(type);
    return PuzzlePiece(
      type: type,
      originalPath: generatePathForType(type, cellSize),
      color: () => colorForType(type),
      id: idForType(type),
      position: position,
      centerPoint: centerPoint,
      borderRadius: borderRadiusForType(type),
      isConfigItem: isForbidden,
      placeZone: isForbidden ? PlaceZone.grid : PlaceZone.board,
    );
  }

  final PieceType type;
  final Path originalPath;
  final GetPieceColor color;
  final Offset centerPoint;
  final double borderRadius;
  final bool isConfigItem;
  final bool isUsersItem;
  final String id;
  final Offset position;
  final double rotation;
  final bool isFlipped;
  final PlaceZone placeZone;

  PuzzlePiece copyWith({
    final Offset? position,
    final Offset? centerPoint,
    final double? rotation,
    final bool? isFlipped,
    final bool? isForbidden,
    final Path? originalPath,
    final PlaceZone? placeZone,
    final bool? isUsersItem,
  }) =>
      PuzzlePiece(
        type: type,
        originalPath: originalPath ?? this.originalPath,
        color: color,
        id: id,
        position: position ?? this.position,
        rotation: rotation ?? this.rotation,
        centerPoint: centerPoint ?? this.centerPoint,
        isFlipped: isFlipped ?? this.isFlipped,
        borderRadius: borderRadius,
        isConfigItem: isForbidden ?? isConfigItem,
        placeZone: placeZone ?? this.placeZone,
        isUsersItem: isUsersItem ?? this.isUsersItem,
      );

  Color borderColor(final bool borderColorMode) =>
      isUsersItem || !borderColorMode ? AppColors.current.pieceBorder : Colors.transparent;

  PuzzlePieceEntity toDomain(final PuzzleGridEntity grid) => PuzzlePieceEntity(
        id: id,
        type: type,
        placeZone: placeZone,
        relativeCells: relativeCells(grid.cellSize),
        absoluteCells: cells(grid.origin, grid.cellSize),
        isConfigItem: isConfigItem,
        isUsersItem: isUsersItem,
      );
}
