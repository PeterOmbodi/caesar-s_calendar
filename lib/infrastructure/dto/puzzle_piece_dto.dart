import 'package:caesar_puzzle/core/models/cell.dart';

class PuzzlePieceDto {
  final String id;
  final List<List<int>> relativeCells;
  final bool isDraggable;
  //todo for now cells are using to determinate !isDraggable pieces only
  final Set<Cell> cells;

  PuzzlePieceDto({
    required this.id,
    required this.relativeCells,
    required this.isDraggable,
    required this.cells,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'relativeCells': relativeCells,
    'isDraggable': isDraggable,
    'cells': cells.map((c) => c.toMap()).toList(),
  };

  static PuzzlePieceDto fromMap(Map<String, dynamic> map) => PuzzlePieceDto(
    id: map['id'],
    relativeCells: (map['relativeCells'] as List).map<List<int>>((e) => List<int>.from(e)).toList(),
    isDraggable: map['isDraggable'],
    cells: (map['cells'] as List).map((e) => Cell.fromMap(Map<String, dynamic>.from(e))).toSet(),
  );
}