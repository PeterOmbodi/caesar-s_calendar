part of 'puzzle_bloc.dart';

extension PuzzleHistoryInputX on PuzzleState {
  PuzzleHistoryInput toHistoryInput({
    required final PuzzleState prevState,
    required final double rotationStep,
  }) =>
      PuzzleHistoryInput(
        shouldPersist: _shouldPersist(),
        solvedTransition: _isSolvedTransition(prevState),
        isSolved: status == GameStatus.solvedByUser,
        selectedDate: selectedDate,
        moveHistory: moveHistory,
        moveIndex: moveIndex,
        firstMoveAt: firstMoveAt,
        lastResumedAt: lastResumedAt,
        activeElapsedMs: activeElapsedMs,
        configPlacements: _configPlacements(rotationStep),
        piecesSnapshot: _snapshotPieces(),
        solutions: solutions,
        applicableSolutions: applicableSolutions,
      );

  bool _shouldPersist() {
    if (status == GameStatus.initializing ||
        status == GameStatus.initialized ||
        status == GameStatus.searchingSolutions ||
        status == GameStatus.solutionsReady ||
        status == GameStatus.showingSolution) {
      return false;
    }
    return moveHistory.isNotEmpty || firstMoveAt != null;
  }

  bool _isSolvedTransition(final PuzzleState prevState) =>
      prevState.status != GameStatus.solvedByUser && status == GameStatus.solvedByUser;

  List<PlacementParams> _configPlacements(final double rotationStep) => pieces
      .where((final p) => p.isConfigItem)
      .map((final piece) {
        final offset = gridConfig.relativePosition(piece.position);
        final row = offset.dy.round();
        final col = offset.dx.round();
        final rotationSteps = (piece.rotation / rotationStep).round() % 4;
        return PlacementParams(piece.id, row, col, rotationSteps, piece.isFlipped);
      })
      .toList()
    ..sort((final a, final b) => a.pieceId.compareTo(b.pieceId));

  List<PuzzlePieceSnapshot> _snapshotPieces() => pieces
      .map(
        (final piece) => PuzzlePieceSnapshot(
          id: piece.id,
          placeZone: piece.placeZone,
          position: Position(dx: piece.position.dx, dy: piece.position.dy),
          rotation: piece.rotation,
          isFlipped: piece.isFlipped,
          isUsersItem: piece.isUsersItem,
          isConfigItem: piece.isConfigItem,
        ),
      )
      .toList();
}
