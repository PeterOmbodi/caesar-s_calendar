import 'dart:math' as math;

import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_board_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';

class LayoutService {
  const LayoutService();

  static const double collisionTolerance = 2;
  static const double intersectionWidthThreshold = 2;
  static const double gridEdgeTolerance = 5;
  static const double maxCellSize = 50;
  static const double boardToGridSizeRatio = 1.2;
  static const double horizontalContentPadding = 8.0;
  static const int gridRows = 7;
  static const int gridColumns = 7;
  static const double defaultPadding = 16.0;
  static const double wideScreenPadding = 24.0;
  static const double boardExtraX = 1.5;
  static const double gridCenterOffset = 0.5;

  LayoutConfig buildInitialLayout(final Size viewSize, {final Iterable<PuzzlePieceUI> configurationPieces = const []}) {
    final gCellSize = _calcCellSize(viewSize);
    final boardCellSize = _calcBoardCellSize(gCellSize);
    final positions = _calcLayoutPositions(viewSize, gCellSize, boardCellSize);

    final gridConfig = PuzzleGridEntity(
      cellSize: gCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(dx: positions.grid.dx, dy: positions.grid.dy),
    );

    final boardConfig = PuzzleBoardEntity(
      cellSize: boardCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(dx: positions.board.dx, dy: positions.board.dy),
    );

    final boardInitialOrigin = _initialBoardPieceOrigin(boardConfig, gCellSize);
    final boardX = boardInitialOrigin.dx;
    final boardY = boardInitialOrigin.dy;
    final cellXOffset = gCellSize + boardExtraX;

    final centerPoint = Offset(gCellSize * gridCenterOffset, gCellSize * gridCenterOffset);
    final boardPieces = [
      PuzzlePieceUI.fromType(PieceType.lShape, Offset(boardX, boardY + gCellSize * 4), centerPoint, gCellSize),
      PuzzlePieceUI.fromType(
        PieceType.square,
        Offset(boardX + cellXOffset * 5 + boardExtraX, boardY + gCellSize * 2),
        centerPoint,
        gCellSize,
      ),
      PuzzlePieceUI.fromType(PieceType.zShape, Offset(boardX + cellXOffset * 4, boardY), centerPoint, gCellSize),
      PuzzlePieceUI.fromType(
        PieceType.yShape,
        Offset(boardX + boardExtraX * 2, boardY + gCellSize * 2),
        centerPoint,
        gCellSize,
      ),
      PuzzlePieceUI.fromType(
        PieceType.uShape,
        Offset(boardX + cellXOffset + boardExtraX, boardY + gCellSize * 3),
        centerPoint,
        gCellSize,
      ),
      PuzzlePieceUI.fromType(PieceType.pShape, Offset(boardX, boardY), centerPoint, gCellSize),
      PuzzlePieceUI.fromType(PieceType.nShape, Offset(boardX + 2 * cellXOffset, boardY), centerPoint, gCellSize),
      PuzzlePieceUI.fromType(
        PieceType.vShape,
        Offset(boardX + cellXOffset * 4, boardY + gCellSize * 3),
        centerPoint,
        gCellSize,
      ),
    ];

    final gridPieces = configurationPieces.isNotEmpty
        ? configurationPieces.toList()
        : [
            PuzzlePieceUI.fromType(
              PieceType.zone1,
              Offset(gridConfig.origin.dx + gCellSize * 6, gridConfig.origin.dy),
              centerPoint,
              gCellSize,
            ),
            PuzzlePieceUI.fromType(
              PieceType.zone2,
              Offset(gridConfig.origin.dx + gCellSize * 3, gridConfig.origin.dy + gCellSize * 6),
              centerPoint,
              gCellSize,
            ),
          ];

    return LayoutConfig(gridConfig: gridConfig, boardConfig: boardConfig, pieces: [...gridPieces, ...boardPieces]);
  }

