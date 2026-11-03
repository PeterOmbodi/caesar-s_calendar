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

  /// Bumped by each local turn on or off; a server answer to a request started before it is stale.
  int consentVersion = 0;

  /// Bumped by each name toggle; the server value may override [showName] only once the toggle is published.
  int nameVersion = 0;
  int publishedNameVersion = 0;

  bool get hasUnpublishedName => nameVersion != publishedNameVersion;

  void applyServer({required final String? source, required final int consentVersionAtStart}) {
    if (consentVersion == consentVersionAtStart) {
      enabled = source != null;
      if (source == null) publishedKey = null;
    }
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
    consentVersion++;
  }

  void disable() {
    enabled = false;
    deletionPending = true;
    publishedKey = null;
    consentVersion++;
  }

  void consentLost({required final int consentVersionAtStart}) {
    if (consentVersion != consentVersionAtStart) return;
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
    if (player.enabled == null) await _readServer(uid, player);
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
      final consentVersion = player.consentVersion;
      await _leaderboards.deleteAll(uid);
      if (player.consentVersion == consentVersion) {
        player.deletionPending = false;
      } else if (player.enabled ?? false) {
        // Turned on again while deleting: the deletion may have removed the new profile.
        _createProfile(uid, player);
      }
      return;
    }

    // Consent or the name setting may have changed on another device.
    await _readServer(uid, player);
    // A local turn on or off from here on is handled by the run it queues.
    final consentVersion = player.consentVersion;
    if (player.enabled != true || player.deletionPending) return;

    final nameVersion = player.nameVersion;
    final snapshot = await _publisher.build(uid: uid, displayName: _displayName(player), now: DateTime.now());
    if (player.consentVersion != consentVersion) return;
    final key = snapshot.key;
    if (key != player.publishedKey) {
      if (!await _leaderboards.publish(uid: uid, snapshot: snapshot)) {
        player.consentLost(consentVersionAtStart: consentVersion);
        return;
      }
    }
    // A toggle during this run is published by the run it queues.
    player.published(key: key, nameVersionAtStart: nameVersion);
    await _leaderboards.renameAll(uid, snapshot.profile.nickname);
  }

  _PlayerState _player(final String uid) => _players.putIfAbsent(uid, _PlayerState.new);

  Future<void> _readServer(final String uid, final _PlayerState player) async {
    final consentVersion = player.consentVersion;
    final source = await _leaderboards.nicknameSource(uid);
    player.applyServer(source: source, consentVersionAtStart: consentVersion);
  }

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
