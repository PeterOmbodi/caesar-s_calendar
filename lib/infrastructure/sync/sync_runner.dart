import 'dart:async';

import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status_service.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SyncRunner {
  SyncRunner(this._auth, this._sync, this._publicProfile, this._status);

  final AuthService _auth;
  final SyncService _sync;
  final PublicProfileService _publicProfile;
  final SyncStatusService _status;

  AppLifecycleListener? _lifecycleListener;
  bool _running = false;
  bool _suspended = false;
  bool _pendingSync = false;
  bool _pendingProfilePublish = false;

  void start() {
    _lifecycleListener ??= AppLifecycleListener(onStateChange: _onLifecycleChanged);
    requestSync();
  }

  void stop() {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }

  void requestSync() {
    if (_suspended || !_auth.isAvailable || _auth.currentUser == null) return;
    _pendingSync = true;
    unawaited(_drainQueue());
  }

  void publishProfileNow() {
    if (_suspended || !_auth.isAvailable || _auth.currentUser == null) return;
    _pendingProfilePublish = true;
    unawaited(_drainQueue());
  }

  Future<void> pause() async {
    _suspended = true;
    _pendingSync = false;
    _pendingProfilePublish = false;
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void resume({final bool requestImmediateSync = true}) {
    _suspended = false;
    if (requestImmediateSync) {
      requestSync();
    }
  }

  Future<void> _drainQueue() async {
    if (_running || _suspended) return;
    _running = true;
    try {
      while (!_suspended && (_pendingSync || _pendingProfilePublish)) {
        final shouldSync = _pendingSync;
        final shouldPublishProfile = _pendingProfilePublish;
        _pendingSync = false;
        _pendingProfilePublish = false;

        _status.setSyncing();
        if (shouldSync) {
          await _sync.syncOnce();
        }
        if (shouldPublishProfile) {
          await _publicProfile.publishNow();
        }
        _status.setSuccess();
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
      _status.setError(e);
    } finally {
      _running = false;
    }
  }

  void _onLifecycleChanged(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      requestSync();
    }
  }

  Future<void> dispose() async {
    stop();
  }
}

