import 'package:caesar_puzzle/core/models/cell.dart';

class PuzzlePieceDto {
  final String id;
  final Set<Cell> cells;
  final bool isForbidden;
  final bool isImmovable;

  PuzzlePieceDto({
    required this.id,
    required this.cells,
    required this.isForbidden,
    required this.isImmovable,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cells': cells.map((c) => c.toMap()).toSet(),
        'isForbidden': isForbidden,
        'isImmovable': isImmovable,
      };

  static PuzzlePieceDto fromMap(Map<String, dynamic> map) => PuzzlePieceDto(
        id: map['id'],
        cells: (map['cells'] as Set).map((e) => Cell.fromMap(Map<String, dynamic>.from(e))).toSet(),
        isForbidden: map['isForbidden'],
        isImmovable: map['isImmovable'],
      );
}
