import 'package:drift/drift.dart';

class PuzzleSolvedSolutions extends Table {
  TextColumn get puzzleDate => text()();
  TextColumn get configId => text()();
  TextColumn get solutionSignature => text()();
  IntColumn get solvedAt => integer()();
  TextColumn get sessionId => text()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get syncState => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {puzzleDate, configId, solutionSignature};
}
