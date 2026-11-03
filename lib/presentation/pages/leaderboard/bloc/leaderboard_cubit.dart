import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

enum LeaderboardTab { today, week, month, year, streaks }

/// What a row ranks by; rows with an equal [rankKey] share a place.
sealed class RowValue {
  const RowValue();

  int get rankKey;
}

final class TimeValue extends RowValue {
  const TimeValue({required this.timeMs, required this.extraSolutions});

  final int timeMs;
  final int extraSolutions;

  @override
  int get rankKey => timeMs;
}

final class PointsValue extends RowValue {
  const PointsValue({required this.points, required this.days});

  final int points;
  final int days;

  @override
  int get rankKey => points;
}

final class StreakValue extends RowValue {
  const StreakValue({required this.best, required this.current});

  final int best;
  final int current;

  @override
  int get rankKey => best;
}

@immutable
class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.nickname,
    required this.colorIndex,
    required this.value,
    required this.isMe,
  });

  final int rank;
  final String nickname;
  final int colorIndex;
  final RowValue value;
  final bool isMe;
}

@immutable
class LeaderboardState {
  const LeaderboardState({
    required this.tab,
    required this.isLoading,
    this.rows = const [],
    this.me,
    this.dayTier,
    this.error,
  });

  final LeaderboardTab tab;
  final bool isLoading;
  final List<LeaderboardRow> rows;

  /// The player's own row when it is not among [rows].
  final LeaderboardRow? me;

  /// Shown on Medium, and on Hard only after the player's own solve today.
  final int? dayTier;
  final Object? error;

  LeaderboardState copyWith({
    final LeaderboardTab? tab,
    final bool? isLoading,
    final List<LeaderboardRow>? rows,
    final LeaderboardRow? Function()? me,
    final int? Function()? dayTier,
    final Object? Function()? error,
  }) => LeaderboardState(
    tab: tab ?? this.tab,
    isLoading: isLoading ?? this.isLoading,
    rows: rows ?? this.rows,
    me: me == null ? this.me : me(),
    dayTier: dayTier == null ? this.dayTier : dayTier(),
    error: error == null ? this.error : error(),
  );
}

@injectable
class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository, this._auth)
    : super(const LeaderboardState(tab: LeaderboardTab.today, isLoading: true));

  final LeaderboardRepository _repository;
  final AuthService _auth;

  PuzzleSessionDifficulty _level = PuzzleSessionDifficulty.hard;
  int _request = 0;

  Future<void> open(final PuzzleSessionDifficulty level) {
    _level = level;
    return load();
  }

  Future<void> selectTab(final LeaderboardTab tab) {
    if (tab == state.tab) return Future.value();
    emit(state.copyWith(tab: tab));
    return load();
  }

  Future<void> load({final DateTime? now}) async {
    if (isClosed) return;
    final request = ++_request;
    final tab = state.tab;
    emit(state.copyWith(isLoading: true, error: () => null));
    final uid = _auth.isAvailable ? _auth.currentUser?.uid : null;
    try {
      final today = now ?? DateTime.now();
      final (rows, me) = tab == LeaderboardTab.streaks
          ? await _loadStreaks(uid, today)
          : await _loadBoard(LeaderboardKeys.board(_period(tab), today, _level), uid);
      if (isClosed || request != _request) return;
      final hasOwnResult = me != null || rows.any((final row) => row.isMe);
      final showTier = tab == LeaderboardTab.today && (_level == PuzzleSessionDifficulty.medium || hasOwnResult);
      emit(
        state.copyWith(
          isLoading: false,
          rows: rows,
          me: () => me,
          dayTier: () => showTier ? DayDifficulty.tier(today.month, today.day) : null,
        ),
      );
    } catch (e) {
      debugPrint('Leaderboard load failed: $e');
      if (isClosed || request != _request) return;
      emit(state.copyWith(isLoading: false, rows: const [], me: () => null, error: () => e));
    }
  }

  Future<(List<LeaderboardRow>, LeaderboardRow?)> _loadBoard(final String boardId, final String? uid) async {
    final top = await _repository.top(boardId);
    final rows = _ranked([for (final e in top) (e.uid, e.nickname, e.colorIndex, _entryValue(e))], uid);
    if (uid == null || rows.any((final row) => row.isMe)) return (rows, null);
    return (
      rows,
      await _ownRow(() async {
        final own = await _repository.entry(boardId, uid);
        if (own == null) return null;
        final rank = await _repository.rank(boardId, own);
        return _row(rank, own.nickname, own.colorIndex, _entryValue(own));
      }),
    );
  }

  Future<(List<LeaderboardRow>, LeaderboardRow?)> _loadStreaks(final String? uid, final DateTime today) async {
    StreakValue value(final StreakEntry e) =>
        StreakValue(best: e.best, current: _isAlive(e.lastDay, today) ? e.current : 0);
    final top = await _repository.topStreaks(_level);
    final rows = _ranked([for (final e in top) (e.uid, e.nickname, e.colorIndex, value(e))], uid);
    if (uid == null || rows.any((final row) => row.isMe)) return (rows, null);
    return (
      rows,
      await _ownRow(() async {
        final own = await _repository.streakEntry(_level, uid);
        if (own == null || own.best == 0) return null;
        final rank = await _repository.streakRank(_level, own);
        return _row(rank, own.nickname, own.colorIndex, value(own));
      }),
    );
  }

  /// The own row needs the server (a document read and a count); without it the table is still shown.
  static Future<LeaderboardRow?> _ownRow(final Future<LeaderboardRow?> Function() load) async {
    try {
      return await load();
    } catch (e) {
      debugPrint('Leaderboard own row failed: $e');
      return null;
    }
  }

  static RowValue _entryValue(final LeaderboardEntry entry) => switch (entry) {
    DayEntry(:final timeMs, :final extraSolutions) => TimeValue(timeMs: timeMs, extraSolutions: extraSolutions),
    PeriodEntry(:final points, :final days) => PointsValue(points: points, days: days),
  };

  /// Equal values share a place: 1, 2, 2, 4.
  static List<LeaderboardRow> _ranked(
    final List<(String uid, String nickname, int colorIndex, RowValue value)> entries,
    final String? uid,
  ) {
    final rows = <LeaderboardRow>[];
    for (final (index, (entryUid, nickname, colorIndex, value)) in entries.indexed) {
      final rank = index > 0 && rows.last.value.rankKey == value.rankKey ? rows.last.rank : index + 1;
      rows.add(_row(rank, nickname, colorIndex, value, isMe: entryUid == uid));
    }
    return rows;
  }

  static LeaderboardRow _row(
    final int rank,
    final String nickname,
    final int colorIndex,
    final RowValue value, {
    final bool isMe = true,
  }) => LeaderboardRow(rank: rank, nickname: nickname, colorIndex: colorIndex, value: value, isMe: isMe);

  static bool _isAlive(final DateTime? lastDay, final DateTime today) {
    if (lastDay == null) return false;
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(lastDay.year, lastDay.month, lastDay.day)).inDays;
    return days <= 1;
  }

  static LeaderboardPeriod _period(final LeaderboardTab tab) => switch (tab) {
    LeaderboardTab.today => LeaderboardPeriod.today,
    LeaderboardTab.week => LeaderboardPeriod.week,
    LeaderboardTab.month => LeaderboardPeriod.month,
    LeaderboardTab.year || LeaderboardTab.streaks => LeaderboardPeriod.year,
  };
}
