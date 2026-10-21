import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/infrastructure/persistence/board_layout_repository_impl.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PuzzleHistoryDao dao;
  late BoardLayoutRepositoryImpl repository;

  final rightColumn = [PlacementParams('zone1', 0, 6, 0, false), PlacementParams('zone2', 3, 6, 1, false)];

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = PuzzleHistoryDao(db);
    repository = BoardLayoutRepositoryImpl(dao);
  });

  tearDown(() => db.close());

  Future<List<String>> names() async =>
      [for (final layout in await repository.watchLayouts().first) layout.isStandard ? '<standard>' : layout.name];

  test('Standard is always listed first', () async {
    expect(await names(), ['<standard>']);
  });

  test('a saved layout is listed, stored as a dirty config and keeps its placements', () async {
    final id = await repository.saveLayout(name: 'Right column', placements: rightColumn);

    expect(await names(), ['<standard>', 'Right column']);
    final layouts = await repository.watchLayouts().first;
    expect(PuzzleConfigJson.encode(layouts.last.placements), PuzzleConfigJson.encode(rightColumn));
    expect((await dao.getConfigById(id))!.syncState, 1);
  });

  test('saving Standard placements does not create a named copy', () async {
    final id = await repository.saveLayout(name: 'Mine', placements: PuzzleConfigJson.standardPlacements);

    expect(id, StandardPuzzleConfig.id);
    expect(await names(), ['<standard>']);
  });

  test('rename and delete; a deleted layout keeps its config for old sessions', () async {
    final id = await repository.saveLayout(name: 'Right column', placements: rightColumn);

    await repository.renameLayout(id, 'Edge');
    expect(await names(), ['<standard>', 'Edge']);

    await repository.deleteLayout(id);
    expect(await names(), ['<standard>']);
    expect(await dao.getConfigById(id), isNotNull);
  });

  test('Standard cannot be renamed or deleted', () {
    expect(() => repository.renameLayout(StandardPuzzleConfig.id, 'x'), throwsStateError);
    expect(() => repository.deleteLayout(StandardPuzzleConfig.id), throwsStateError);
  });
}
