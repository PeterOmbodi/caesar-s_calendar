import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/services/move_history_service.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const layoutService = LayoutService();
  const historyService = MoveHistoryService();
  final portrait = layoutService.buildInitialLayout(Offset.zero & const Size(393, 640), maxCell: 56);
  final landscape = layoutService.buildInitialLayout(Offset.zero & const Size(1200, 800), maxCell: 80);
  final before = portrait.pieces.firstWhere((final p) => p.id == 'Square');
  final after = landscape.pieces.firstWhere((final p) => p.id == 'Square');
  final relative = portrait.boardConfig.relativePosition(before.position);
  final trayPlacement = MovePlacement(
    zone: PlaceZone.board,
    position: Position(dx: relative.dx, dy: relative.dy),
  );
  final gridPlacement = MovePlacement(position: const Position(dx: 2, dy: 2));

  test('undoing a hint after resize returns to the centered tray coordinates', () {
    final state = PuzzleState.initial().copyWith(
      gridConfig: landscape.gridConfig,
      boardConfig: landscape.boardConfig,
      pieces: landscape.pieces.toList(),
      moveHistory: [
        HintMove(
          before.id,
          from: trayPlacement,
          to: gridPlacement,
          rotationFrom: 0,
          rotationTo: 90,
          flippedFrom: false,
          flippedTo: true,
        ),
      ],
    );
    final restored = historyService.historyPiece(
      state: state,
      idx: 0,
      isUndo: true,
      rotationStep: 90,
      fullRotation: 360,
    );
    expect((restored.position - after.position).distance, closeTo(0, 0.001));
    expect(restored.placeZone, PlaceZone.board);
    expect(restored.rotation, 0);
    expect(restored.isFlipped, isFalse);
  });

  for (final flip in [false, true]) {
    for (final undo in [false, true]) {
      test(
        '${flip ? 'flip' : 'rotation'} snap correction uses centered tray coordinates on ${undo ? 'undo' : 'redo'}',
        () {
          final correction = MovePiece(
            before.id,
            from: trayPlacement,
            to: MovePlacement(
              zone: PlaceZone.board,
              position: Position(dx: relative.dx - 1, dy: relative.dy + 0.5),
            ),
          );
          final move = flip
              ? FlipPiece(before.id, correction, isFlipped: true)
              : RotatePiece(before.id, correction, rotation: 90);
          final state = PuzzleState.initial().copyWith(
            gridConfig: landscape.gridConfig,
            boardConfig: landscape.boardConfig,
            pieces: landscape.pieces.toList(),
            moveHistory: [move],
          );
          final restored = historyService.historyPiece(
            state: state,
            idx: 0,
            isUndo: undo,
            rotationStep: 90,
            fullRotation: 360,
          );
          final expected =
              after.position +
              (undo ? Offset.zero : Offset(-landscape.boardConfig.cellSize, landscape.boardConfig.cellSize / 2));
          expect((restored.position - expected).distance, closeTo(0, 0.001));
        },
      );
    }
  }
}
