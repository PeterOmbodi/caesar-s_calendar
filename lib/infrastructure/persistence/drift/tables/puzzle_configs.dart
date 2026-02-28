import 'package:drift/drift.dart';

class PuzzleConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get configJson => text()();
  IntColumn get createdAt => integer()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get syncState => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
