import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/status/status_for.dart';

String statusText(final PuzzleStatus status) => switch (status.message) {
  StatusMessage.readyToPlay => S.current.statusReadyToPlay,
  StatusMessage.searching => S.current.statusSearching,
  StatusMessage.solutionsCount => S.current.statusSolutionsCount(status.count!),
  StatusMessage.oneSolutionLeft => S.current.statusOneSolutionLeft,
  StatusMessage.solvable => S.current.statusSolvable,
  StatusMessage.piecesPlaced => S.current.statusPiecesPlaced(status.count!, status.total!),
  StatusMessage.noSolutions => S.current.statusNoSolutions,
  StatusMessage.deadEnd => S.current.statusDeadEnd,
  StatusMessage.releaseToPlace => S.current.statusReleaseToPlace,
  StatusMessage.doesNotFit => S.current.statusDoesNotFit,
  StatusMessage.keepDrawing => S.current.statusKeepDrawing(status.count!, status.total!),
  StatusMessage.doubleTapToPlace => S.current.statusDoubleTapToPlace,
  StatusMessage.noMatchingShape => S.current.statusNoMatchingShape,
  StatusMessage.solved => S.current.statusSolved,
  StatusMessage.viewingSolution => S.current.statusViewingSolution(status.count!, status.total!),
  StatusMessage.layoutSolutions => S.current.layoutsSolutionsToday(status.count!),
  StatusMessage.layoutNoSolution => S.current.layoutsNoSolutionToday,
};
