import 'dart:math' as math;

import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';

class PieceShapeMatch {
  const PieceShapeMatch({required this.piece, required this.position, required this.rotation, required this.isFlipped});

  final PuzzlePieceUI piece;
  final Offset position;
  final double rotation;
  final bool isFlipped;
}

class PieceShapeMatcher {
  const PieceShapeMatcher();

  static const double rotationStep = math.pi / 2;

  PieceShapeMatch? match({
    required final DrawnGroup group,
    required final Iterable<PuzzlePieceUI> candidates,
    required final PuzzleGridEntity grid,
  }) {
    final targetCells = group.cellSet;
    if (targetCells.isEmpty) {
      return null;
    }
    final normalizedTarget = _normalize(targetCells);
    final targetMin = _minCell(targetCells);
    final matches = <PieceShapeMatch>[];

    for (final candidate in candidates.where((final piece) => !piece.isConfigItem)) {
      for (final isFlipped in const [false, true]) {
        for (var rotationSteps = 0; rotationSteps < 4; rotationSteps++) {
          final rotation = rotationSteps * rotationStep;
          final probe = candidate.copyWith(
            originalPath: generatePathForType(candidate.type, grid.cellSize),
            centerPoint: Offset(grid.cellSize / 2, grid.cellSize / 2),
            position: Offset.zero,
            rotation: rotation,
            isFlipped: isFlipped,
            placeZone: PlaceZone.grid,
          );
          final probeCells = probe.cells(Position.zero(), grid.cellSize);
          if (probeCells.length != targetCells.length) {
            continue;
          }
          if (!_sameCells(_normalize(probeCells), normalizedTarget)) {
            continue;
          }

          final probeMin = _minCell(probeCells);
          final targetOriginCell = Cell(targetMin.row - probeMin.row, targetMin.col - probeMin.col);
          matches.add(
            PieceShapeMatch(
              piece: candidate,
              position: grid.cellTopLeft(targetOriginCell),
              rotation: rotation,
              isFlipped: isFlipped,
            ),
          );
        }
      }
    }

    if (matches.isEmpty) {
      return null;
    }
    matches.sort((final a, final b) {
      final exactA = _currentCellsMatch(a.piece, targetCells, grid) ? 0 : 1;
      final exactB = _currentCellsMatch(b.piece, targetCells, grid) ? 0 : 1;
      if (exactA != exactB) return exactA.compareTo(exactB);

      final gridA = a.piece.placeZone == PlaceZone.grid ? 0 : 1;
      final gridB = b.piece.placeZone == PlaceZone.grid ? 0 : 1;
      if (gridA != gridB) return gridA.compareTo(gridB);

      final boardA = a.piece.placeZone == PlaceZone.board ? 0 : 1;
      final boardB = b.piece.placeZone == PlaceZone.board ? 0 : 1;
      if (boardA != boardB) return boardA.compareTo(boardB);

      return a.piece.id.compareTo(b.piece.id);
    });
    return matches.first;
  }

  bool _currentCellsMatch(final PuzzlePieceUI piece, final Set<Cell> targetCells, final PuzzleGridEntity grid) {
    if (piece.placeZone != PlaceZone.grid) {
      return false;
    }
    final currentCells = piece.cells(grid.origin, grid.cellSize);
    return currentCells.length == targetCells.length && currentCells.containsAll(targetCells);
  }

  Set<Cell> _normalize(final Set<Cell> cells) {
    final min = _minCell(cells);
    return cells.map((final cell) => Cell(cell.row - min.row, cell.col - min.col)).toSet();
  }

  Cell _minCell(final Set<Cell> cells) {
    var minRow = 1 << 30;
    var minCol = 1 << 30;
    for (final cell in cells) {
      if (cell.row < minRow) {
        minRow = cell.row;
      }
      if (cell.col < minCol) {
        minCol = cell.col;
      }
    }
    return Cell(minRow, minCol);
  }

  bool _sameCells(final Set<Cell> a, final Set<Cell> b) => a.length == b.length && a.containsAll(b);
}
