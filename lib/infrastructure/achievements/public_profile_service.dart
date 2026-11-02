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
  final _pendingDeletion = <String>{};
  // Local choices not yet published; the server state must not override them.
  final _pendingEnable = <String>{};
  final _pendingRename = <String>{};
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
    _pendingRename.add(uid);
  }

  /// Applies at once; publishing and deletion run later in [publishNow].
  void setEnabled(final bool enabled) {
    final uid = _uid;
    if (uid == null) return;
    _enabled[uid] = enabled;
    _lastPublishedKey = null;
    if (enabled) {
      _pendingDeletion.remove(uid);
      _pendingEnable.add(uid);
      // Not awaited: Firestore applies the write locally and sends it once online.
      final profile = _publisher.emptySnapshot(uid: uid, displayName: _displayName(uid));
      unawaited(
        _leaderboards
            .publish(uid: uid, snapshot: profile)
            .catchError((final Object e) => debugPrint('Leaderboard profile create failed: $e')),
      );
    } else {
      _pendingEnable.remove(uid);
      _pendingRename.remove(uid);
      _pendingDeletion.add(uid);
    }
  }

  /// Runs a pending deletion, otherwise publishes if consent is still given and the data changed.
  Future<void> publishNow() async {
    final uid = _uid;
    if (uid == null) return;
    if (_pendingDeletion.contains(uid)) {
      await _leaderboards.deleteAll(uid);
      _pendingDeletion.remove(uid);
      return;
    }
    // Consent may have been withdrawn or the name setting changed on another device.
    if (!_pendingEnable.contains(uid)) await _refresh(uid);
    if (_enabled[uid] != true) return;
    final nickname = await _publish(uid);
    _pendingEnable.remove(uid);
    if (nickname != null && _pendingRename.contains(uid)) {
      await _leaderboards.renameAll(uid, nickname);
      _pendingRename.remove(uid);
    }
  }

  Future<void> _refresh(final String uid) async {
    final source = await _leaderboards.nicknameSource(uid);
    _enabled[uid] = source != null;
    if (source == null) _lastPublishedKey = null;
    if (!_pendingRename.contains(uid)) _showName[uid] = source == LeaderboardProfile.sourceName;
  }

  String? _displayName(final String uid) => (_showName[uid] ?? false) ? _auth.currentDisplayName : null;

  String? get _uid => _auth.isAvailable ? _auth.currentUser?.uid : null;

  /// Returns the published nickname, or null when visibility was turned off meanwhile.
  Future<String?> _publish(final String uid) async {
    final snapshot = await _publisher.build(uid: uid, displayName: _displayName(uid), now: DateTime.now());
    final key = '$uid|${snapshot.key}';
    if (_enabled[uid] != true) return null;
    if (key != _lastPublishedKey) {
      await _leaderboards.publish(uid: uid, snapshot: snapshot);
      _lastPublishedKey = key;
    }
    // Turned off while publishing: the deletion may have run before this write landed.
    if (_enabled[uid] != true) {
      _lastPublishedKey = null;
      _pendingDeletion.add(uid);
      return null;
    }
    return snapshot.profile.nickname;
  }
}
