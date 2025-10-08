import 'package:caesar_puzzle/core/models/puzzle_piece_base.dart';
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
  Future<Iterable<List<String>>> solve({
    required Iterable<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    bool keepUserMoves = false,
    DateTime? date,
  }) async {
    final serializablePieces = pieces.map((p) {
      final immovablePiece = keepUserMoves ? p.placeZone == PlaceZone.grid : p.isConfigItem;
      return PuzzlePieceDto(
        id: p.id,
        cells: immovablePiece || p.isConfigItem ? p.cells(grid.origin, grid.cellSize) : p.relativeCells(grid.cellSize),
        isForbidden: p.isConfigItem,
        isImmovable: immovablePiece,
      );
    });
    final solver = PuzzleSolver(grid: grid, pieces: serializablePieces, date: date ?? DateTime.now());

    return solver.solveInIsolate();
  }
}
