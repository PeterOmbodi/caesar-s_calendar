import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/bloc/leaderboard_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 1, 20);

LeaderboardEntry _entry(final String uid, final int score, [final int secondary = 0]) => LeaderboardEntry(
  uid: uid,
  nickname: 'Player $uid',
  colorIndex: 0,
  score: score,
  secondary: secondary,
  reachedAt: _now,
);

StreakEntry _streak(final String uid, final int best, final int current, final DateTime lastDay) => StreakEntry(
  uid: uid,
  nickname: 'Player $uid',
  colorIndex: 0,
  best: best,
  current: current,
  lastDay: lastDay,
);

class _Repository implements LeaderboardRepository {
  final boards = <String, List<LeaderboardEntry>>{};
  final streaks = <StreakEntry>[];
  final outsideTop = <String>{};

  @override
  Future<List<LeaderboardEntry>> top(final String boardId, {final int limit = 50}) async =>
      (boards[boardId] ?? const []).where((final e) => !outsideTop.contains(e.uid)).take(limit).toList();

  @override
  Future<LeaderboardEntry?> entry(final String boardId, final String uid) async =>
      boards[boardId]?.where((final e) => e.uid == uid).firstOrNull;

  bool offline = false;

  @override
  Future<int> rank(final String boardId, final LeaderboardEntry entry) async {
    if (offline) throw StateError('unavailable');
    return 42;
  }

  @override
  Future<List<StreakEntry>> topStreaks(final PuzzleSessionDifficulty level, {final int limit = 50}) async =>
      streaks.take(limit).toList();

  @override
  Future<StreakEntry?> streakEntry(final PuzzleSessionDifficulty level, final String uid) async =>
      streaks.where((final e) => e.uid == uid).firstOrNull;

  @override
  Future<int> streakRank(final PuzzleSessionDifficulty level, final StreakEntry entry) async => 7;

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements AuthService {
  _Auth(this.uid);

  final String? uid;

  @override
  bool get isAvailable => true;

  @override
  User? get currentUser => uid == null ? null : _User(uid!);

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  _User(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repository repository;

  LeaderboardCubit cubit({final String? uid = 'me'}) => LeaderboardCubit(repository, _Auth(uid));

  setUp(() => repository = _Repository());

  test('ranks equal results together and marks the player', () async {
    repository.boards['d2026-11-01_hard'] = [
      _entry('a', 60000),
      _entry('me', 60000),
      _entry('b', 70000),
    ];
    final c = cubit();

    await c.open(PuzzleSessionDifficulty.hard);
    await c.load(now: _now);

    expect(c.state.rows.map((final r) => r.rank), [1, 1, 3]);
    expect(c.state.rows[1].isMe, isTrue);
    expect(c.state.me, isNull);
  });

  test('own result outside the top comes with its rank', () async {
    repository.boards['w2026-44_medium'] = [_entry('a', 100), _entry('me', 30, 2)];
    repository.outsideTop.add('me');
    final c = cubit();
    await c.open(PuzzleSessionDifficulty.medium);

    await c.selectTab(LeaderboardTab.week);
    await c.load(now: _now);

    expect(c.state.rows, hasLength(1));
    expect(c.state.me?.rank, 42);
    expect(c.state.me?.score, 30);
    expect(c.state.me?.secondary, 2);
  });

  test('table stays when the own rank needs the server and it is unavailable', () async {
    repository.boards['w2026-44_medium'] = [_entry('a', 100), _entry('me', 30)];
    repository.outsideTop.add('me');
    repository.offline = true;
    final c = cubit();
    await c.open(PuzzleSessionDifficulty.medium);

    await c.selectTab(LeaderboardTab.week);
    await c.load(now: _now);

    expect(c.state.error, isNull);
    expect(c.state.rows, hasLength(1));
    expect(c.state.me, isNull);
  });

  test('day tier: always on Medium, on Hard only with an own result', () async {
    final hard = cubit();
    await hard.open(PuzzleSessionDifficulty.hard);
    await hard.load(now: _now);
    expect(hard.state.dayTier, isNull);

    repository.boards['d2026-11-01_hard'] = [_entry('me', 60000)];
    await hard.load(now: _now);
    expect(hard.state.dayTier, DayDifficulty.tier(11, 1));

    final medium = cubit();
    await medium.open(PuzzleSessionDifficulty.medium);
    await medium.load(now: _now);
    expect(medium.state.dayTier, DayDifficulty.tier(11, 1));
  });

  test('streaks drop a current streak that ended before yesterday', () async {
    repository.streaks.addAll([
      _streak('a', 10, 10, DateTime(2026, 10, 20)),
      _streak('b', 5, 3, DateTime(2026, 10, 31)),
    ]);
    final c = cubit(uid: null);
    await c.open(PuzzleSessionDifficulty.hard);

    await c.selectTab(LeaderboardTab.streaks);
    await c.load(now: _now);

    expect([for (final r in c.state.rows) (r.score, r.secondary)], [(10, 0), (5, 3)]);
  });
}
