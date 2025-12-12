import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';

class SolvePuzzleUseCase {
  SolvePuzzleUseCase(this._solver);

  final PuzzleSolverService _solver;

  Future<Iterable<Map<String, PlacementParams>>> call({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async {
    final rawSolutions = await _solver.solve(
      pieces: pieces,
      grid: grid,
      keepUserMoves: keepUserMoves,
      date: date,
    );
    return rawSolutions.map(_toSolutionMap);
  }
}

Map<String, PlacementParams> _toSolutionMap(final List<String> rows) {
  final result = <String, PlacementParams>{};
  for (final rowId in rows) {
    final match = RegExp(r'^(.+)_r(\d+)_c(\d+)_rot(\d+)(_F)?$').firstMatch(rowId);
    if (match == null) continue;
    final pieceId = match.group(1)!;
    final row = int.parse(match.group(2)!);
    final col = int.parse(match.group(3)!);
    final rot = int.parse(match.group(4)!);
    final isFlipped = match.group(5) != null;
    result[pieceId] = PlacementParams(pieceId, row, col, rot, isFlipped);
  }
  return result;
}
