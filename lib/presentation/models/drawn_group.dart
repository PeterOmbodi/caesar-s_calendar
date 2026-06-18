import 'package:caesar_puzzle/core/models/cell.dart';

enum DrawnGroupCommitStatus { tooSmall, committable, invalid }

class DrawnCell {
  const DrawnCell({required this.cell, required this.order});

  final Cell cell;
  final int order;
}

class DrawnGroup {
  const DrawnGroup({required this.cells, required this.nextOrder});

  factory DrawnGroup.start(final Cell cell) => DrawnGroup(cells: [DrawnCell(cell: cell, order: 0)], nextOrder: 1);

  final List<DrawnCell> cells;
  final int nextOrder;

  Set<Cell> get cellSet => cells.map((final e) => e.cell).toSet();

  bool contains(final Cell cell) => cellSet.contains(cell);

  DrawnGroup copyWith({final List<DrawnCell>? cells, final int? nextOrder}) =>
      DrawnGroup(cells: cells ?? this.cells, nextOrder: nextOrder ?? this.nextOrder);
}
