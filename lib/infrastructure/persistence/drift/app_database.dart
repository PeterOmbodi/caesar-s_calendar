import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/database_connection.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_configs.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_sessions.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_solution_counts.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_solved_solutions.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [PuzzleConfigs, PuzzleSolutionCounts, PuzzleSessions, PuzzleSolvedSolutions],
  daos: [PuzzleHistoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @override
  int get schemaVersion => 1;
}
