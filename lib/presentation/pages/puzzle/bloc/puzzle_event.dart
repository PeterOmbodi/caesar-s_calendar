part of 'puzzle_bloc.dart';

@freezed
sealed class PuzzleEvent with _$PuzzleEvent {
  const factory PuzzleEvent.started() = _Started;

  const factory PuzzleEvent.setViewSize(final Size viewSize) = _SetViewSize;

  const factory PuzzleEvent.reset() = _Reset;

  const factory PuzzleEvent.onTapDown(final Offset localPosition) = _OnTapDown;

  const factory PuzzleEvent.onTapUp(final Offset localPosition) = _OnTapUp;

  const factory PuzzleEvent.rotatePiece(final PuzzlePiece piece) = _RotatePiece;

  const factory PuzzleEvent.onPanStart(final Offset localPosition) = _OnPanStart;

  const factory PuzzleEvent.onPanUpdate(final Offset localPosition) = _OnPanUpdate;

  const factory PuzzleEvent.onPanEnd(final Offset localPosition) = _OnPanEnd;

  const factory PuzzleEvent.onDoubleTapDown(final Offset localPosition) = _OnDoubleTapDown;

  const factory PuzzleEvent.solve({required final bool showResult}) = _Solve;

  const factory PuzzleEvent.setSolvingResults(final Iterable<Map<String, String>> solutions) = _SetSolvingResults;

  const factory PuzzleEvent.showSolution(final int index) = _ShowSolution;

  const factory PuzzleEvent.configure({
    @Default(false) final bool toInitial,
    @Default(<PuzzlePiece>[]) final Iterable<PuzzlePiece> configurationPieces,
  }) = _Configure;

  const factory PuzzleEvent.undo() = _Undo;

  const factory PuzzleEvent.redo() = _Redo;

  const factory PuzzleEvent.showHint() = _ShowHint;
}
