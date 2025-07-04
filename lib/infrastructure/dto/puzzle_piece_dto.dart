import 'package:caesar_puzzle/core/models/cell.dart';

class PuzzlePieceDto {
  final String id;
  final List<List<int>> relativeCells;
  final bool isForbidden;
  final Set<Cell> cells;

  PuzzlePieceDto({
    required this.id,
    required this.relativeCells,
    required this.isForbidden,
    required this.cells,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'relativeCells': relativeCells,
    'isForbidden': isForbidden,
    'cells': cells.map((c) => c.toMap()).toList(),
  };

  static PuzzlePieceDto fromMap(Map<String, dynamic> map) => PuzzlePieceDto(
    id: map['id'],
    relativeCells: (map['relativeCells'] as List).map<List<int>>((e) => List<int>.from(e)).toList(),
    isForbidden: map['isForbidden'],
    cells: (map['cells'] as List).map((e) => Cell.fromMap(Map<String, dynamic>.from(e))).toSet(),
  );
}