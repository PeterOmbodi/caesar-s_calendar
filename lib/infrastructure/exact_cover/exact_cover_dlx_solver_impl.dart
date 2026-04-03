import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_piece.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/algorithms/exact_cover/caesar_puzzle_exact_cover_solver.dart';

@Injectable(as: PuzzleSolverService)
class ExactCoverDlxSolverImpl implements PuzzleSolverService {
  ExactCoverDlxSolverImpl();

  @override
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async {
    final serializablePieces = pieces.map((final piece) {
      final immovablePiece = keepUserMoves ? piece.placeZone == PlaceZone.grid : piece.isConfigItem;
      final cells = immovablePiece || piece.isConfigItem ? piece.absoluteCells : piece.relativeCells;
      return SolverPiece(
        id: piece.id,
        cells: cells,
        isForbidden: piece.isConfigItem,
        isImmovable: immovablePiece,
      );
    });

    final payload = _ExactCoverSolverPayload(
      grid: grid.toSerializable(),
      pieces: serializablePieces.map((final piece) => piece.toMap()).toList(),
      dateIso8601: (date ?? DateTime.now()).toIso8601String(),
    );

    return compute(_solveWithExactCover, payload.toMap());
  }
}

Iterable<List<String>> _solveWithExactCover(final Map<String, dynamic> payload) {
  final data = _ExactCoverSolverPayload.fromMap(payload);
  final solver = CaesarPuzzleExactCoverSolver(
    grid: PuzzleGridEntity.fromSerializable(data.grid),
    pieces: data.pieces.map(SolverPiece.fromSerializable).toList(),
    date: DateTime.parse(data.dateIso8601),
  );
  final result = solver.solve();
  return result.solutions
      .map((final solution) => solution.selectedRows.map((final placement) => placement.id).toList())
      .toList();
}

class _ExactCoverSolverPayload {
  const _ExactCoverSolverPayload({
    required this.grid,
    required this.pieces,
    required this.dateIso8601,
  });

  factory _ExactCoverSolverPayload.fromMap(final Map<String, dynamic> map) => _ExactCoverSolverPayload(
    grid: Map<String, dynamic>.from(map['grid'] as Map),
    pieces: (map['pieces'] as List)
        .map((final item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    dateIso8601: map['dateIso8601'] as String,
  );

  final Map<String, dynamic> grid;
  final List<Map<String, dynamic>> pieces;
  final String dateIso8601;

  Map<String, dynamic> toMap() => {
    'grid': grid,
    'pieces': pieces,
    'dateIso8601': dateIso8601,
  };
}
