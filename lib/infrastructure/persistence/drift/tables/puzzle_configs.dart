import 'package:drift/drift.dart';

class PuzzleConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get configJson => text()();
  IntColumn get createdAt => integer()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get syncState => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  /// Null unless the config is a saved layout.
  TextColumn get layoutName => text().nullable()();
  TextColumn get pieceSetId => text().withDefault(const Constant('classic8'))();

  @override
  Set<Column> get primaryKey => {id};
}
