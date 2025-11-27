import 'package:caesar_puzzle/core/models/cell.dart';

class PuzzlePieceDto {

  PuzzlePieceDto({
    required this.id,
    required this.cells,
    required this.isForbidden,
    required this.isImmovable,
  });

  factory PuzzlePieceDto.fromMap(final Map<String, dynamic> map) =>
      PuzzlePieceDto(
        id: map['id'],
        cells: (map['cells'] as Set).map((final e) => Cell.fromMap(Map<String, dynamic>.from(e))).toSet(),
        isForbidden: map['isForbidden'],
        isImmovable: map['isImmovable'],
      );
  final String id;
  final Set<Cell> cells;
  final bool isForbidden;
  final bool isImmovable;

  Map<String, dynamic> toMap() => {
        'id': id,
        'cells': cells.map((final c) => c.toMap()).toSet(),
        'isForbidden': isForbidden,
        'isImmovable': isImmovable,
      };
}
