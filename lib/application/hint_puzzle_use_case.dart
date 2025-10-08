import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';

import '../injection.dart';

class HintPuzzleUseCase {
  HintPuzzleUseCase();

  Future<Iterable<Map<String, String>>> call({
    required Iterable<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    DateTime? date,
  }) async {
    final rawSolutions = await getIt<PuzzleSolverService>().solve(
      pieces: pieces,
      grid: grid,
      keepUserMoves: true,
      date: date,
    );
    return rawSolutions.map((e) => e.toSolutionMap());
  }
}
