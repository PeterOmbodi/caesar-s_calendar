import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_dto.dart';

/// Represents a candidate placement for a puzzle piece.
/// A placement is defined by:
///  - the puzzle piece to place,
///  - the grid position (row, col) of its anchor point,
///  - the rotation in multiples of 90° (0, 1, 2, or 3),
///  - whether the piece is flipped horizontally.
class PlacementDto {
  final PuzzlePieceDto piece;
  final int row;
  final int col;
  final int rotationSteps;
  final bool isFlipped;

  PlacementDto(this.piece, this.row, this.col, this.rotationSteps, this.isFlipped);

  String get id {
    return '${piece.id}_r${row}_c${col}_rot$rotationSteps${isFlipped ? "_F" : ""}';
  }
}
