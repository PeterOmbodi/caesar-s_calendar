import 'package:drift/drift.dart';

class PuzzleAssists extends Table {
  TextColumn get puzzleDate => text()();
  TextColumn get configId => text()();
  IntColumn get assistedAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get syncState => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {puzzleDate, configId};
}
