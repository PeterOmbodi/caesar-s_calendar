import 'dart:convert';

import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class SyncService {
  SyncService({
    required final AppDatabase db,
    required final FirebaseFirestore firestore,
    required final AuthService auth,
  }) : _db = db,
       _firestore = firestore,
       _auth = auth;

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final AuthService _auth;

  static const _prefsKeyPrefix = 'sync_last_ms_';

  Future<bool> hasCloudData(final String uid) async {
    if (!_auth.isAvailable) return false;
    if (await _collectionHasDocs(FirestorePaths.userSessions(uid))) return true;
    if (await _collectionHasDocs(FirestorePaths.userConfigs(uid))) return true;
    if (await _collectionHasDocs(FirestorePaths.userSolvedSolutions(uid))) return true;
    if (await _collectionHasDocs('${FirestorePaths.userDoc(uid)}/solutionCounts')) return true;
    return false;
  }

  Future<void> clearAllSyncCheckpoints() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((final key) => key.startsWith(_prefsKeyPrefix)).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  Future<void> syncOnce() async {
    if (!_auth.isAvailable) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs = prefs.getInt('$_prefsKeyPrefix$uid') ?? 0;

    await _uploadDirty(uid);
    await _downloadUpdates(uid, sinceMs: lastSyncMs);

    await prefs.setInt('$_prefsKeyPrefix$uid', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _uploadDirty(final String uid) async {
    await _uploadDirtyConfigs(uid);
    await _uploadDirtySessions(uid);
    await _uploadDirtySolvedSolutions(uid);
    await _uploadDirtySolutionCounts(uid);
  }

  Future<void> _uploadDirtyConfigs(final String uid) async {
    final rows = await (_db.select(_db.puzzleConfigs)
          ..where((final t) => t.syncState.equals(SyncState.dirty.code)))
        .get();
    if (rows.isEmpty) return;

    final col = _firestore.collection(FirestorePaths.userConfigs(uid));
    for (final row in rows) {
      final doc = col.doc(row.id);
      await doc.set(
        {
          'id': row.id,
          'configJson': row.configJson,
          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,
        },
        SetOptions(merge: true),
      );
      await (_db.update(_db.puzzleConfigs)..where((final t) => t.id.equals(row.id))).write(
        PuzzleConfigsCompanion(
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _uploadDirtySessions(final String uid) async {
    final rows = await (_db.select(_db.puzzleSessions)
          ..where((final t) => t.syncState.equals(SyncState.dirty.code)))
        .get();
    if (rows.isEmpty) return;

    final col = _firestore.collection(FirestorePaths.userSessions(uid));
    for (final row in rows) {
      final doc = col.doc(row.id);
      await doc.set(
        {
          'id': row.id,
          'puzzleDate': row.puzzleDate,
          'configId': row.configId,
          'difficulty': row.difficulty.index,
          'status': row.status.index,
          'startedAt': row.startedAt,
          'firstMoveAt': row.firstMoveAt,
          'lastResumedAt': row.lastResumedAt,
          'activeElapsedMs': row.activeElapsedMs,
          'updatedAt': row.updatedAt,
          'completedAt': row.completedAt,
          'piecesSnapshotJson': row.piecesSnapshotJson,
          'moveHistoryJson': row.moveHistoryJson,
          'moveIndex': row.moveIndex,
          'moveHistoryVersion': row.moveHistoryVersion,
          'clientUpdatedAt': row.updatedAt,
        },
        SetOptions(merge: true),
      );
      await (_db.update(_db.puzzleSessions)..where((final t) => t.id.equals(row.id))).write(
        PuzzleSessionsCompanion(
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _uploadDirtySolvedSolutions(final String uid) async {
    final rows = await (_db.select(_db.puzzleSolvedSolutions)
          ..where((final t) => t.syncState.equals(SyncState.dirty.code)))
        .get();
    if (rows.isEmpty) return;

    final col = _firestore.collection(FirestorePaths.userSolvedSolutions(uid));
    for (final row in rows) {
      final docId = _solvedDocId(
        puzzleDate: row.puzzleDate,
        configId: row.configId,
        signature: row.solutionSignature,
      );
      final doc = col.doc(docId);
      await doc.set(
        {
          'puzzleDate': row.puzzleDate,
          'configId': row.configId,
          'solutionSignature': row.solutionSignature,
          'solvedAt': row.solvedAt,
          'sessionId': row.sessionId,
          'updatedAt': row.updatedAt,
        },
        SetOptions(merge: true),
      );
      await (_db.update(_db.puzzleSolvedSolutions)
            ..where(
                  (final t) =>
              t.puzzleDate.equals(row.puzzleDate) &
              t.configId.equals(row.configId) &
              t.solutionSignature.equals(row.solutionSignature),
            ))
          .write(
        PuzzleSolvedSolutionsCompanion(
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _uploadDirtySolutionCounts(final String uid) async {
    final rows = await (_db.select(_db.puzzleSolutionCounts)
          ..where((final t) => t.syncState.equals(SyncState.dirty.code)))
        .get();
    if (rows.isEmpty) return;

    final col = _firestore.collection('${FirestorePaths.userDoc(uid)}/solutionCounts');
    for (final row in rows) {
      final docId = '${row.puzzleDate}__${row.configId}';
      final doc = col.doc(docId);
      await doc.set(
        {
          'puzzleDate': row.puzzleDate,
          'configId': row.configId,
          'totalSolutions': row.totalSolutions,
          'computedAt': row.computedAt,
          'updatedAt': row.updatedAt,
        },
        SetOptions(merge: true),
      );
      await (_db.update(_db.puzzleSolutionCounts)
            ..where(
                  (final t) =>
              t.puzzleDate.equals(row.puzzleDate) & t.configId.equals(row.configId),
            ))
          .write(
        PuzzleSolutionCountsCompanion(
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _downloadUpdates(final String uid, {required final int sinceMs}) async {
    await _downloadSessions(uid, sinceMs: sinceMs);
    await _downloadConfigs(uid, sinceMs: sinceMs);
    await _downloadSolvedSolutions(uid, sinceMs: sinceMs);
    await _downloadSolutionCounts(uid, sinceMs: sinceMs);
  }

  Future<void> _downloadSessions(final String uid, {required final int sinceMs}) async {
    final snap = await _firestore
        .collection(FirestorePaths.userSessions(uid))
        .where('updatedAt', isGreaterThan: sinceMs)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = (data['updatedAt'] as int?) ?? 0;
      final local = await (_db.select(_db.puzzleSessions)..where((final t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null && local.updatedAt >= remoteUpdatedAt) continue;

      await _db.into(_db.puzzleSessions).insertOnConflictUpdate(
        PuzzleSessionsCompanion.insert(
          id: doc.id,
          puzzleDate: (data['puzzleDate'] as String?) ?? '',
          configId: (data['configId'] as String?) ?? '',
          difficulty: Value(_difficultyFromIndex(data['difficulty'] as int?)),
          status: _statusFromIndex(data['status'] as int?),
          startedAt: (data['startedAt'] as int?) ?? 0,
          firstMoveAt: Value(data['firstMoveAt'] as int?),
          lastResumedAt: Value(data['lastResumedAt'] as int?),
          activeElapsedMs: (data['activeElapsedMs'] as int?) ?? 0,
          updatedAt: remoteUpdatedAt,
          completedAt: Value(data['completedAt'] as int?),
          piecesSnapshotJson: (data['piecesSnapshotJson'] as String?) ?? '[]',
          moveHistoryJson: (data['moveHistoryJson'] as String?) ?? '[]',
          moveIndex: (data['moveIndex'] as int?) ?? 0,
          moveHistoryVersion: (data['moveHistoryVersion'] as int?) ?? 1,
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _downloadConfigs(final String uid, {required final int sinceMs}) async {
    final snap = await _firestore
        .collection(FirestorePaths.userConfigs(uid))
        .where('updatedAt', isGreaterThan: sinceMs)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = (data['updatedAt'] as int?) ?? 0;
      final local = await (_db.select(_db.puzzleConfigs)..where((final t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null && local.updatedAt >= remoteUpdatedAt) continue;

      await _db.into(_db.puzzleConfigs).insertOnConflictUpdate(
        PuzzleConfigsCompanion.insert(
          id: doc.id,
          configJson: (data['configJson'] as String?) ?? '[]',
          createdAt: (data['createdAt'] as int?) ?? remoteUpdatedAt,
          updatedAt: remoteUpdatedAt,
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _downloadSolvedSolutions(final String uid, {required final int sinceMs}) async {
    final snap = await _firestore
        .collection(FirestorePaths.userSolvedSolutions(uid))
        .where('updatedAt', isGreaterThan: sinceMs)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = (data['updatedAt'] as int?) ?? 0;
      final puzzleDate = (data['puzzleDate'] as String?) ?? '';
      final configId = (data['configId'] as String?) ?? '';
      final signature = (data['solutionSignature'] as String?) ?? '';

      final local = await (_db.select(_db.puzzleSolvedSolutions)
            ..where(
                  (final t) =>
              t.puzzleDate.equals(puzzleDate) & t.configId.equals(configId) & t.solutionSignature.equals(signature),
            ))
          .getSingleOrNull();
      if (local != null && local.updatedAt >= remoteUpdatedAt) continue;

      await _db.into(_db.puzzleSolvedSolutions).insertOnConflictUpdate(
        PuzzleSolvedSolutionsCompanion.insert(
          puzzleDate: puzzleDate,
          configId: configId,
          solutionSignature: signature,
          solvedAt: (data['solvedAt'] as int?) ?? remoteUpdatedAt,
          sessionId: (data['sessionId'] as String?) ?? '',
          updatedAt: remoteUpdatedAt,
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<void> _downloadSolutionCounts(final String uid, {required final int sinceMs}) async {
    final snap = await _firestore
        .collection('${FirestorePaths.userDoc(uid)}/solutionCounts')
        .where('updatedAt', isGreaterThan: sinceMs)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = (data['updatedAt'] as int?) ?? 0;
      final puzzleDate = (data['puzzleDate'] as String?) ?? '';
      final configId = (data['configId'] as String?) ?? '';

      final local = await (_db.select(_db.puzzleSolutionCounts)
            ..where((final t) => t.puzzleDate.equals(puzzleDate) & t.configId.equals(configId)))
          .getSingleOrNull();
      if (local != null && local.updatedAt >= remoteUpdatedAt) continue;

      await _db.into(_db.puzzleSolutionCounts).insertOnConflictUpdate(
        PuzzleSolutionCountsCompanion.insert(
          puzzleDate: puzzleDate,
          configId: configId,
          totalSolutions: (data['totalSolutions'] as int?) ?? 0,
          computedAt: (data['computedAt'] as int?) ?? remoteUpdatedAt,
          updatedAt: remoteUpdatedAt,
          remoteId: Value(doc.id),
          syncState: Value(SyncState.clean.code),
        ),
      );
    }
  }

  Future<bool> _collectionHasDocs(final String path) async {
    final snap = await _firestore.collection(path).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  String _solvedDocId({
    required final String puzzleDate,
    required final String configId,
    required final String signature,
  }) {
    final bytes = utf8.encode('$puzzleDate|$configId|$signature');
    return sha256.convert(bytes).toString();
  }
}

PuzzleSessionDifficulty _difficultyFromIndex(final int? index) {
  if (index == null) return PuzzleSessionDifficulty.hard;
  return PuzzleSessionDifficulty.values.elementAt(index.clamp(0, PuzzleSessionDifficulty.values.length - 1));
}

PuzzleSessionStatus _statusFromIndex(final int? index) {
  if (index == null) return PuzzleSessionStatus.unsolved;
  return PuzzleSessionStatus.values.elementAt(index.clamp(0, PuzzleSessionStatus.values.length - 1));
}

