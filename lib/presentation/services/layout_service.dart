import 'dart:math' as math;

import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';

class LayoutService {
  const LayoutService();

  static const double collisionTolerance = 2;
  static const double intersectionWidthThreshold = 2;
  static const double gridEdgeTolerance = 5;
  static const double horizontalContentPadding = 8.0;
  static const int gridRows = 7;
  static const int gridColumns = 7;
  static const int trayRows = 6;
  static const int trayColumns = 7;
  static const double defaultPadding = 16.0;
  static const double gridCenterOffset = 0.5;
  static const double statusLineGap = 8;
  static const double statusLineHeight = 20;
  static const double statusLineExtent = statusLineGap + statusLineHeight;

  /// Top-left tray cell of each piece; together they fill the 7×6 tray.
  static const Map<PieceType, (int col, int row)> traySlots = {
    PieceType.lShape: (0, 4),
    PieceType.square: (5, 2),
    PieceType.zShape: (4, 0),
    PieceType.yShape: (0, 2),
    PieceType.uShape: (1, 3),
    PieceType.pShape: (0, 0),
    PieceType.nShape: (2, 0),
    PieceType.vShape: (4, 3),
  };

  LayoutConfig buildInitialLayout(
    final Rect contentRect, {
    required final double maxCell,
    final double trayScale = PuzzlePieceUI.defaultTrayScale,
    final bool fillAvailableTray = false,
    final double trayTopInset = 0,
    final Iterable<PuzzlePieceUI> configurationPieces = const [],
  }) {
    final gCellSize = _calcCellSize(contentRect.size, maxCell, trayScale);
    final (:gridConfig, :boardConfig) = _buildConfigs(
      contentRect,
      gCellSize,
      trayScale,
      fillAvailableTray,
      trayTopInset,
    );
    final centerPoint = Offset(gCellSize * gridCenterOffset, gCellSize * gridCenterOffset);
    final trayCell = boardConfig.cellSize;

    final boardPieces = [
      for (final MapEntry(key: type, value: (col, row)) in traySlots.entries)
        PuzzlePieceUI.fromType(
          type,
          boardConfig.absolutPosition(Offset(col.toDouble(), row.toDouble())),
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

    return LayoutConfig(
      gridConfig: gridConfig,
      boardConfig: boardConfig,
      trayArea: _trayArea(contentRect, gridConfig, trayTopInset),
      pieces: [
        for (final p in [...gridPieces, ...boardPieces]) p.copyWith(trayScale: trayCell / gCellSize),
      ],
    );
  }

  LayoutConfig rebuildLayout({
    required final Rect contentRect,
    required final double maxCell,
    required final PuzzleGridEntity prevGrid,
    required final PuzzleBoardEntity prevBoard,
    required final Iterable<PuzzlePieceUI> pieces,
    final double trayScale = PuzzlePieceUI.defaultTrayScale,
    final bool fillAvailableTray = false,
    final double trayTopInset = 0,
  }) {
    final gCellSize = _calcCellSize(contentRect.size, maxCell, trayScale);
    final (:gridConfig, :boardConfig) = _buildConfigs(
      contentRect,
      gCellSize,
      trayScale,
      fillAvailableTray,
      trayTopInset,
    );
    final centerPoint = Offset(gCellSize * gridCenterOffset, gCellSize * gridCenterOffset);

    Offset remap(final Offset position, final PuzzleBaseEntity from, final PuzzleBaseEntity to) =>
        to.absolutPosition(from.relativePosition(position));

    final rebuilt = pieces.map((final p) {
      final onGrid = p.placeZone == PlaceZone.grid;
      final position = onGrid
          ? gridConfig.snapToGrid(remap(p.position, prevGrid, gridConfig))
          : remap(p.position, prevBoard, boardConfig);
      final resized = p.copyWith(
        originalPath: generatePathForType(p.type, gCellSize),
        position: position,
        centerPoint: centerPoint,
        trayScale: boardConfig.cellSize / gCellSize,
      );
      if (onGrid) {
        return resized;
      }
      final clamped = resized.positionInside(boardConfig.getBounds);
      // Path bounds use float precision; avoid accumulating negligible shifts on rotation.
      return (clamped - resized.position).distance < 0.001 ? resized : resized.copyWith(position: clamped);
    });

    return LayoutConfig(
      gridConfig: gridConfig,
      boardConfig: boardConfig,
      trayArea: _trayArea(contentRect, gridConfig, trayTopInset),
      pieces: rebuilt.toList(),
    );
  }

  double _calcCellSize(final Size viewSize, final double maxCell, final double tray) {
    final isPortrait = viewSize.height > viewSize.width;
    final horizontalInsets = horizontalContentPadding * 2;
    final availableWidth = viewSize.width - defaultPadding - horizontalInsets;
    final mainAxisCellSize = isPortrait
        ? (viewSize.height - defaultPadding) / (gridRows + trayRows * tray)
        : math.max(
            availableWidth / (gridColumns + trayColumns),
            // Small boards need smaller tray cells to leave room for the status line.
            (availableWidth * trayRows + trayColumns * statusLineExtent) /
                (gridColumns * trayRows + trayColumns * gridRows),
          );
    final crossAxisCellSize = isPortrait
        ? (viewSize.width - horizontalInsets) / gridColumns
        : viewSize.height / gridRows;
    final floored = math.min(math.min(mainAxisCellSize, crossAxisCellSize), maxCell).floor();
    return floored.isEven ? floored.toDouble() : floored - 1.0;
  }

  /// Room for the enlarged tray piece: the content area beside or below the board.
  Rect _trayArea(final Rect contentRect, final PuzzleGridEntity grid, final double trayTopInset) {
    final board = grid.getBounds;
    return contentRect.height > contentRect.width
        ? Rect.fromLTRB(
            contentRect.left + horizontalContentPadding,
            board.bottom + horizontalContentPadding,
            contentRect.right - horizontalContentPadding,
            contentRect.bottom,
          )
        : Rect.fromLTRB(
            board.right + horizontalContentPadding,
            contentRect.top + trayTopInset,
            contentRect.right - horizontalContentPadding,
            contentRect.bottom,
          );
  }

  ({PuzzleGridEntity gridConfig, PuzzleBoardEntity boardConfig}) _buildConfigs(
    final Rect contentRect,
    final double gridCellSize,
    final double trayScale,
    final bool fillAvailableTray,
    final double trayTopInset,
  ) {
    final viewSize = contentRect.size;
    final gridSize = Size(gridColumns * gridCellSize, gridRows * gridCellSize);
    final isPortrait = viewSize.height > viewSize.width;
    final availableTrayWidth =
        viewSize.width - horizontalContentPadding * 2 - (isPortrait ? 0 : gridSize.width + defaultPadding);
    final availableTrayHeight = viewSize.height - (isPortrait ? gridSize.height + defaultPadding : 0);
    final gridTop = contentRect.top + (viewSize.height - gridSize.height) / 2;
    // In landscape the tray sits under the header and above the status line, at most at board scale.
    // A header measured mid-rotation can be too tall; the tray keeps at least half the board height.
    final landscapeTrayTop = math.min(
      math.max(gridTop, contentRect.top + trayTopInset),
      gridTop + gridSize.height / 2,
    );
    final landscapeTrayHeight = gridTop + gridSize.height - statusLineExtent - landscapeTrayTop;
    final trayCellSize = !isPortrait
        ? math.min(
            gridCellSize,
            trayTopInset > 0
                ? math.min(landscapeTrayHeight / trayRows, availableTrayWidth / trayColumns)
                : landscapeTrayHeight / trayRows,
          )
        : fillAvailableTray
        ? math.min(gridCellSize, math.min(availableTrayWidth / trayColumns, availableTrayHeight / trayRows))
        : gridCellSize * trayScale;
    final traySize = Size(trayColumns * trayCellSize, trayRows * trayCellSize);

    final Offset grid;
    final Offset tray;
    if (isPortrait) {
      final contentWidth = math.max(gridSize.width, traySize.width);
      final contentHeight = gridSize.height + defaultPadding + traySize.height;
      final left =
          contentRect.left +
          horizontalContentPadding +
          (viewSize.width - horizontalContentPadding * 2 - contentWidth) / 2;
      final top = contentRect.top + (viewSize.height - contentHeight) / 2;
      grid = Offset(left + (contentWidth - gridSize.width) / 2, top);
      tray = Offset(contentRect.left + horizontalContentPadding, top + gridSize.height + defaultPadding);
    } else {
      grid = Offset(contentRect.left + horizontalContentPadding, gridTop);
      tray = Offset(grid.dx + gridSize.width + defaultPadding, landscapeTrayTop);
    }

    return (
      gridConfig: PuzzleGridEntity(
        cellSize: gridCellSize,
        rows: gridRows,
        columns: gridColumns,
        origin: Position(dx: grid.dx, dy: grid.dy),
      ),
      boardConfig: PuzzleBoardEntity(
        cellSize: trayCellSize,
        rows: trayRows,
        columns: trayColumns,
        origin: Position(dx: tray.dx, dy: tray.dy),
        availableWidth: availableTrayWidth,
        availableHeight: isPortrait ? contentRect.bottom - tray.dy : landscapeTrayHeight,
      ),
    );
  }
}

class LayoutConfig {
  LayoutConfig({required this.gridConfig, required this.boardConfig, required this.trayArea, required this.pieces});

  final PuzzleGridEntity gridConfig;
  final PuzzleBoardEntity boardConfig;
  final Rect trayArea;
  final Iterable<PuzzlePieceUI> pieces;
}
