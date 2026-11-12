import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LeaderboardRepository)
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._firestore);

  static const _batchLimit = 500;

  final FirebaseFirestore _firestore;

  @override
  Future<String?> nicknameSource(final String uid) async {
    final data = (await _profile(uid).get()).data();
    return data == null ? null : data['nicknameSource'] as String? ?? LeaderboardProfile.sourceGenerated;
  }

  @override
  Future<void> createProfile({required final String uid, required final LeaderboardProfile profile}) =>
      _profile(uid).set(_profileMap(profile, forUpdate: false));

  @override
  Future<bool> publish({required final String uid, required final LeaderboardSnapshot snapshot}) async {
    // `update` fails on a missing profile, so withdrawn consent rejects the whole batch.
    final batch = _firestore.batch()..update(_profile(uid), _profileMap(snapshot.profile, forUpdate: true));
    for (final MapEntry(key: boardId, value: entry) in snapshot.entries.entries) {
      batch.set(_entries(boardId).doc(uid), _toMap(entry));
    }
    for (final boardId in snapshot.boards.difference(snapshot.entries.keys.toSet())) {
      batch.delete(_entries(boardId).doc(uid));
    }
    try {
      await batch.commit();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') return false;
      rethrow;
    }
  }

  @override
  Future<void> renameAll(final String uid, final String nickname) async {
    final stale = await _ownEntries(uid).where('nickname', isNotEqualTo: nickname).get();
    final refs = [for (final doc in stale.docs) doc.reference];
    await _inBatches(refs, (final batch, final ref) => batch.update(ref, {'nickname': nickname}));
  }

  @override
  Future<void> deleteAll(final String uid) async {
    // Profile first: later publishes are rejected, earlier ones' entries are found below.
    await _profile(uid).delete();
    final own = await _ownEntries(uid).get();
    await _inBatches([for (final doc in own.docs) doc.reference], (final batch, final ref) => batch.delete(ref));
  }

  Query<Map<String, dynamic>> _ownEntries(final String uid) =>
      _firestore.collectionGroup(FirestorePaths.leaderboardEntries).where('uid', isEqualTo: uid);

  static Map<String, Object?> _profileMap(final LeaderboardProfile profile, {required final bool forUpdate}) => {
    'nickname': profile.nickname,
    'nicknameSource': profile.nicknameSource,
    'colorIndex': profile.colorIndex,
    'updatedAt': FieldValue.serverTimestamp(),
    'schemaVersion': 1,
    for (final MapEntry(key: level, value: streak) in profile.streaks.entries) ...{
      'bestStreak${_capitalized(level.name)}': streak.best,
      'currentStreak${_capitalized(level.name)}': streak.current,
      if (streak.lastDay case final lastDay?)
        'streakLastDay${_capitalized(level.name)}': _dayKey(lastDay)
      else if (forUpdate)
        'streakLastDay${_capitalized(level.name)}': FieldValue.delete(),
    },
  };

  Future<void> _inBatches(
    final List<DocumentReference<Map<String, dynamic>>> refs,
    final void Function(WriteBatch batch, DocumentReference<Map<String, dynamic>> ref) apply,
  ) async {
    for (var i = 0; i < refs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(_batchLimit)) {
        apply(batch, ref);
      }
      await batch.commit();
    }
  }

  @override
  Future<List<LeaderboardEntry>> top(final String boardId, {final int limit = 50}) async {
    final query = LeaderboardKeys.isDayBoard(boardId)
        ? _entries(boardId).orderBy('timeMs')
        : _entries(boardId).orderBy('points', descending: true);
    final snapshot = await query.orderBy('reachedAt').limit(limit).get();
    return [for (final doc in snapshot.docs) _fromMap(boardId, doc.data())];
  }

  @override
  Future<LeaderboardEntry?> entry(final String boardId, final String uid) async {
    final data = (await _entries(boardId).doc(uid).get()).data();
    return data == null ? null : _fromMap(boardId, data);
  }

  @override
  Future<int> rank(final String boardId, final LeaderboardEntry entry) async {
    final better = switch (entry) {
      DayEntry(:final timeMs) => _entries(boardId).where('timeMs', isLessThan: timeMs),
      PeriodEntry(:final points) => _entries(boardId).where('points', isGreaterThan: points),
    };
    final count = (await better.count().get()).count ?? 0;
    return count + 1;
  }

  @override
  Future<List<StreakEntry>> topStreaks(final PuzzleSessionDifficulty level, {final int limit = 50}) async {
    final field = _bestStreakField(level);
    final snapshot = await _firestore
        .collection(FirestorePaths.publicUsers)
        .where(field, isGreaterThan: 0)
        .orderBy(field, descending: true)
        .limit(limit)
        .get();
    return [for (final doc in snapshot.docs) _streakFromMap(level, doc.id, doc.data())];
  }

  @override
  Future<StreakEntry?> streakEntry(final PuzzleSessionDifficulty level, final String uid) async {
    final data = (await _profile(uid).get()).data();
    return data == null ? null : _streakFromMap(level, uid, data);
  }

  @override
  Future<int> streakRank(final PuzzleSessionDifficulty level, final StreakEntry entry) async {
    final better = _firestore
        .collection(FirestorePaths.publicUsers)
        .where(_bestStreakField(level), isGreaterThan: entry.best);
    return ((await better.count().get()).count ?? 0) + 1;
  }

  DocumentReference<Map<String, dynamic>> _profile(final String uid) =>
      _firestore.doc(FirestorePaths.publicUserDoc(uid));

  CollectionReference<Map<String, dynamic>> _entries(final String boardId) =>
      _firestore.collection(FirestorePaths.leaderboardEntriesOf(boardId));

  static Map<String, Object?> _toMap(final LeaderboardEntry entry) => {
    'uid': entry.uid,
    'nickname': entry.nickname,
    'colorIndex': entry.colorIndex,
    ...switch (entry) {
      DayEntry(:final timeMs, :final extraSolutions) => {'timeMs': timeMs, 'extra': extraSolutions},
      PeriodEntry(:final points, :final days) => {'points': points, 'days': days},
    },
    'reachedAt': Timestamp.fromDate(entry.reachedAt),
    if (entry.expireAt case final expireAt?) 'expireAt': Timestamp.fromDate(expireAt),
  };

  static LeaderboardEntry _fromMap(final String boardId, final Map<String, dynamic> data) {
    final uid = data['uid'] as String;
    final nickname = data['nickname'] as String;
    final colorIndex = data['colorIndex'] as int;
    final reachedAt = (data['reachedAt'] as Timestamp).toDate();
    final expireAt = (data['expireAt'] as Timestamp?)?.toDate();
    return LeaderboardKeys.isDayBoard(boardId)
        ? DayEntry(
            uid: uid,
            nickname: nickname,
            colorIndex: colorIndex,
            reachedAt: reachedAt,
            expireAt: expireAt,
            timeMs: data['timeMs'] as int,
            extraSolutions: data['extra'] as int,
          )
        : PeriodEntry(
            uid: uid,
            nickname: nickname,
            colorIndex: colorIndex,
            reachedAt: reachedAt,
            expireAt: expireAt,
            points: data['points'] as int,
            days: data['days'] as int,
          );
  }

  static String _bestStreakField(final PuzzleSessionDifficulty level) => 'bestStreak${_capitalized(level.name)}';

  static StreakEntry _streakFromMap(
    final PuzzleSessionDifficulty level,
    final String uid,
    final Map<String, dynamic> data,
  ) {
    final name = _capitalized(level.name);
    final lastDay = data['streakLastDay$name'] as String?;
    return StreakEntry(
      uid: uid,
      nickname: data['nickname'] as String,
      colorIndex: data['colorIndex'] as int,
      best: data['bestStreak$name'] as int? ?? 0,
      current: data['currentStreak$name'] as int? ?? 0,
      lastDay: lastDay == null ? null : DateTime.parse(lastDay),
    );
  }

  static String _capitalized(final String value) => '${value[0].toUpperCase()}${value.substring(1)}';

  static String _dayKey(final DateTime day) {
    String two(final int value) => value.toString().padLeft(2, '0');
    return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-${two(day.day)}';
  }
}
