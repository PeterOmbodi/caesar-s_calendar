import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';

abstract class LeaderboardRepository {
  /// Null when the player has no public profile.
  Future<String?> nicknameSource(final String uid);

  /// The only way to create the profile; called when consent is given.
  Future<void> createProfile({required final String uid, required final LeaderboardProfile profile});

  /// Updates the profile and entries in one batch; false, with nothing written, if the profile is gone.
  Future<bool> publish({required final String uid, required final LeaderboardSnapshot snapshot});

  /// Sets [nickname] in every entry of the player that has another one.
  Future<void> renameAll(final String uid, final String nickname);

  /// Removes the profile first, then every entry of the player.
  Future<void> deleteAll(final String uid);

  Future<List<LeaderboardEntry>> top(final String boardId, {final int limit = 50});

  Future<LeaderboardEntry?> entry(final String boardId, final String uid);

  /// 1-based place; equal results share it.
  Future<int> rank(final String boardId, final LeaderboardEntry entry);

  Future<List<StreakEntry>> topStreaks(final PuzzleSessionDifficulty level, {final int limit = 50});

  Future<StreakEntry?> streakEntry(final PuzzleSessionDifficulty level, final String uid);

  Future<int> streakRank(final PuzzleSessionDifficulty level, final StreakEntry entry);
}
