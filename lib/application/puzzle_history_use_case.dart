import 'dart:async';
import 'dart:convert';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class PuzzleHistoryUseCase {
  PuzzleHistoryUseCase(this._historyRepository);

  final PuzzleHistoryRepository _historyRepository;

  String? _currentSessionId;
  int? _currentSessionStartedAt;
  PuzzleSessionDifficulty? _currentSessionDifficulty;
  bool _currentSessionLockedAfterSolved = false;

  void resetSession() {
    _currentSessionId = null;
    _currentSessionStartedAt = null;
    _currentSessionDifficulty = null;
    _currentSessionLockedAfterSolved = false;
  }

  void activateSession(final PuzzleSessionData session) {
    _currentSessionId = session.id;
    _currentSessionStartedAt = session.startedAt;
    _currentSessionDifficulty = session.difficulty;
    _currentSessionLockedAfterSolved =
        session.status == PuzzleSessionStatus.solved || session.completedAt != null;
  }

  void setCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty) {
    _currentSessionDifficulty = _coalesceDifficulty(_currentSessionDifficulty, difficulty);
  }

  void markCurrentSessionEasy() {
    _currentSessionDifficulty = PuzzleSessionDifficulty.easy;
  }

  Stream<List<CalendarDayStats>> watchCalendarStats(final DateTime from, final DateTime to) =>
      _historyRepository.watchCalendarStats(from: from, to: to);

  Stream<List<PuzzleSessionData>> watchSessionsByDate(final DateTime date) =>
      _historyRepository.watchSessionsByDate(puzzleDate: DateTime(date.year, date.month, date.day));

  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay(final DateTime date) =>
      _historyRepository.watchSessionsByMonthDay(puzzleDate: DateTime(date.year, date.month, date.day));

  void persistAfterChange(final PuzzleHistoryInput input) {
    if (_currentSessionLockedAfterSolved) {
      return;
    }
    if (!input.shouldPersist) {
      return;
    }
    if (input.isSolved) {
      _currentSessionLockedAfterSolved = true;
    }
    unawaited(
      _persistSession(
        selectedDate: input.selectedDate,
        moveHistory: input.moveHistory,
        moveIndex: input.moveIndex,
        firstMoveAt: input.firstMoveAt,
        lastResumedAt: input.lastResumedAt,
        activeElapsedMs: input.activeElapsedMs,
        isSolved: input.isSolved,
        difficulty: input.difficulty,
        configPlacements: input.configPlacements,
        piecesSnapshot: input.piecesSnapshot,
        solutions: input.solutions,
        applicableSolutions: input.applicableSolutions,
        solvedTransition: input.solvedTransition,
      ),
    );
  }

  Future<void> _persistSession({
    required final DateTime selectedDate,
    required final List<Move> moveHistory,
    required final int moveIndex,
    required final int? firstMoveAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isSolved,
    required final PuzzleSessionDifficulty difficulty,
    required final List<PlacementParams> configPlacements,
    required final List<PuzzlePieceSnapshot> piecesSnapshot,
    required final List<Map<String, PlacementParams>> solutions,
    required final List<Map<String, PlacementParams>> applicableSolutions,
    required final bool solvedTransition,
  }) async {
    final configJson = _buildConfigJson(configPlacements);
    final configId = await _historyRepository.upsertConfig(configJson: configJson);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final startedAt = _currentSessionStartedAt ?? nowMs;
    _currentSessionStartedAt ??= startedAt;
    final sessionDifficulty = _coalesceDifficulty(_currentSessionDifficulty, difficulty);
    _currentSessionDifficulty = sessionDifficulty;

    final created = _currentSessionId == null;
    final sessionId =
        _currentSessionId ??
        await _historyRepository.createSession(
          PuzzleSessionData(
            id: '',
            puzzleDate: selectedDate,
            configId: configId,
            difficulty: sessionDifficulty,
            status: isSolved ? PuzzleSessionStatus.solved : PuzzleSessionStatus.unsolved,
            startedAt: startedAt,
            firstMoveAt: firstMoveAt,
            lastResumedAt: lastResumedAt,
            activeElapsedMs: activeElapsedMs,
            updatedAt: nowMs,
            completedAt: isSolved ? nowMs : null,
            moveIndex: moveIndex,
            moveHistoryVersion: 1,
            pieces: piecesSnapshot,
            moveHistory: moveHistory,
          ),
        );
    _currentSessionId ??= sessionId;

    if (!created) {
      await _historyRepository.updateSession(
        PuzzleSessionData(
          id: sessionId,
          puzzleDate: selectedDate,
          configId: configId,
          difficulty: sessionDifficulty,
          status: isSolved ? PuzzleSessionStatus.solved : PuzzleSessionStatus.unsolved,
          startedAt: startedAt,
          firstMoveAt: firstMoveAt,
          lastResumedAt: lastResumedAt,
          activeElapsedMs: activeElapsedMs,
          updatedAt: nowMs,
          completedAt: isSolved ? nowMs : null,
          moveIndex: moveIndex,
          moveHistoryVersion: 1,
          pieces: piecesSnapshot,
          moveHistory: moveHistory,
        ),
      );
    }

    if (solvedTransition) {
      final signatures = _solutionSignatures(applicableSolutions: applicableSolutions, solutions: solutions);
      await _historyRepository.markSessionSolved(
        sessionId: sessionId,
        puzzleDate: selectedDate,
        configId: configId,
        solutionSignatures: signatures,
        completedAt: DateTime.now(),
      );
    }
  }

  String _buildConfigJson(final List<PlacementParams> configPlacements) {
    final payload = configPlacements
        .map(
          (final placement) => {
            'pieceId': placement.pieceId,
            'row': placement.row,
            'col': placement.col,
            'rot': placement.rotationSteps,
            'flip': placement.isFlipped,
          },
        )
        .toList();
    return jsonEncode(payload);
  }

  List<String> _solutionSignatures({
    required final List<Map<String, PlacementParams>> solutions,
    required final List<Map<String, PlacementParams>> applicableSolutions,
  }) {
    final source = applicableSolutions.isNotEmpty ? applicableSolutions : solutions;
    return source.map(_signatureFromSolution).toList();
  }

  String _signatureFromSolution(final Map<String, PlacementParams> solution) {
    final entries = solution.entries.toList()..sort((final a, final b) => a.key.compareTo(b.key));
    return entries
        .map(
          (final entry) =>
              '${entry.key}:${entry.value.row}:${entry.value.col}:${entry.value.rotationSteps}:${entry.value.isFlipped ? 1 : 0}',
        )
        .join('|');
  }

  PuzzleSessionDifficulty _coalesceDifficulty(
    final PuzzleSessionDifficulty? previous,
    final PuzzleSessionDifficulty incoming,
  ) {
    if (previous == PuzzleSessionDifficulty.easy || incoming == PuzzleSessionDifficulty.easy) {
      return PuzzleSessionDifficulty.easy;
    }
    return PuzzleSessionDifficulty.hard;
  }
}
