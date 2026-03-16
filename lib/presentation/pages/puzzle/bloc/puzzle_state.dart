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
    required final PuzzleGridEntity gridConfig,
    required final PuzzleBoardEntity boardConfig,
    required final List<Map<String, PlacementParams>> solutions,
    required final List<Map<String, PlacementParams>> applicableSolutions,
    required final int solutionIdx,
    required final Iterable<PuzzlePieceUI> pieces,
    required final PuzzlePieceUI? selectedPiece,
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
    required final bool isRestoredSolvedSession,
    required final bool hasShownSolvedDialog,
    final int? firstMoveAt,
    final int? lastResumedAt,
    required final int activeElapsedMs,
  }) = _PuzzleState;

  const PuzzleState._();

  factory PuzzleState.initial() => PuzzleState(
    status: GameStatus.initializing,
    gridConfig: PuzzleGridEntity.initial(),
    boardConfig: PuzzleBoardEntity.initial(),
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
    isRestoredSolvedSession: false,
    hasShownSolvedDialog: false,
    activeElapsedMs: 0,
  );

  bool get isSolving => status == GameStatus.searchingSolutions;

  bool get isSolved => status == GameStatus.solvedByUser;

  bool get isPaused =>
      status == GameStatus.paused || (status != GameStatus.playing && status != GameStatus.solutionsReady);

  bool get isShowSolutions => status == GameStatus.showingSolution;

  Iterable<PuzzlePieceUI> piecesByZone(final PlaceZone zone) => pieces.where((final p) => p.placeZone == zone);

  Iterable<PuzzlePieceUI> get gridPieces => piecesByZone(PlaceZone.grid);

  Iterable<PuzzlePieceUI> get boardPieces => piecesByZone(PlaceZone.board);

  bool get isRedoEnabled => !isSolving && moveHistory.length > moveIndex;

  bool get isUndoEnabled => !isSolving && moveHistory.isNotEmpty && moveIndex > 0;

  bool get isCustomConfig => PuzzleConfigClassifier.isCustomConfig(
    pieces: pieces,
    gridConfig: gridConfig,
  );

  bool isPieceInGrid(final String pieceId) => gridPieces.any((final e) => !e.isConfigItem && e.id == pieceId);

  List<Cell> get sortedConfigCells {
    final configPieces = pieces.where((final e) => e.isConfigItem);
    final pieceCells =
        configPieces
            .map(
              (final piece) => piece.cells(gridConfig.origin, gridConfig.cellSize).toList()
                ..sort((final a, final b) {
                  final byRow = a.row.compareTo(b.row);
                  return byRow != 0 ? byRow : a.col.compareTo(b.col);
                }),
            )
            .toList()
          ..sort((final a, final b) {
            final bySize = a.length.compareTo(b.length);
            if (bySize != 0) return bySize;
            if (a.isEmpty || b.isEmpty) return 0;
            final byRow = a.first.row.compareTo(b.first.row);
            return byRow != 0 ? byRow : a.first.col.compareTo(b.first.col);
          });
    return pieceCells.expand((final cells) => cells).toList();
  }

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
