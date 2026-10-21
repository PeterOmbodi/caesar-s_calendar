import 'dart:math' as math;

import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/utils/piece_type_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/painting.dart';

Set<Cell> blockedCellsOf(final Iterable<PlacementParams> placements) {
  const unit = 10.0;
  const center = Offset(unit * LayoutService.gridCenterOffset, unit * LayoutService.gridCenterOffset);
  return {
    for (final p in placements)
      ...PuzzlePieceUI.fromType(
        PieceType.values.firstWhere((final type) => type.idForType == p.pieceId),
        Offset(p.col * unit, p.row * unit),
        center,
        unit,
      ).copyWith(rotation: p.rotationSteps * math.pi / 2, isFlipped: p.isFlipped).cells(const Position.zero(), unit),
  };
}

/// Same cells give the same key, however the blocks that cover them are turned.
String cellsKey(final Iterable<Cell> cells) =>
    (cells.map((final c) => c.row * 100 + c.col).toList()..sort()).join(',');
