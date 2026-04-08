import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';

PuzzlePieceUI findOnboardingPShape(final PuzzleState state) => state.pieces.firstWhere(
  (final piece) => piece.type == PieceType.pShape && !piece.isConfigItem,
  orElse: () => state.pieces.first,
);

PuzzlePieceUI? buildDragDemoTargetPiece(final PuzzleState puzzleState) {
  final sourcePiece = puzzleState.pieces
      .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
      .cast<PuzzlePieceUI?>()
      .firstWhere((final piece) => piece != null, orElse: () => null);
  if (sourcePiece == null) {
    return null;
  }

  final targetTopLeft = Offset(
    puzzleState.gridConfig.origin.dx + 3 * puzzleState.gridConfig.cellSize,
    puzzleState.gridConfig.origin.dy,
  );

  return sourcePiece.copyWith(position: targetTopLeft, placeZone: PlaceZone.grid);
}

Rect buildDragInteractionHole(final PuzzleState puzzleState) {
  final baseRect = puzzleState.gridConfig.getBounds
      .expandToInclude(puzzleState.boardConfig.getBounds)
      .inflate(8);
  final sourcePiece = puzzleState.boardPieces
      .where((final piece) => piece.type == PieceType.pShape && !piece.isConfigItem)
      .cast<PuzzlePieceUI?>()
      .firstWhere((final piece) => piece != null, orElse: () => null);
  if (sourcePiece == null) {
    return Rect.fromLTRB(baseRect.left + 8, baseRect.top, baseRect.right - 8, baseRect.bottom);
  }

  final sourceBounds = sourcePiece.getTransformedPath().getBounds();
  return Rect.fromLTRB(
    baseRect.left + 8,
    baseRect.top,
    baseRect.right - 8,
    sourceBounds.bottom + 16,
  );
}
