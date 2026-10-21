import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/services/calendar_cells.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final standard = {Cell(0, 6), Cell(1, 6), Cell(6, 3), Cell(6, 4), Cell(6, 5), Cell(6, 6)};

  test('targets on the Standard board', () {
    expect(targetCells(rows: 7, columns: 7, blocked: standard, date: DateTime(2026, 10, 8)), {Cell(1, 3), Cell(3, 0)});
    expect(targetCells(rows: 7, columns: 7, blocked: standard, date: DateTime(2026, 12, 31)), {Cell(1, 5), Cell(6, 2)});
  });

  test('labels flow around blocked cells', () {
    final blocked = {Cell(0, 0), Cell(0, 1), Cell(6, 3), Cell(6, 4), Cell(6, 5), Cell(6, 6)};
    expect(targetCells(rows: 7, columns: 7, blocked: blocked, date: DateTime(2026, 1, 1)), {Cell(0, 2), Cell(2, 0)});
  });
}
