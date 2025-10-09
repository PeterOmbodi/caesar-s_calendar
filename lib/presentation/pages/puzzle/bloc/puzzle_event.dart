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
  const factory PuzzleEvent.solve({required bool showResult}) = _Solve;
  const factory PuzzleEvent.setSolvingResults(Iterable<Map<String, String>> solutions) = _SetSolvingResults;
  const factory PuzzleEvent.showSolution(int index) = _ShowSolution;
  const factory PuzzleEvent.configure({
    required Size viewSize,
    @Default(false) bool toInitial,
    @Default(<PuzzlePiece>[]) Iterable<PuzzlePiece> configurationPieces ,
  }) = _Configure;
  const factory PuzzleEvent.undo() = _Undo;
  const factory PuzzleEvent.redo() = _Redo;
  const factory PuzzleEvent.showHint() = _ShowHint;
}
