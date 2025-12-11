import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';

import '../injection.dart';

class SolvePuzzleUseCase {
  SolvePuzzleUseCase();

  Future<Iterable<Map<String, String>>> call({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async {
    final rawSolutions = await getIt<PuzzleSolverService>().solve(
      pieces: pieces,
      grid: grid,
      keepUserMoves: keepUserMoves,
      date: date,
    );
    return rawSolutions.map((final e) => e.toSolutionMap());
  }
}

extension SolutionExtension on List<String> {
  Map<String, String> toSolutionMap() {
    final result = <String, String>{};
    for (final item in this) {
      final parts = item.split('_');
      if (parts.isNotEmpty) {
        final key = parts.first;
        final value = parts.skip(1).join('_');
        result[key] = value;
      }
    }
    return result;
  }
}
