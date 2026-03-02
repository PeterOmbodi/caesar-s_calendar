import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:drift/drift.dart';

class PuzzleSessions extends Table {
  TextColumn get id => text()();
  TextColumn get puzzleDate => text()();
  TextColumn get configId => text()();
  IntColumn get difficulty => intEnum<PuzzleSessionDifficulty>().withDefault(const Constant(0))();
  IntColumn get status => intEnum<PuzzleSessionStatus>()();
  IntColumn get startedAt => integer()();
  IntColumn get firstMoveAt => integer().nullable()();
  IntColumn get lastResumedAt => integer().nullable()();
  IntColumn get activeElapsedMs => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get piecesSnapshotJson => text()();
  TextColumn get moveHistoryJson => text()();
  IntColumn get moveIndex => integer()();
  IntColumn get moveHistoryVersion => integer()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get syncState => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
