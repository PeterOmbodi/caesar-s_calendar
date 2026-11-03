import 'dart:async';

import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// What this device knows about one player's leaderboard participation. Every change goes through
/// a method here, so the transitions around each `await` in [PublicProfileService] stay checkable.
class _PlayerState {
  /// Null until read from the server.
  bool? enabled;
  bool showName = false;
  bool deletionPending = false;
  String? publishedKey;

  /// Bumped by each name toggle; the server value may override [showName] only once the toggle is published.
  int nameVersion = 0;
  int publishedNameVersion = 0;

  bool get hasUnpublishedName => nameVersion != publishedNameVersion;

  void applyServer({required final String? source}) {
    enabled = source != null;
    if (source == null) publishedKey = null;
    if (!hasUnpublishedName) showName = source == LeaderboardProfile.sourceName;
  }

  void toggleName(final bool value) {
    showName = value;
    nameVersion++;
  }

  void enable() {
    enabled = true;
    deletionPending = false;
    publishedKey = null;
  }

  void disable() {
    enabled = false;
    deletionPending = true;
    publishedKey = null;
  }

  void consentLost() {
    enabled = false;
    publishedKey = null;
  }

  void published({required final String key, required final int nameVersionAtStart}) {
    publishedKey = key;
    if (nameVersion == nameVersionAtStart) publishedNameVersion = nameVersionAtStart;
  }
}

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
  final _players = <String, _PlayerState>{};

  Future<bool> isEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    final player = _player(uid);
    if (player.enabled == null) player.applyServer(source: await _leaderboards.nicknameSource(uid));
    return player.enabled ?? false;
  }

  /// Off by default: the nickname is generated from the uid.
  bool get showName => switch (_uid) {
    final uid? => _player(uid).showName,
    null => false,
  };

  /// Applies at once; the new nickname is published by [publishNow], also in past entries.
  void setShowName(final bool showName) {
    final uid = _uid;
    if (uid != null) _player(uid).toggleName(showName);
  }

  /// Applies at once; publishing and deletion run in [publishNow].
  void setEnabled(final bool enabled) {
    final uid = _uid;
    if (uid == null) return;
    final player = _player(uid);
    if (!enabled) {
      player.disable();
      return;
    }
    player.enable();
    _createProfile(uid, player);
  }

  /// Deletes if pending, otherwise publishes while consent holds and fixes stale nicknames.
  Future<void> publishNow() async {
    final uid = _uid;
    if (uid == null) return;
    final player = _player(uid);

    if (player.deletionPending) {
      await _leaderboards.deleteAll(uid);
      // Turned on again while deleting: the deletion may have removed the new profile.
      if (player.enabled ?? false) {
        _createProfile(uid, player);
      } else {
        player.deletionPending = false;
      }
      return;
    }

    // Consent or the name setting may have changed on another device.
    player.applyServer(source: await _leaderboards.nicknameSource(uid));
    if (player.enabled != true) return;

    final nameVersion = player.nameVersion;
    final snapshot = await _publisher.build(uid: uid, displayName: _displayName(player), now: DateTime.now());
    if (player.enabled != true) return;
    final key = snapshot.key;
    if (key != player.publishedKey) {
      if (!await _leaderboards.publish(uid: uid, snapshot: snapshot)) {
        player.consentLost();
        return;
      }
    }
    // A toggle during this run is published by the run it queues.
    player.published(key: key, nameVersionAtStart: nameVersion);
    await _leaderboards.renameAll(uid, snapshot.profile.nickname);
  }

  _PlayerState _player(final String uid) => _players.putIfAbsent(uid, _PlayerState.new);

  void _createProfile(final String uid, final _PlayerState player) {
    player.deletionPending = false;
    final profile = _publisher.emptySnapshot(uid: uid, displayName: _displayName(player)).profile;
    // Not awaited: Firestore applies the write locally and sends it once online.
    unawaited(
      _leaderboards
          .createProfile(uid: uid, profile: profile)
          .catchError((final Object e) => debugPrint('Leaderboard profile create failed: $e')),
    );
  }

  String? _displayName(final _PlayerState player) => player.showName ? _auth.currentDisplayName : null;

  String? get _uid => _auth.isAvailable ? _auth.currentUser?.uid : null;
}
