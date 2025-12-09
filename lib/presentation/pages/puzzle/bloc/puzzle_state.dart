part of 'puzzle_bloc.dart';

enum GameStatus {
  initializing, // initial state
  initialized,
  playing, // user started to solve
  searchingSolutions, // searching for solutions
  solutionsReady,
  showingSolution, //showing possible solution
  solvedByUser,
  paused,
}

@freezed
abstract class PuzzleState with _$PuzzleState {
  factory PuzzleState({
    required final GameStatus status,
    required final PuzzleGrid gridConfig,
    required final PuzzleBoard boardConfig,
    required final List<Map<String, String>> solutions,
    required final List<Map<String, String>> applicableSolutions,
    required final int solutionIdx,
    required final Iterable<PuzzlePiece> pieces,
    required final PuzzlePiece? selectedPiece,
    required final bool isDragging,
    final Offset? dragStartOffset,
    final Offset? pieceStartPosition,
    final Offset? previewPosition,
    final PlaceZone? dragStartZone,
    required final bool showPreview,
    required final bool previewCollision,
    required final List<Move> moveHistory,
    required final int moveIndex,
    required final DateTime selectedDate,
    final int? firstMoveAt,
    final int? lastResumedAt,
    required final int activeElapsedMs,
  }) = _PuzzleState;

  const PuzzleState._();

  factory PuzzleState.initial() => PuzzleState(
    status: GameStatus.initializing,
    gridConfig: PuzzleGrid.initial(),
    boardConfig: PuzzleBoard.initial(),
    pieces: [],
    solutions: [],
    applicableSolutions: [],
    solutionIdx: -1,
    selectedPiece: null,
    isDragging: false,
    showPreview: false,
    previewCollision: false,
    moveHistory: [],
    moveIndex: 0,
    selectedDate: DateTime.now(),
    activeElapsedMs: 0,
  );

  bool get isSolving => status == GameStatus.searchingSolutions;

  bool get isPaused => status == GameStatus.paused || (status != GameStatus.playing && status != GameStatus.solutionsReady);

  bool get isShowSolutions => status == GameStatus.showingSolution;

  Iterable<PuzzlePiece> piecesByZone(final PlaceZone zone) => pieces.where((final p) => p.placeZone == zone);

  Iterable<PuzzlePiece> get gridPieces => piecesByZone(PlaceZone.grid);

  Iterable<PuzzlePiece> get boardPieces => piecesByZone(PlaceZone.board);

  bool get isRedoEnabled => !isSolving && moveHistory.length > moveIndex;

  bool get isUndoEnabled => !isSolving && moveHistory.isNotEmpty && moveIndex > 0;

  bool isPieceInGrid(final String pieceId) => gridPieces.any((final e) => !e.isConfigItem && e.id == pieceId);

  Iterable<Cell> get sortedConfigCells => pieces
      .where((final e) => e.isConfigItem)
      .expand((final e) => e.cells(gridConfig.origin, gridConfig.cellSize))
      .sortedBy((final e) => e.row * 100 + e.col);


  Offset cfgCellOffset(final int index) {
    if (index >= sortedConfigCells.length) {
      return Offset.zero;
    }
    final cell = sortedConfigCells.toList()[index];
    final origin = gridConfig.origin;
    final cellSize = gridConfig.cellSize;

    final x = origin.dx + cell.col * cellSize;
    final y = origin.dy + cell.row * cellSize;
    return Offset(x, y);
  }
}
