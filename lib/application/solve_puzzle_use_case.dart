import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';

import '../injection.dart';

class SolvePuzzleUseCase {
  SolvePuzzleUseCase();

  Future<List<List<String>>> call({
    required List<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    bool keepUserMoves = false,
  }) async {
    return getIt<PuzzleSolverService>().solve(pieces: pieces, grid: grid, keepUserMoves: keepUserMoves);
  }
}
