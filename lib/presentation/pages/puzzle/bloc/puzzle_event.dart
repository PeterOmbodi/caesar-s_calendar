part of 'puzzle_bloc.dart';

@freezed
sealed class PuzzleEvent with _$PuzzleEvent {
  const factory PuzzleEvent.started() = _Started;
  const factory PuzzleEvent.setViewSize(Size viewSize) = _SetViewSize;
  const factory PuzzleEvent.reset() = _Reset;
  const factory PuzzleEvent.onTapDown(Offset localPosition) = _OnTapDown;
  const factory PuzzleEvent.onTapUp(Offset localPosition) = _OnTapUp;
  const factory PuzzleEvent.rotatePiece(PuzzlePiece piece) = _RotatePiece;
  const factory PuzzleEvent.onPanStart(Offset localPosition) = _OnPanStart;
  const factory PuzzleEvent.onPanUpdate(Offset localPosition) = _OnPanUpdate;
  const factory PuzzleEvent.onPanEnd(Offset localPosition) = _OnPanEnd;
  const factory PuzzleEvent.onDoubleTapDown(Offset localPosition) = _OnDoubleTapDown;
  const factory PuzzleEvent.solve({required bool keepUserMoves}) = _Solve;
  const factory PuzzleEvent.setSolvingResults(List<List<String>> solutions) = _SetSolvingResults;
  const factory PuzzleEvent.showSolution(int index) = _ShowSolution;
  const factory PuzzleEvent.changeForbiddenCellsMode() = _ChangeForbiddenCellsMode;
  const factory PuzzleEvent.configure({
    required Size viewSize,
    required PuzzleState prevState,
    required Iterable<PuzzlePiece> forbiddenPieces,
  }) = _Configure;
  const factory PuzzleEvent.undo() = _Undo;
  const factory PuzzleEvent.redo() = _Redo;
  const factory PuzzleEvent.hint() = _Hint;
  const factory PuzzleEvent.setHintingResults(List<List<String>> solutions) = _SetHintingResults;
  const factory PuzzleEvent.showHint(int index) = _ShowHint;
}
