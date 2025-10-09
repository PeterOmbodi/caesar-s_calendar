part of 'puzzle_bloc.dart';

enum GameStatus {
  initializing, // initial state
  initialized,
  playing, // user started to solve
  searchingSolutions, // searching for solutions
  solutionsReady,
  showingSolution, //showing possible solution
  solvedByUser,
}

@freezed
abstract class PuzzleState with _$PuzzleState {
  const PuzzleState._();

  factory PuzzleState.initial() => PuzzleState(
    status: GameStatus.initializing,
    gridConfig: PuzzleGrid.initial(),
    boardConfig: PuzzleBoard.initial(),
    pieces: [],
    solutions: [],
    applicableSolutions: [],
    solutionIdx: -1,
    timer: 0,
    selectedPiece: null,
    isDragging: false,
    showPreview: false,
    previewCollision: false,
    moveHistory: [],
    moveIndex: 0,
    selectedDate: DateTime.now(),
  );

  factory PuzzleState({
    required GameStatus status,
    required PuzzleGrid gridConfig,
    required PuzzleBoard boardConfig,
    required List<Map<String, String>> solutions,
    required List<Map<String, String>> applicableSolutions,
    required int solutionIdx,
    required int timer,
    required Iterable<PuzzlePiece> pieces,
    required PuzzlePiece? selectedPiece,
    required bool isDragging,
    Offset? dragStartOffset,
    Offset? pieceStartPosition,
    Offset? previewPosition,
    PlaceZone? dragStartZone,
    required bool showPreview,
    required bool previewCollision,
    required List<Move> moveHistory,
    required int moveIndex,
    required DateTime selectedDate,
  }) = _PuzzleState;

  bool get isSolving => status == GameStatus.searchingSolutions;

  bool get allowSolutionNavigation => status == GameStatus.showingSolution;

  Iterable<PuzzlePiece> piecesByZone(PlaceZone zone) => pieces.where((p) => p.placeZone == zone);

  Iterable<PuzzlePiece> get gridPieces => piecesByZone(PlaceZone.grid);

  Iterable<PuzzlePiece> get boardPieces => piecesByZone(PlaceZone.board);

  bool get isRedoEnabled => moveHistory.length > moveIndex;

  bool get isUndoEnabled => moveHistory.isNotEmpty && moveIndex > 0;

  bool isPieceInGrid(String pieceId) => gridPieces.any((e) => !e.isConfigItem && e.id == pieceId);
}
