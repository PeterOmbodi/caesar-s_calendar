import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';

abstract class PuzzleHistoryRepository {
  Future<String> upsertConfig({
    required final String configJson,
    final DateTime? createdAt,
  });

  Future<void> upsertSolutionCount({
    required final DateTime puzzleDate,
    required final String configId,
    required final int totalSolutions,
    final DateTime? computedAt,
  });

  Future<String> createSession(final PuzzleSessionData session);

  Future<void> updateSession(final PuzzleSessionData session);

  Future<void> markSessionSolved({
    required final String sessionId,
    required final DateTime puzzleDate,
    required final String configId,
    required final Iterable<String> solutionSignatures,
    final DateTime? completedAt,
  });

  Stream<List<CalendarDayStats>> watchCalendarStats({
    required final DateTime from,
    required final DateTime to,
  });

  Stream<List<PuzzleSessionData>> watchSessionsByDate({
    required final DateTime puzzleDate,
  });

  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay({
    required final DateTime puzzleDate,
  });

  Future<PuzzleSessionData?> getLatestUnsolvedSession({
    required final DateTime puzzleDate,
  });

  Future<bool> hasAnyLocalSessions();

  Future<void> clearLocalData();
}
