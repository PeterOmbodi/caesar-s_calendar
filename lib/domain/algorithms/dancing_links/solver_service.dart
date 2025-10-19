import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';

abstract class PuzzleSolverService {
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePiece> pieces,
    required final PuzzleGrid grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  });
}
