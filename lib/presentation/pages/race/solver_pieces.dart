import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_piece.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/utils/piece_type_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/painting.dart';

const double _unit = 10;

/// The solver needs no screen size.
const PuzzleGridEntity solverGrid = PuzzleGridEntity(cellSize: _unit, rows: 7, columns: 7, origin: Position.zero());

List<SolverPiece> standardSolverPieces() => [
  SolverPiece(
    id: 'blocked',
    cells: blockedCellsOf(PuzzleConfigJson.standardPlacements),
    isForbidden: true,
    isImmovable: true,
  ),
  for (final type in PieceType.values.where((final t) => !t.isConfigType))
    SolverPiece(
      id: type.idForType,
      cells: PuzzlePieceUI.fromType(type, Offset.zero, const Offset(_unit / 2, _unit / 2), _unit).relativeCells(_unit),
      isForbidden: false,
      isImmovable: false,
    ),
];
