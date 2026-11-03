import 'dart:async';

import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
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
  final _showName = <String, bool>{};
  // The server value overrides a local name toggle only after that toggle is published.
  final _nameVersion = <String, int>{};
  final _publishedNameVersion = <String, int>{};
  final _pendingDeletion = <String>{};
  String? _lastPublishedKey;

  Future<bool> isEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    if (!_enabled.containsKey(uid)) await _refresh(uid);
    return _enabled[uid]!;
  }

  /// Off by default: the nickname is generated from the uid.
  bool get showName => _showName[_uid] ?? false;

  /// Applies at once; the new nickname is published by [publishNow], also in past entries.
  void setShowName(final bool showName) {
    final uid = _uid;
    if (uid == null) return;
    _showName[uid] = showName;
    _nameVersion[uid] = (_nameVersion[uid] ?? 0) + 1;
  }

  /// Applies at once; publishing and deletion run in [publishNow].
  void setEnabled(final bool enabled) {
    final uid = _uid;
    if (uid == null) return;
    _enabled[uid] = enabled;
    _lastPublishedKey = null;
    if (enabled) {
      _pendingDeletion.remove(uid);
      // Not awaited: Firestore applies the write locally and sends it once online.
      final profile = _publisher.emptySnapshot(uid: uid, displayName: _displayName(uid)).profile;
      unawaited(
        _leaderboards
            .createProfile(uid: uid, profile: profile)
            .catchError((final Object e) => debugPrint('Leaderboard profile create failed: $e')),
      );
    } else {
      _pendingDeletion.add(uid);
    }
  }

  /// Deletes if pending, otherwise publishes while consent holds and fixes stale nicknames.
  Future<void> publishNow() async {
    final uid = _uid;
    if (uid == null) return;
    if (_pendingDeletion.contains(uid)) {
      await _leaderboards.deleteAll(uid);
      _pendingDeletion.remove(uid);
      return;
    }
    // Consent or the name setting may have changed on another device.
    await _refresh(uid);
    if (_enabled[uid] != true) return;
    final nameVersion = _nameVersion[uid] ?? 0;
    final snapshot = await _publisher.build(uid: uid, displayName: _displayName(uid), now: DateTime.now());
    if (_enabled[uid] != true) return;
    final key = '$uid|${snapshot.key}';
    if (key != _lastPublishedKey) {
      if (!await _leaderboards.publish(uid: uid, snapshot: snapshot)) {
        _enabled[uid] = false;
        _lastPublishedKey = null;
        return;
      }
      _lastPublishedKey = key;
    }
    // A toggle during this run is published by the run it queues.
    if ((_nameVersion[uid] ?? 0) == nameVersion) _publishedNameVersion[uid] = nameVersion;
    await _leaderboards.renameAll(uid, snapshot.profile.nickname);
  }

  Future<void> _refresh(final String uid) async {
    final source = await _leaderboards.nicknameSource(uid);
    _enabled[uid] = source != null;
    if (source == null) _lastPublishedKey = null;
    if ((_publishedNameVersion[uid] ?? 0) == (_nameVersion[uid] ?? 0)) {
      _showName[uid] = source == LeaderboardProfile.sourceName;
    }
  }

  String? _displayName(final String uid) => (_showName[uid] ?? false) ? _auth.currentDisplayName : null;

  String? get _uid => _auth.isAvailable ? _auth.currentUser?.uid : null;
}
