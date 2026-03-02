import 'dart:convert';
import 'dart:math';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/infrastructure/dto/move_history_dto.dart';
import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_snapshot_dto.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PuzzleHistoryRepository)
class PuzzleHistoryRepositoryImpl implements PuzzleHistoryRepository {
  PuzzleHistoryRepositoryImpl(this._dao);

  static const int _moveHistoryVersion = 1;

  final PuzzleHistoryDao _dao;

  @override
  Future<String> upsertConfig({required final String configJson, final DateTime? createdAt}) async {
    final now = createdAt ?? DateTime.now();
    final configId = _hash(configJson);
    final nowMs = now.millisecondsSinceEpoch;
    await _dao.upsertConfig(
      id: configId,
      configJson: configJson,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
    return configId;
  }

  @override
  Future<void> upsertSolutionCount({
    required final DateTime puzzleDate,
    required final String configId,
    required final int totalSolutions,
    final DateTime? computedAt,
  }) async {
    final now = DateTime.now();
    await _dao.upsertSolutionCount(
      puzzleDate: _dateKey(puzzleDate),
      configId: configId,
      totalSolutions: totalSolutions,
      computedAt: (computedAt ?? now).millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  @override
  Future<String> createSession(final PuzzleSessionData session) async {
    final sessionId = session.id.isEmpty ? _newId() : session.id;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _dao.insertSession(
      PuzzleSessionsCompanion.insert(
        id: sessionId,
        puzzleDate: _dateKey(session.puzzleDate),
        configId: session.configId,
        difficulty: Value(session.difficulty),
        status: session.status,
        startedAt: session.startedAt,
        firstMoveAt: Value(session.firstMoveAt),
        lastResumedAt: Value(session.lastResumedAt),
        activeElapsedMs: session.activeElapsedMs,
        updatedAt: session.updatedAt == 0 ? nowMs : session.updatedAt,
        completedAt: Value(session.completedAt),
        piecesSnapshotJson: _encodePieces(session.pieces),
        moveHistoryJson: _encodeMoves(session.moveHistory),
        moveIndex: session.moveIndex,
        moveHistoryVersion: session.moveHistoryVersion == 0 ? _moveHistoryVersion : session.moveHistoryVersion,
      ),
    );
    return sessionId;
  }

  @override
  Future<void> updateSession(final PuzzleSessionData session) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _dao.updateSession(
      session.id,
      PuzzleSessionsCompanion(
        difficulty: Value(session.difficulty),
        status: Value(session.status),
        firstMoveAt: Value(session.firstMoveAt),
        lastResumedAt: Value(session.lastResumedAt),
        activeElapsedMs: Value(session.activeElapsedMs),
        updatedAt: Value(session.updatedAt == 0 ? nowMs : session.updatedAt),
        completedAt: Value(session.completedAt),
        piecesSnapshotJson: Value(_encodePieces(session.pieces)),
        moveHistoryJson: Value(_encodeMoves(session.moveHistory)),
        moveIndex: Value(session.moveIndex),
        moveHistoryVersion: Value(session.moveHistoryVersion == 0 ? _moveHistoryVersion : session.moveHistoryVersion),
      ),
    );
  }

  @override
  Future<void> markSessionSolved({
    required final String sessionId,
    required final DateTime puzzleDate,
    required final String configId,
    required final Iterable<String> solutionSignatures,
    final DateTime? completedAt,
  }) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    await _dao.markSessionSolved(
      sessionId: sessionId,
      status: PuzzleSessionStatus.solved,
      completedAt: (completedAt ?? now).millisecondsSinceEpoch,
      updatedAt: nowMs,
    );
    final entries = solutionSignatures
        .map(
          (final signature) => PuzzleSolvedSolutionsCompanion.insert(
            puzzleDate: _dateKey(puzzleDate),
            configId: configId,
            solutionSignature: signature,
            solvedAt: nowMs,
            sessionId: sessionId,
            updatedAt: nowMs,
          ),
        )
        .toList();
    if (entries.isNotEmpty) {
      await _dao.insertSolvedSignatures(entries);
    }
  }

  @override
  Stream<List<CalendarDayStats>> watchCalendarStats({required final DateTime from, required final DateTime to}) => _dao
        .watchCalendarStats(
          fromDate: _dateKey(from),
          toDate: _dateKey(to),
          unsolvedStatus: PuzzleSessionStatus.unsolved,
        )
        .map((final rows) => _fillMissingDays(from, to, rows));

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByDate({required final DateTime puzzleDate}) =>
      _dao.watchSessionsByDate(puzzleDate: _dateKey(puzzleDate)).map(
        (final rows) => rows.map(_sessionFromRow).toList(),
      );

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay({required final DateTime puzzleDate}) => _dao
      .watchSessionsByMonthDay(monthDay: _monthDayKey(puzzleDate))
      .map((final rows) => rows.map(_sessionFromRow).toList());

  @override
  Future<PuzzleSessionData?> getLatestUnsolvedSession({required final DateTime puzzleDate}) async {
    final row = await _dao.getLatestUnsolvedSession(
      puzzleDate: _dateKey(puzzleDate),
      status: PuzzleSessionStatus.unsolved,
    );
    if (row == null) return null;
    return _sessionFromRow(row);
  }

  List<CalendarDayStats> _fillMissingDays(
    final DateTime from,
    final DateTime to,
    final List<CalendarStatsRow> rows,
  ) {
    final rowByDate = {
      for (final row in rows) row.puzzleDate: row,
    };
    final stats = <CalendarDayStats>[];
    var current = DateTime(from.year, from.month, from.day);
    final last = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(last)) {
      final key = _dateKey(current);
      final row = rowByDate[key];
      stats.add(
        CalendarDayStats(
          date: current,
          totalSolutions: row?.totalSolutions,
          solvedVariants: row?.solvedVariants ?? 0,
          unsolvedStarted: row?.unsolvedStarted ?? 0,
        ),
      );
      current = current.add(const Duration(days: 1));
    }
    return stats;
  }

