import 'package:drift/drift.dart';

class PuzzleSolutionCounts extends Table {
  TextColumn get puzzleDate => text()();
  TextColumn get configId => text()();
  IntColumn get totalSolutions => integer()();
  IntColumn get computedAt => integer()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get syncState => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {puzzleDate, configId};
}
