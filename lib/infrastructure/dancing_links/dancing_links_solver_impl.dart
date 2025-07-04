import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_dto.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: PuzzleSolverService)
class DancingLinksSolverImpl implements PuzzleSolverService {

  DancingLinksSolverImpl();

  @override
  Future<List<List<String>>> solve({required List<PuzzlePiece> pieces, required PuzzleGrid grid}) async {
    final serializablePieces = pieces
        .map((p) => PuzzlePieceDto(
            id: p.id,
            relativeCells: p.relativeCells.map((c) => [c.row, c.col]).toList(),
            isForbidden: p.isForbidden,
            cells: !p.isForbidden ? {} : p.cells(grid.origin, grid.cellSize)))
        .toList();
    final solver = PuzzleSolver(
      grid: grid,
      pieces: serializablePieces,
      date: DateTime.now(),
    );

    return solver.solve();
  }
}