  PuzzleSessionData _sessionFromRow(final PuzzleSession row) => PuzzleSessionData(
    id: row.id,
    puzzleDate: _dateFromKey(row.puzzleDate),
    configId: row.configId,
    difficulty: row.difficulty,
    status: row.status,
    startedAt: row.startedAt,
    firstMoveAt: row.firstMoveAt,
    lastResumedAt: row.lastResumedAt,
    activeElapsedMs: row.activeElapsedMs,
    updatedAt: row.updatedAt,
    completedAt: row.completedAt,
    moveIndex: row.moveIndex,
    moveHistoryVersion: row.moveHistoryVersion,
    pieces: _decodePieces(row.piecesSnapshotJson),
    moveHistory: _decodeMoves(row.moveHistoryJson),
  );

  String _dateKey(final DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _monthDayKey(final DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime _dateFromKey(final String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  String _encodePieces(final List<PuzzlePieceSnapshot> pieces) => jsonEncode(
        pieces.map((final item) => PuzzlePieceSnapshotDto.fromDomain(item).toMap()).toList(),
      );

  List<PuzzlePieceSnapshot> _decodePieces(final String json) => (jsonDecode(json) as List)
      .map((final item) => PuzzlePieceSnapshotDto.fromMap(Map<String, dynamic>.from(item as Map)).toDomain())
      .toList();

  String _encodeMoves(final List<Move> moves) =>
      jsonEncode(moves.map((final move) => MoveDto.fromDomain(move).toMap()).toList());

  List<Move> _decodeMoves(final String json) => (jsonDecode(json) as List)
      .map((final item) => MoveDto.fromMap(Map<String, dynamic>.from(item as Map)).toDomain())
      .toList();

  String _hash(final String input) => sha256.convert(utf8.encode(input)).toString();

  String _newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
