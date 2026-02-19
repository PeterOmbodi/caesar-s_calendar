import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_configs.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_sessions.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_solution_counts.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/tables/puzzle_solved_solutions.dart';
import 'package:drift/drift.dart';

part 'puzzle_history_dao.g.dart';

class CalendarStatsRow {
  const CalendarStatsRow({
    required this.puzzleDate,
    required this.totalSolutions,
    required this.solvedVariants,
    required this.unsolvedStarted,
  });

  final String puzzleDate;
  final int? totalSolutions;
  final int solvedVariants;
  final int unsolvedStarted;
}

@DriftAccessor(tables: [PuzzleConfigs, PuzzleSolutionCounts, PuzzleSessions, PuzzleSolvedSolutions])
class PuzzleHistoryDao extends DatabaseAccessor<AppDatabase> with _$PuzzleHistoryDaoMixin {
  PuzzleHistoryDao(super.db);

  Future<void> upsertConfig({
    required final String id,
    required final String configJson,
    required final int createdAt,
    required final int updatedAt,
  }) async {
    await into(puzzleConfigs).insertOnConflictUpdate(
      PuzzleConfigsCompanion.insert(id: id, configJson: configJson, createdAt: createdAt, updatedAt: updatedAt),
    );
  }

  Future<void> upsertSolutionCount({
    required final String puzzleDate,
    required final String configId,
    required final int totalSolutions,
    required final int computedAt,
    required final int updatedAt,
  }) async {
    await into(puzzleSolutionCounts).insertOnConflictUpdate(
      PuzzleSolutionCountsCompanion.insert(
        puzzleDate: puzzleDate,
        configId: configId,
        totalSolutions: totalSolutions,
        computedAt: computedAt,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> insertSession(final PuzzleSessionsCompanion entry) async {
    await into(puzzleSessions).insert(entry);
  }

  Future<void> updateSession(final String sessionId, final PuzzleSessionsCompanion entry) async {
    await (update(puzzleSessions)..where((final row) => row.id.equals(sessionId))).write(entry);
  }

  Future<void> markSessionSolved({
    required final String sessionId,
    required final int status,
    required final int completedAt,
    required final int updatedAt,
  }) async {
    await (update(puzzleSessions)..where((final row) => row.id.equals(sessionId))).write(
      PuzzleSessionsCompanion(status: Value(status), completedAt: Value(completedAt), updatedAt: Value(updatedAt)),
    );
  }

  Future<void> insertSolvedSignatures(final List<PuzzleSolvedSolutionsCompanion> entries) async {
    await batch((final batch) {
      batch.insertAllOnConflictUpdate(puzzleSolvedSolutions, entries);
    });
  }

  Future<PuzzleSession?> getLatestUnsolvedSession({required final String puzzleDate, required final int status}) => (select(puzzleSessions)
          ..where(
            (final row) => row.puzzleDate.equals(puzzleDate) & row.status.equals(status) & row.completedAt.isNull(),
          )
          ..orderBy([(final row) => OrderingTerm.desc(row.updatedAt)])
          ..limit(1))
        .getSingleOrNull();

  Stream<List<CalendarStatsRow>> watchCalendarStats({
    required final String fromDate,
    required final String toDate,
    required final int unsolvedStatus,
  }) {
    const sql = '''
WITH solved AS (
  SELECT puzzle_date, config_id, COUNT(DISTINCT solution_signature) AS solved_count
  FROM puzzle_solved_solutions
  GROUP BY puzzle_date, config_id
),
solved_sum AS (
  SELECT puzzle_date, SUM(solved_count) AS solved_variants
  FROM solved
  GROUP BY puzzle_date
),
totals AS (
  SELECT puzzle_date, SUM(total_solutions) AS total_solutions
  FROM puzzle_solution_counts
  GROUP BY puzzle_date
),
unsolved AS (
  SELECT puzzle_date, COUNT(*) AS unsolved_started
  FROM puzzle_sessions
  WHERE status = ?1 AND first_move_at IS NOT NULL AND completed_at IS NULL
  GROUP BY puzzle_date
)
SELECT d.puzzle_date AS puzzle_date,
       totals.total_solutions AS total_solutions,
       solved_sum.solved_variants AS solved_variants,
       unsolved.unsolved_started AS unsolved_started
FROM (
  SELECT puzzle_date FROM puzzle_solution_counts
  UNION
  SELECT puzzle_date FROM puzzle_solved_solutions
  UNION
  SELECT puzzle_date FROM puzzle_sessions
) d
LEFT JOIN totals ON totals.puzzle_date = d.puzzle_date
LEFT JOIN solved_sum ON solved_sum.puzzle_date = d.puzzle_date
LEFT JOIN unsolved ON unsolved.puzzle_date = d.puzzle_date
WHERE d.puzzle_date BETWEEN ?2 AND ?3
ORDER BY d.puzzle_date;
''';

    return customSelect(
      sql,
      variables: [Variable.withInt(unsolvedStatus), Variable.withString(fromDate), Variable.withString(toDate)],
      readsFrom: {puzzleSolutionCounts, puzzleSolvedSolutions, puzzleSessions},
    ).watch().map(
      (final rows) => rows
          .map(
            (final row) => CalendarStatsRow(
              puzzleDate: row.read<String>('puzzle_date'),
              totalSolutions: row.readNullable<int>('total_solutions'),
              solvedVariants: row.readNullable<int>('solved_variants') ?? 0,
              unsolvedStarted: row.readNullable<int>('unsolved_started') ?? 0,
            ),
          )
          .toList(),
    );
  }
}
