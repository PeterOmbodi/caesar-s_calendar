import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
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

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (final migrator, final from, final to) async {
      if (from < 2) {
        await migrator.alterTable(
          TableMigration(
            puzzleSessions,
            columnTransformer: {
              puzzleSessions.difficulty: const Constant(0),
            },
            newColumns: [puzzleSessions.difficulty],
          ),
        );
      }
      if (from < 3) {
        await migrator.addColumn(puzzleConfigs, puzzleConfigs.layoutName);
        await migrator.addColumn(puzzleConfigs, puzzleConfigs.pieceSetId);
      }
    },
  );
}
