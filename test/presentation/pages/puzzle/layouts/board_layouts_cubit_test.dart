import 'dart:async';

import 'package:caesar_puzzle/application/contracts/board_layout_repository.dart';
import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_cubit.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements BoardLayoutRepository {
  final controller = StreamController<List<BoardLayout>>();

  @override
  Stream<List<BoardLayout>> watchLayouts() => controller.stream;

  @override
  Future<String> saveLayout({required final String name, required final List<PlacementParams> placements}) async => '';

  @override
  Future<void> renameLayout(final String id, final String name) async {}

  @override
  Future<void> deleteLayout(final String id) async {}
}

void main() {
  final standard = BoardLayout(id: 'std', name: '', placements: PuzzleConfigJson.standardPlacements, isStandard: true);
  final custom = BoardLayout(
    id: 'c1',
    name: 'Right column',
    placements: [PlacementParams('zone1', 0, 6, 0, false), PlacementParams('zone2', 3, 6, 1, false)],
  );

  test('finds a layout by its blocked cells', () async {
    final repository = _FakeRepository();
    final cubit = BoardLayoutsCubit(repository);
    repository.controller.add([standard, custom]);
    await Future<void>.delayed(Duration.zero);

    final key = cellsKey(blockedCellsOf(custom.placements));
    expect(cubit.state.entryWithKey(key)?.layout.name, 'Right column');
    expect(cubit.state.entryWithKey('none'), isNull);
    await cubit.close();
  });

  test('counts each layout once per date', () async {
    final repository = _FakeRepository();
    final cubit = BoardLayoutsCubit(repository);
    repository.controller.add([standard, custom]);
    await Future<void>.delayed(Duration.zero);
    final date = DateTime(2026, 10, 8);
    var calls = 0;
    Future<int> count(final List<PlacementParams> placements, final DateTime date) async {
      calls++;
      return placements == standard.placements ? 50 : 51;
    }

    await cubit.countSolutions(cubit.state.entries, date, count);
    await cubit.countSolutions(cubit.state.entries, date, count);

    expect(calls, 2);
    expect(cubit.state.solutionsFor(cubit.state.entries.first, date), 50);
    expect(cubit.state.solutionsFor(cubit.state.entries.last, date), 51);
    expect(cubit.state.solutionsFor(cubit.state.entries.first, DateTime(2026, 10, 9)), isNull);
    await cubit.close();
  });
}
