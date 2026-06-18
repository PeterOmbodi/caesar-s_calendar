import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/services/drawn_group_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DrawnGroupService();

  test('remove keeps oldest connected component after split', () {
    final group = DrawnGroup(
      cells: [
        DrawnCell(cell: Cell(0, 0), order: 0),
        DrawnCell(cell: Cell(0, 1), order: 1),
        DrawnCell(cell: Cell(0, 2), order: 2),
        DrawnCell(cell: Cell(0, 3), order: 3),
      ],
      nextOrder: 4,
    );

    final updated = service.remove(group: group, cell: Cell(0, 1));

    expect(updated, isNotNull);
    expect(updated!.cellSet, {Cell(0, 0)});
  });
}
