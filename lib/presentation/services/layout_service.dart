import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_board_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';

class LayoutService {
  const LayoutService();

  static const double collisionTolerance = 2;
  static const double intersectionWidthThreshold = 2;
  static const double gridEdgeTolerance = 5;
  static const double maxCellSize = 50;
  static const int gridRows = 7;
  static const int gridColumns = 7;
  static const double defaultPadding = 16.0;
  static const double wideScreenPadding = 24.0;
  static const double boardExtraX = 1.5;
  static const double gridCenterOffset = 0.5;

  LayoutConfig buildInitialLayout(final Size viewSize, {final Iterable<PuzzlePieceUI> configurationPieces = const []}) {
    final gCellSize = _calcCellSize(viewSize);
    final gLeftPadding = gCellSize < maxCellSize || viewSize.height < viewSize.width
        ? wideScreenPadding
        : (viewSize.width - gCellSize * gridColumns) / 2;

    final gridConfig = PuzzleGridEntity(
      cellSize: gCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(dx: gLeftPadding, dy: defaultPadding),
    );

    final boardConfig = PuzzleBoardEntity(
      cellSize: gCellSize + gLeftPadding / gridColumns,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(
        dx: viewSize.height > viewSize.width
            ? gLeftPadding / 2
            : gridConfig.origin.dx + gridConfig.cellSize * gridConfig.columns + defaultPadding,
        dy: viewSize.height > viewSize.width
            ? gridConfig.origin.dy + gridConfig.cellSize * gridConfig.rows + defaultPadding
            : defaultPadding,
      ),
    );

    final boardX = boardConfig.initialX(gCellSize);
    final boardY = boardConfig.initialY(gCellSize);
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
    final gLeftPadding = gCellSize < maxCellSize || viewSize.height < viewSize.width
        ? wideScreenPadding
        : (viewSize.width - gCellSize * gridColumns) / 2;

    final gridConfig = PuzzleGridEntity(
      cellSize: gCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(dx: gLeftPadding, dy: defaultPadding),
    );

    final boardConfig = PuzzleBoardEntity(
      cellSize: gCellSize + gLeftPadding / gridColumns,
      rows: gridRows,
      columns: gridColumns,
      origin: Position(
        dx: viewSize.height > viewSize.width
            ? gLeftPadding / 2
            : gridConfig.origin.dx + gridConfig.cellSize * gridConfig.columns + defaultPadding,
        dy: viewSize.height > viewSize.width
            ? gridConfig.origin.dy + gridConfig.cellSize * gridConfig.rows + defaultPadding
            : defaultPadding,
      ),
    );

    final boardX = boardConfig.initialX(gCellSize);
    final boardY = boardConfig.initialY(gCellSize);

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

    final prevBoardX = prevBoard.initialX(prevGrid.cellSize);
    final prevBoardY = prevBoard.initialY(prevGrid.cellSize);
    final boardDeltaX = boardX - prevBoardX * gridCellMod;
    final boardDeltaY = boardY - prevBoardY * gridCellMod;

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
    final smallestSide = viewSize.width > viewSize.height ? viewSize.height : viewSize.width;
    final floored = (smallestSide / (gridRows + 1)).floor();
    return floored < maxCellSize ? (floored.isEven ? floored.toDouble() : floored - 1.0) : maxCellSize;
  }
}

class LayoutConfig {
  LayoutConfig({required this.gridConfig, required this.boardConfig, required this.pieces});

  final PuzzleGridEntity gridConfig;
  final PuzzleBoardEntity boardConfig;
  final Iterable<PuzzlePieceUI> pieces;
}
