part of 'puzzle_bloc.dart';

enum PieceZone { grid, board }

enum GameStatus {
  initializing,
  waiting,
  playing,
  solving,
  solved,
}

@freezed
abstract class PuzzleState with _$PuzzleState {
  factory PuzzleState.initial() => PuzzleState(
        status: GameStatus.initializing,
        gridConfig: PuzzleGrid.initial(),
        boardConfig: PuzzleBoard.initial(),
        pieces: {},
        solutions: [],
        solutionIdx: 0,
        timer: 0,
        selectedPiece: null,
        isDragging: false,
        isSolving: false,
        showPreview: false,
        previewCollision: false,
        isUnlockedForbiddenCells: false,
      );

  factory PuzzleState({
    required GameStatus status,
    required PuzzleGrid gridConfig,
    required PuzzleBoard boardConfig,
    required List<List<String>> solutions,
    required int solutionIdx,
    required int timer,
    required Map<PieceZone, List<PuzzlePiece>> pieces,
    required PuzzlePiece? selectedPiece,
    required bool isDragging,
    Offset? dragStartOffset,
    Offset? pieceStartPosition,
    Offset? previewPosition,
    PieceZone? dropZone,
    required bool isSolving,
    required bool showPreview,
    required bool previewCollision,
    required bool isUnlockedForbiddenCells,
  }) = _PuzzleState;

}
