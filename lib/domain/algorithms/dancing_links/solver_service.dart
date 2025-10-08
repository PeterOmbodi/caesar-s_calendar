import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';

abstract class PuzzleSolverService {
  Future<Iterable<List<String>>> solve({
    required Iterable<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    bool keepUserMoves = false,
    DateTime? date,
  });
}
