import 'package:caesar_puzzle/application/contracts/board_layout_repository.dart';
import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/infrastructure/persistence/config_id.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: BoardLayoutRepository)
class BoardLayoutRepositoryImpl implements BoardLayoutRepository {
  BoardLayoutRepositoryImpl(this._dao);

  final PuzzleHistoryDao _dao;

  static final BoardLayout standard = BoardLayout(
    id: StandardPuzzleConfig.id,
    name: '',
    placements: PuzzleConfigJson.standardPlacements,
    isStandard: true,
  );

  @override
  Stream<List<BoardLayout>> watchLayouts() => _dao.watchNamedConfigs().map(
    (final rows) => [
      standard,
      for (final row in rows)
        if (row.id != StandardPuzzleConfig.id)
          BoardLayout(
            id: row.id,
            name: row.layoutName!,
            placements: PuzzleConfigJson.decode(row.configJson),
            pieceSetId: row.pieceSetId,
          ),
    ],
  );

  @override
  Future<String> saveLayout({required final String name, required final List<PlacementParams> placements}) async {
    final json = PuzzleConfigJson.encode(placements);
    final id = configIdFor(json);
    if (id == StandardPuzzleConfig.id) {
      return id;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (await _dao.getConfigById(id) == null) {
      await _dao.upsertConfig(id: id, configJson: json, createdAt: nowMs, updatedAt: nowMs);
    }
    await _dao.setConfigName(id, name, nowMs);
    return id;
  }

  @override
  Future<void> renameLayout(final String id, final String name) =>
      _dao.setConfigName(_editable(id), name, DateTime.now().millisecondsSinceEpoch);

  @override
  Future<void> deleteLayout(final String id) =>
      _dao.setConfigName(_editable(id), null, DateTime.now().millisecondsSinceEpoch);

  String _editable(final String id) {
    if (id == StandardPuzzleConfig.id) {
      throw StateError('The Standard layout is read-only');
    }
    return id;
  }
}
