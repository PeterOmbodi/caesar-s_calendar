import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_dto.dart';

class SolvePuzzleUseCase {
  final List<PuzzlePiece> pieces;
  final PuzzleGrid grid;

  SolvePuzzleUseCase(this.pieces, this.grid);

  Future<List<String>> call() async {
    final serializablePieces = pieces
        .map((p) => PuzzlePieceDto(
            id: p.id,
            relativeCells: p.relativeCells.map((c) => [c.row, c.col]).toList(),
            isDraggable: p.isDraggable,
            cells: p.isDraggable ? {} : p.cells(grid.origin, grid.cellSize)))
        .toList();
    final solver = PuzzleSolver(
      grid: grid,
      pieces: serializablePieces,
      date: DateTime.now(),
    );
    return solver.solveInIsolate();
  }
}
