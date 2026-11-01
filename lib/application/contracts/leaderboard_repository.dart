import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  Future<bool> hasProfile(final String uid);

  Future<void> publish({required final String uid, required final LeaderboardSnapshot snapshot});

  /// Removes the profile and every entry of the player.
  Future<void> deleteAll(final String uid);

  Future<List<LeaderboardEntry>> top(final String boardId, {final int limit = 50});

  Future<LeaderboardEntry?> entry(final String boardId, final String uid);

  /// 1-based place; equal results share it.
  Future<int> rank(final String boardId, final LeaderboardEntry entry);
}
