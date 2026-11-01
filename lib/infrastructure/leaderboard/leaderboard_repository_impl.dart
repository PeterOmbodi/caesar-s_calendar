import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LeaderboardRepository)
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._firestore);

  static const _batchLimit = 500;

  final FirebaseFirestore _firestore;

  @override
  Future<bool> hasProfile(final String uid) async => (await _profile(uid).get()).exists;

  @override
  Future<void> publish({required final String uid, required final LeaderboardSnapshot snapshot}) async {
    final profile = snapshot.profile;
    final batch = _firestore.batch()
      ..set(_profile(uid), {
        'nickname': profile.nickname,
        'nicknameSource': profile.nicknameSource,
        'colorIndex': profile.colorIndex,
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
        for (final MapEntry(key: level, value: streak) in profile.streaks.entries) ...{
          'bestStreak${_capitalized(level.name)}': streak.best,
          'currentStreak${_capitalized(level.name)}': streak.current,
          if (streak.lastDay case final lastDay?) 'streakLastDay${_capitalized(level.name)}': _dayKey(lastDay),
        },
      });
    for (final MapEntry(key: boardId, value: entry) in snapshot.entries.entries) {
      batch.set(_entries(boardId).doc(uid), _toMap(boardId, entry));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteAll(final String uid) async {
    final own = await _firestore.collectionGroup(FirestorePaths.leaderboardEntries).where('uid', isEqualTo: uid).get();
    final refs = [for (final doc in own.docs) doc.reference, _profile(uid)];
    for (var i = 0; i < refs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(_batchLimit)) {
        batch.delete(ref);
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
    final better = LeaderboardKeys.isDayBoard(boardId)
        ? _entries(boardId).where('timeMs', isLessThan: entry.score)
        : _entries(boardId).where('points', isGreaterThan: entry.score);
    final count = (await better.count().get()).count ?? 0;
    return count + 1;
  }

  DocumentReference<Map<String, dynamic>> _profile(final String uid) =>
      _firestore.doc(FirestorePaths.publicUserDoc(uid));

  CollectionReference<Map<String, dynamic>> _entries(final String boardId) =>
      _firestore.collection(FirestorePaths.leaderboardEntriesOf(boardId));

  static Map<String, Object?> _toMap(final String boardId, final LeaderboardEntry entry) {
    final isDay = LeaderboardKeys.isDayBoard(boardId);
    return {
      'uid': entry.uid,
      'nickname': entry.nickname,
      'colorIndex': entry.colorIndex,
      isDay ? 'timeMs' : 'points': entry.score,
      isDay ? 'extra' : 'days': entry.secondary,
      'reachedAt': Timestamp.fromDate(entry.reachedAt),
      if (entry.expireAt case final expireAt?) 'expireAt': Timestamp.fromDate(expireAt),
    };
  }

  static LeaderboardEntry _fromMap(final String boardId, final Map<String, dynamic> data) {
    final isDay = LeaderboardKeys.isDayBoard(boardId);
    return LeaderboardEntry(
      uid: data['uid'] as String,
      nickname: data['nickname'] as String,
      colorIndex: data['colorIndex'] as int,
      score: data[isDay ? 'timeMs' : 'points'] as int,
      secondary: data[isDay ? 'extra' : 'days'] as int,
      reachedAt: (data['reachedAt'] as Timestamp).toDate(),
      expireAt: (data['expireAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _capitalized(final String value) => '${value[0].toUpperCase()}${value.substring(1)}';

  static String _dayKey(final DateTime day) {
    String two(final int value) => value.toString().padLeft(2, '0');
    return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-${two(day.day)}';
  }
}
