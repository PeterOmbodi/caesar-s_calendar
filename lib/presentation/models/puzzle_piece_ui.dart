import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/utils/piece_type_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';

typedef GetPieceColor = Color Function();

class PuzzlePieceUI {
  PuzzlePieceUI({
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

  factory PuzzlePieceUI.fromType(
    final PieceType type,
    final Offset position,
    final Offset centerPoint,
    final double cellSize,
  ) {
    final isForbidden = type.isConfigType;
    return PuzzlePieceUI(
      type: type,
      originalPath: generatePathForType(type, cellSize),
      color: () => type.colorForType,
      id: type.idForType,
      position: position,
      centerPoint: centerPoint,
      borderRadius: type.borderRadiusForType,
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

  PuzzlePieceUI copyWith({
    final Offset? position,
    final Offset? centerPoint,
    final double? rotation,
    final bool? isFlipped,
    final bool? isForbidden,
    final Path? originalPath,
    final PlaceZone? placeZone,
    final bool? isUsersItem,
  }) => PuzzlePieceUI(
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