  LayoutConfig rebuildLayout({
    required final Size viewSize,
    required final PuzzleGridEntity prevGrid,
    required final PuzzleBoardEntity prevBoard,
    required final Iterable<PuzzlePieceUI> pieces,
  }) {
    final gCellSize = _calcCellSize(viewSize);
    final boardCellSize = _calcBoardCellSize(gCellSize);
    final positions = _calcLayoutPositions(viewSize, gCellSize, boardCellSize);

    final gridConfig = PuzzleGridEntity(
      cellSize: gCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(dx: positions.grid.dx, dy: positions.grid.dy),
    );

    final boardConfig = PuzzleBoardEntity(
      cellSize: boardCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(dx: positions.board.dx, dy: positions.board.dy),
    );

    final boardInitialOrigin = _initialBoardPieceOrigin(boardConfig, gCellSize);

    final gridCellMod = gCellSize / prevGrid.cellSize;

    final prevGridX = prevGrid.origin.dx;
    final prevGridY = prevGrid.origin.dy;
    final gridDeltaX = gridConfig.origin.dx - prevGridX * gridCellMod;
    final gridDeltaY = gridConfig.origin.dy - prevGridY * gridCellMod;

    final centerPoint = Offset(gCellSize * gridCenterOffset, gCellSize * gridCenterOffset);

    final gridPieces = pieces
        .where((final p) => p.placeZone == PlaceZone.grid)
        .map(
          (final p) => p.copyWith(
            originalPath: generatePathForType(p.type, gCellSize),
            position: gridConfig.snapToGrid(
              Offset(p.position.dx * gridCellMod + gridDeltaX, p.position.dy * gridCellMod + gridDeltaY),
            ),
            centerPoint: centerPoint,
          ),
        )
        .toList();

    final prevBoardInitialOrigin = _initialBoardPieceOrigin(prevBoard, prevGrid.cellSize);
    final boardDeltaX = boardInitialOrigin.dx - prevBoardInitialOrigin.dx * gridCellMod;
    final boardDeltaY = boardInitialOrigin.dy - prevBoardInitialOrigin.dy * gridCellMod;

    final boardPieces = pieces
        .where((final p) => p.placeZone == PlaceZone.board)
        .map(
          (final p) => p.copyWith(
            originalPath: generatePathForType(p.type, gCellSize),
            position: Offset(p.position.dx * gridCellMod + boardDeltaX, p.position.dy * gridCellMod + boardDeltaY),
            centerPoint: centerPoint,
          ),
        )
        .toList();

    return LayoutConfig(gridConfig: gridConfig, boardConfig: boardConfig, pieces: [...gridPieces, ...boardPieces]);
  }

  double _calcCellSize(final Size viewSize) {
    final isPortrait = viewSize.height > viewSize.width;
    final gridAndBoardCells = gridRows * (1 + boardToGridSizeRatio);
    final horizontalInsets = horizontalContentPadding * 2;
    final mainAxisAvailable = isPortrait
        ? viewSize.height - defaultPadding
        : viewSize.width - defaultPadding - horizontalInsets;
    final mainAxisCellSize = mainAxisAvailable / gridAndBoardCells;
    final crossAxisCellSize = isPortrait
        ? (viewSize.width - horizontalInsets) / (gridColumns * boardToGridSizeRatio)
        : viewSize.height / (gridRows * boardToGridSizeRatio);
    final floored = math.min(mainAxisCellSize, crossAxisCellSize).floor();
    return floored.isEven ? floored.toDouble() : floored - 1.0;
  }

  double _calcBoardCellSize(final double gridCellSize) => gridCellSize * boardToGridSizeRatio;

  ({Offset grid, Offset board}) _calcLayoutPositions(
    final Size viewSize,
    final double gridCellSize,
    final double boardCellSize,
  ) {
    final gridWidth = gridColumns * gridCellSize;
    final gridHeight = gridRows * gridCellSize;
    final boardWidth = gridColumns * boardCellSize;
    final boardHeight = gridRows * boardCellSize;
    final isPortrait = viewSize.height > viewSize.width;

    if (isPortrait) {
      final contentWidth = math.max(gridWidth, boardWidth);
      final contentHeight = gridHeight + defaultPadding + boardHeight;
      final left = horizontalContentPadding + (viewSize.width - horizontalContentPadding * 2 - contentWidth) / 2;
      final top = (viewSize.height - contentHeight) / 2;
      return (
        grid: Offset(left + (contentWidth - gridWidth) / 2, top),
        board: Offset(left + (contentWidth - boardWidth) / 2, top + gridHeight + defaultPadding),
      );
    }

    final contentWidth = gridWidth + defaultPadding + boardWidth;
    final contentHeight = math.max(gridHeight, boardHeight);
    final left = horizontalContentPadding + (viewSize.width - horizontalContentPadding * 2 - contentWidth) / 2;
    final top = (viewSize.height - contentHeight) / 2;
    return (
      grid: Offset(left, top + (contentHeight - gridHeight) / 2),
      board: Offset(left + gridWidth + defaultPadding, top + (contentHeight - boardHeight) / 2),
    );
  }

  Offset _initialBoardPieceOrigin(final PuzzleBoardEntity board, final double cellSize) =>
      Offset(board.getBounds.center.dx - (7 * cellSize + 6 * boardExtraX) / 2, board.initialY(cellSize));
}

class LayoutConfig {
  LayoutConfig({required this.gridConfig, required this.boardConfig, required this.pieces});

  final PuzzleGridEntity gridConfig;
  final PuzzleBoardEntity boardConfig;
  final Iterable<PuzzlePieceUI> pieces;
}
