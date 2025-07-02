import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';

abstract class PuzzleSolverService {
  Future<List<List<String>>> solve({required List<PuzzlePiece> pieces, required PuzzleGrid grid});
}
