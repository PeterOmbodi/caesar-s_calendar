import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
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

@DriftAccessor(
  tables: [
    PuzzleConfigs,
    PuzzleSolutionCounts,
    PuzzleSessions,
    PuzzleSolvedSolutions,
  ],
)
class PuzzleHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$PuzzleHistoryDaoMixin {
  PuzzleHistoryDao(super.db);

  Future<void> upsertConfig({
    required final String id,
    required final String configJson,
    required final int createdAt,
    required final int updatedAt,
  }) async {
    await into(puzzleConfigs).insertOnConflictUpdate(
      PuzzleConfigsCompanion.insert(
        id: id,
        configJson: configJson,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
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

  Future<void> updateSession(final String sessionId,
      final PuzzleSessionsCompanion entry,) async {
    await (update(
      puzzleSessions,
    )
      ..where((final row) => row.id.equals(sessionId))).write(entry);
  }

  Future<void> markSessionSolved({
    required final String sessionId,
    required final PuzzleSessionStatus status,
    required final int completedAt,
    required final int updatedAt,
  }) async {
    await (update(
      puzzleSessions,
    )
      ..where((final row) => row.id.equals(sessionId))).write(
      PuzzleSessionsCompanion(
        status: Value(status),
        completedAt: Value(completedAt),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> insertSolvedSignatures(final List<PuzzleSolvedSolutionsCompanion> entries,) async {
    await batch((final batch) {
      batch.insertAllOnConflictUpdate(puzzleSolvedSolutions, entries);
    });
  }

  Future<PuzzleSession?> getLatestUnsolvedSession({
    required final String puzzleDate,
    required final PuzzleSessionStatus status,
  }) =>
      (select(puzzleSessions)
        ..where(
              (final row) =>
          row.puzzleDate.equals(puzzleDate) &
          row.status.equalsValue(status) &
          row.completedAt.isNull(),
        )
        ..orderBy([(final row) => OrderingTerm.desc(row.updatedAt)])
        ..limit(1))
          .getSingleOrNull();

  Stream<List<PuzzleSession>> watchSessionsByDate({
    required final String puzzleDate,
  }) =>
      (select(puzzleSessions)
        ..where((final row) => row.puzzleDate.equals(puzzleDate))
        ..orderBy([(final row) => OrderingTerm.desc(row.updatedAt)]))
          .watch();

  Stream<List<PuzzleSession>> watchSessionsByMonthDay({
    required final String monthDay,
  }) =>
      (select(puzzleSessions)
        ..where((final row) => row.puzzleDate.substr(6, 5).equals(monthDay))
        ..orderBy([
              (final row) => OrderingTerm.desc(row.puzzleDate),
              (final row) => OrderingTerm.desc(row.updatedAt),
        ]))
          .watch();

  Stream<List<CalendarStatsRow>> watchCalendarStats({
    required final String fromDate,
    required final String toDate,
    required final PuzzleSessionStatus unsolvedStatus,
  }) {
    final totalsStream = _watchTotalSolutionsByDate(
      fromDate: fromDate,
      toDate: toDate,
    );
    final solvedStream = _watchSolvedVariantsByDate(
      fromDate: fromDate,
      toDate: toDate,
    );
    final unsolvedStream = _watchUnsolvedStartedByDate(
      fromDate: fromDate,
      toDate: toDate,
      unsolvedStatus: unsolvedStatus,
    );

    return Stream.multi((final controller) {
      var totals = const <String, int?>{};
      var solved = const <String, int>{};
      var unsolved = const <String, int>{};
      var hasTotals = false;
      var hasSolved = false;
      var hasUnsolved = false;

      void emitCombined() {
        if (!hasTotals || !hasSolved || !hasUnsolved) return;
        final keys = <String>{
          ...totals.keys,
          ...solved.keys,
          ...unsolved.keys,
        }.toList()
          ..sort();
        controller.add(
          keys
              .map(
                (final key) =>
                CalendarStatsRow(
                  puzzleDate: key,
                  totalSolutions: totals[key],
                  solvedVariants: solved[key] ?? 0,
                  unsolvedStarted: unsolved[key] ?? 0,
                ),
          )
              .toList(),
        );
      }

      final totalsSub = totalsStream.listen((final value) {
        totals = value;
        hasTotals = true;
        emitCombined();
      }, onError: controller.addError);
      final solvedSub = solvedStream.listen((final value) {
        solved = value;
        hasSolved = true;
        emitCombined();
      }, onError: controller.addError);
      final unsolvedSub = unsolvedStream.listen((final value) {
        unsolved = value;
        hasUnsolved = true;
        emitCombined();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await totalsSub.cancel();
        await solvedSub.cancel();
        await unsolvedSub.cancel();
      };
    });
  }

  Stream<Map<String, int?>> _watchTotalSolutionsByDate({
    required final String fromDate,
    required final String toDate,
  }) {
    final totalExpr = puzzleSolutionCounts.totalSolutions.sum();
    final query = selectOnly(puzzleSolutionCounts)
      ..where(
        puzzleSolutionCounts.puzzleDate.isBiggerOrEqualValue(fromDate) &
        puzzleSolutionCounts.puzzleDate.isSmallerOrEqualValue(toDate),
      )
      ..addColumns([puzzleSolutionCounts.puzzleDate, totalExpr])
      ..groupBy([puzzleSolutionCounts.puzzleDate]);

    return query.watch().map(
          (final rows) =>
      {
        for (final row in rows)
          row.read(puzzleSolutionCounts.puzzleDate)!: row.read(totalExpr),
      },
    );
  }

  Stream<Map<String, int>> _watchSolvedVariantsByDate({
    required final String fromDate,
    required final String toDate,
  }) {
    final signaturesQuery = selectOnly(puzzleSolvedSolutions)
      ..where(
        puzzleSolvedSolutions.puzzleDate.isBiggerOrEqualValue(fromDate) &
            puzzleSolvedSolutions.puzzleDate.isSmallerOrEqualValue(toDate),
      )
      ..addColumns([
        puzzleSolvedSolutions.puzzleDate,
        puzzleSolvedSolutions.sessionId,
      ]);
    final completedSessionsQuery = selectOnly(puzzleSessions)
      ..where(
        puzzleSessions.completedAt.isNotNull() &
            puzzleSessions.puzzleDate.isBiggerOrEqualValue(fromDate) &
            puzzleSessions.puzzleDate.isSmallerOrEqualValue(toDate),
      )
      ..addColumns([puzzleSessions.id]);

    final signaturesStream = signaturesQuery.watch();
    final completedSessionsStream = completedSessionsQuery.watch();

    return Stream.multi((final controller) {
      var signaturesRows = const <TypedResult>[];
      var completedSessionIds = const <String>{};
      var hasSignatures = false;
      var hasCompletedSessions = false;

      void emitCombined() {
        if (!hasSignatures || !hasCompletedSessions) return;
        final result = <String, int>{};
        for (final row in signaturesRows) {
          final sessionId = row.read(puzzleSolvedSolutions.sessionId);
          if (sessionId == null || !completedSessionIds.contains(sessionId)) {
            continue;
          }
          final date = row.read(puzzleSolvedSolutions.puzzleDate);
          if (date == null) continue;
          result.update(
            date,
            (final value) => value + 1,
            ifAbsent: () => 1,
          );
        }
        controller.add(result);
      }

      final signaturesSub = signaturesStream.listen((final rows) {
        signaturesRows = rows;
        hasSignatures = true;
        emitCombined();
      }, onError: controller.addError);

      final completedSub = completedSessionsStream.listen((final rows) {
        completedSessionIds = {
          for (final row in rows)
            if (row.read(puzzleSessions.id) != null) row.read(puzzleSessions.id)!,
        };
        hasCompletedSessions = true;
        emitCombined();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await signaturesSub.cancel();
        await completedSub.cancel();
      };
    });
  }

  Stream<Map<String, int>> _watchUnsolvedStartedByDate({
    required final String fromDate,
    required final String toDate,
    required final PuzzleSessionStatus unsolvedStatus,
  }) {
    final countExpr = puzzleSessions.id.count();
    final query = selectOnly(puzzleSessions)
      ..where(
        puzzleSessions.status.equalsValue(unsolvedStatus) &
        puzzleSessions.firstMoveAt.isNotNull() &
        puzzleSessions.completedAt.isNull() &
        puzzleSessions.puzzleDate.isBiggerOrEqualValue(fromDate) &
        puzzleSessions.puzzleDate.isSmallerOrEqualValue(toDate),
      )
      ..addColumns([puzzleSessions.puzzleDate, countExpr])
      ..groupBy([puzzleSessions.puzzleDate]);

    return query.watch().map(
          (final rows) =>
      {
        for (final row in rows)
          row.read(puzzleSessions.puzzleDate)!: (row.read(countExpr) ?? 0),
      },
    );
  }
}
