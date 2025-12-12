import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: PuzzleSolverService)
class DancingLinksSolverImpl implements PuzzleSolverService {
  DancingLinksSolverImpl();

  @override
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async {
    final serializablePieces = pieces.map((final p) {
      final immovablePiece = keepUserMoves ? p.placeZone == PlaceZone.grid : p.isConfigItem;
      final cells = immovablePiece || p.isConfigItem ? p.absoluteCells : p.relativeCells;
      return PuzzlePieceDto(
        id: p.id,
        cells: cells,
        isForbidden: p.isConfigItem,
        isImmovable: immovablePiece,
      );
    });
    final solver = PuzzleSolver(grid: grid, pieces: serializablePieces, date: date ?? DateTime.now());

    return compute(PuzzleSolver.solveEntryPoint, solver.toSerializable());
  }
}
