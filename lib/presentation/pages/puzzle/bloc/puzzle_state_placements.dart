part of 'puzzle_bloc.dart';

extension PuzzleStatePlacementsX on PuzzleState {
  PlacementParams placementOf(final PuzzlePieceUI piece) {
    final offset = gridConfig.relativePosition(piece.position);
    final rotationSteps = (piece.rotation / PuzzleBloc.rotationStep).round() % 4;
    return PlacementParams(piece.id, offset.dy.round(), offset.dx.round(), rotationSteps, piece.isFlipped);
  }

  PuzzlePieceUI placedAt(final PuzzlePieceUI piece, final PlacementParams params) => piece.copyWith(
    isFlipped: params.isFlipped,
    position: Offset(
      gridConfig.origin.dx + params.col * gridConfig.cellSize,
      gridConfig.origin.dy + params.row * gridConfig.cellSize,
    ),
    rotation: params.rotationSteps * PuzzleBloc.rotationStep,
    placeZone: PlaceZone.grid,
  );

  /// Without the blocked cells.
  List<PlacementParams> get piecePlacements => [
    for (final piece in gridPieces)
      if (!piece.isConfigItem) placementOf(piece),
  ];

  /// Pieces not in [placements] are left out.
  List<PuzzlePieceUI> boardWith(final Iterable<PlacementParams> placements) {
    final byId = {for (final piece in pieces) piece.id: piece};
    return [
      ...pieces.where((final piece) => piece.isConfigItem),
      for (final params in placements)
        if (byId[params.pieceId] case final piece? when !piece.isConfigItem) placedAt(piece, params),
    ];
  }
}
