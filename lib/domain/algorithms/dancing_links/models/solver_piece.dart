import 'package:caesar_puzzle/core/models/cell.dart';

class SolverPiece {
  const SolverPiece({
    required this.id,
    required this.cells,
    required this.isForbidden,
    required this.isImmovable,
  });

  factory SolverPiece.fromSerializable(final Map<String, dynamic> map) => SolverPiece(
        id: map['id'] as String,
        cells: (map['cells'] as Iterable)
            .map((final e) => Cell.fromMap(Map<String, dynamic>.from(e as Map)))
            .toSet(),
        isForbidden: map['isForbidden'] as bool,
        isImmovable: map['isImmovable'] as bool,
      );

  final String id;
  final Set<Cell> cells;
  final bool isForbidden;
  final bool isImmovable;

  Map<String, dynamic> toMap() => {
        'id': id,
        'cells': cells.map((final c) => c.toMap()).toList(),
        'isForbidden': isForbidden,
        'isImmovable': isImmovable,
      };
}
