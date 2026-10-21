import 'package:caesar_puzzle/core/models/cell.dart';

/// Labels run over the free cells row by row: twelve months, then days 1–31.
Set<Cell> targetCells({
  required final int rows,
  required final int columns,
  required final Set<Cell> blocked,
  required final DateTime date,
}) {
  final targets = <Cell>{};
  var index = 0;
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < columns; col++) {
      final cell = Cell(row, col);
      if (blocked.contains(cell)) {
        continue;
      }
      if (index == date.month - 1 || index == date.day + 11) {
        targets.add(cell);
      }
      index++;
    }
  }
  return targets;
}
