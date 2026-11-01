import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:injectable/injectable.dart';

/// Leaderboard visibility: the player's public profile exists only while it is on.
@lazySingleton
class PublicProfileService {
  PublicProfileService({
    required final AuthService auth,
    required final LeaderboardRepository leaderboards,
    required final LeaderboardPublisher publisher,
  }) : _auth = auth,
       _leaderboards = leaderboards,
       _publisher = publisher;

  final AuthService _auth;
  final LeaderboardRepository _leaderboards;
  final LeaderboardPublisher _publisher;

  final _enabled = <String, bool>{};
  String? _lastPublishedKey;

  Future<bool> isEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    return _enabled[uid] ??= await _leaderboards.hasProfile(uid);
  }

  Future<void> setEnabled(final bool enabled) async {
    final uid = _uid;
    if (uid == null) return;
    if (enabled) {
      await _publish(uid, force: true);
    } else {
      await _leaderboards.deleteAll(uid);
      _lastPublishedKey = null;
    }
    _enabled[uid] = enabled;
  }

  /// Publishes only when visibility is on and the data changed since the last publish.
  Future<void> publishNow() async {
    final uid = _uid;
    if (uid == null || !await isEnabled()) return;
    await _publish(uid, force: false);
  }

  String? get _uid => _auth.isAvailable ? _auth.currentUser?.uid : null;

  Future<void> _publish(final String uid, {required final bool force}) async {
    final snapshot = await _publisher.build(uid: uid, displayName: _auth.currentDisplayName, now: DateTime.now());
    final key = '$uid|${snapshot.key}';
    if (!force && key == _lastPublishedKey) return;
    await _leaderboards.publish(uid: uid, snapshot: snapshot);
    _lastPublishedKey = key;
  }
}
