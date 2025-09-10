part of 'puzzle_bloc.dart';

enum GameStatus { initializing, waiting, playing, searchingAllSolutions, solutionsReady, searchingHint, hintReady }

@freezed
abstract class PuzzleState with _$PuzzleState {
  const PuzzleState._();

  factory PuzzleState.initial() => PuzzleState(
    status: GameStatus.initializing,
    gridConfig: PuzzleGrid.initial(),
    boardConfig: PuzzleBoard.initial(),
    pieces: [],
    solutions: [],
    solutionIdx: -1,
    timer: 0,
    selectedPiece: null,
    isDragging: false,
    showPreview: false,
    previewCollision: false,
    moveHistory: [],
    moveIndex: 0,
  );

  factory PuzzleState({
    required GameStatus status,
    required PuzzleGrid gridConfig,
    required PuzzleBoard boardConfig,
    required List<List<String>> solutions,
    required int solutionIdx,
    required int timer,
    required List<PuzzlePiece> pieces,
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
  }) = _PuzzleState;

  bool get isSolving => status == GameStatus.searchingAllSolutions;

  bool get allowSolutionDisplay => status == GameStatus.solutionsReady && solutions.isNotEmpty && solutionIdx >= 0;

  bool get allowHintDisplay => solutionIdx < 0 && moveHistory.isNotEmpty;

  Iterable<PuzzlePiece> piecesByZone(PlaceZone zone) => pieces.where((p) => p.placeZone == zone);

  Iterable<PuzzlePiece> get gridPieces => piecesByZone(PlaceZone.grid);

  Iterable<PuzzlePiece> get boardPieces => piecesByZone(PlaceZone.board);

  bool get isRedoEnabled => moveHistory.length > moveIndex;

  bool get isUndoEnabled => moveHistory.isNotEmpty && moveIndex > 0;

  bool isPieceInGrid(String pieceId) => gridPieces.any((e) => !e.isForbidden && e.id == pieceId);
}
