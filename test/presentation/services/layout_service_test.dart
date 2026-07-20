import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LayoutService();

  test('buildInitialLayout centers the board-piece group horizontally in both orientations', () {
    for (final size in [const Size(400, 800), const Size(800, 400)]) {
      final layout = service.buildInitialLayout(size);

      _expectHorizontallyCenteredAndInsideBoard(layout);
      expect(
        _boardPieceBounds(layout).top,
        closeTo(layout.boardConfig.origin.dy + layout.gridConfig.cellSize / 4, 0.001),
      );
    }
  });

  test('rebuildLayout keeps the board-piece group centered after an orientation change', () {
    for (final (from, to) in [
      (const Size(400, 800), const Size(800, 400)),
      (const Size(800, 400), const Size(400, 800)),
    ]) {
      final initial = service.buildInitialLayout(from);
      final rebuilt = service.rebuildLayout(
        viewSize: to,
        prevGrid: initial.gridConfig,
        prevBoard: initial.boardConfig,
        pieces: initial.pieces,
      );

      _expectHorizontallyCenteredAndInsideBoard(rebuilt);
    }
  });

  test('tablet portrait sizes grid and board by vertical ratio', () {
    final layout = service.buildInitialLayout(const Size(1024, 1366));

    expect(layout.gridConfig.cellSize, greaterThan(LayoutService.maxCellSize));
    expect(_boardAxisRatio(layout), closeTo(LayoutService.boardToGridSizeRatio, 0.001));
    expect(_contentBounds(layout).bottom, lessThanOrEqualTo(1366));
    expect(_contentBounds(layout).center.dx, closeTo(1024 / 2, 0.001));
    expect(_contentBounds(layout).center.dy, closeTo(1366 / 2, 0.001));
  });

  test('tablet landscape sizes grid and board by horizontal ratio', () {
    final layout = service.buildInitialLayout(const Size(1366, 1024));

    expect(layout.gridConfig.cellSize, greaterThan(LayoutService.maxCellSize));
    expect(_boardAxisRatio(layout), closeTo(LayoutService.boardToGridSizeRatio, 0.001));
    expect(_contentBounds(layout).right, lessThanOrEqualTo(1366));
    expect(_contentBounds(layout).center.dx, closeTo(1366 / 2, 0.001));
    expect(_contentBounds(layout).center.dy, closeTo(1024 / 2, 0.001));
  });

  test('wide landscape centers content in the gameplay area beside settings panel', () {
    const screenWidth = 1366.0;
    const settingsPanelWidth = 340.0;
    const gameplaySize = Size(screenWidth - settingsPanelWidth, 1024);

    final layout = service.buildInitialLayout(gameplaySize);

    expect(_contentBounds(layout).center.dx, closeTo(gameplaySize.width / 2, 0.001));
  });

  test('keeps horizontal padding around grid and board content', () {
    final layout = service.buildInitialLayout(const Size(760, 700));
    final contentBounds = _contentBounds(layout);

    expect(contentBounds.left, greaterThanOrEqualTo(LayoutService.horizontalContentPadding));
    expect(contentBounds.right, lessThanOrEqualTo(760 - LayoutService.horizontalContentPadding));
  });
}

double _boardAxisRatio(final LayoutConfig layout) => layout.boardConfig.cellSize / layout.gridConfig.cellSize;

Rect _contentBounds(final LayoutConfig layout) =>
    layout.gridConfig.getBounds.expandToInclude(layout.boardConfig.getBounds);

Rect _boardPieceBounds(final LayoutConfig layout) => layout.pieces
    .where((final piece) => piece.placeZone == PlaceZone.board)
    .map((final piece) => piece.getTransformedPath().getBounds())
    .reduce((final bounds, final pieceBounds) => bounds.expandToInclude(pieceBounds));

void _expectHorizontallyCenteredAndInsideBoard(final LayoutConfig layout) {
  final groupBounds = _boardPieceBounds(layout);
  final boardBounds = layout.boardConfig.getBounds;

  expect(groupBounds.center.dx, closeTo(boardBounds.center.dx, 0.5));
  expect(groupBounds.left, greaterThanOrEqualTo(boardBounds.left));
  expect(groupBounds.right, lessThanOrEqualTo(boardBounds.right));
  expect(groupBounds.top, greaterThanOrEqualTo(boardBounds.top));
  expect(groupBounds.bottom, lessThanOrEqualTo(boardBounds.bottom));
}
