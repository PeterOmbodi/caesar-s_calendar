import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';

sealed class HistoryScreenResult {
  const HistoryScreenResult();

  const factory HistoryScreenResult.resumeSession(final PuzzleSessionData session) = ResumeHistorySessionResult;

  const factory HistoryScreenResult.startPuzzleForDate(final DateTime date) = StartPuzzleForDateHistoryResult;
}

final class ResumeHistorySessionResult extends HistoryScreenResult {
  const ResumeHistorySessionResult(this.session);

  final PuzzleSessionData session;
}

final class StartPuzzleForDateHistoryResult extends HistoryScreenResult {
  const StartPuzzleForDateHistoryResult(this.date);

  final DateTime date;
}
