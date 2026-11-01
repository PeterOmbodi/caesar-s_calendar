import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status_service.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'public_profile_cubit.freezed.dart';
part 'public_profile_state.dart';

@injectable
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(this._profiles, this._auth, this._syncRunner, this._syncStatus)
    : operationTimeout = defaultOperationTimeout,
      super(PublicProfileState.initial(syncStatus: _syncStatus.state)) {
    _init();
  }

  @visibleForTesting
  PublicProfileCubit.withOperationTimeout(
    this._profiles,
    this._auth,
    this._syncRunner,
    this._syncStatus, {
    required this.operationTimeout,
  }) : super(PublicProfileState.initial(syncStatus: _syncStatus.state)) {
    _init();
  }

  static const defaultOperationTimeout = Duration(seconds: 15);

  final PublicProfileService _profiles;
  final AuthService _auth;
  final SyncRunner _syncRunner;
  final SyncStatusService _syncStatus;
  final Duration operationTimeout;

  StreamSubscription<Object?>? _authSub;
  StreamSubscription<SyncStatus>? _syncSub;

  Future<void> _init() async {
    _syncSub = _syncStatus.stream.listen((final status) {
      emit(state.copyWith(syncStatus: status));
    });

    if (!_auth.isAvailable) {
      emit(state.copyWith(isAvailable: false, isLoading: false, enabled: false));
      return;
    }

    _authSub = _auth.userChanges().listen((final user) {
      unawaited(_loadForCurrentUser());
    });

    await _loadForCurrentUser();
  }

  void toggleEnabled(final bool enabled) {
    if (!_auth.isAvailable || _auth.currentUser == null) return;
    _profiles.setEnabled(enabled);
    emit(state.copyWith(enabled: enabled, errorMessage: null));
    _syncRunner.publishProfileNow();
  }

  void requestSyncNow() {
    _syncRunner.requestSync();
  }

  Future<void> _loadForCurrentUser() async {
    if (!_auth.isAvailable) {
      emit(state.copyWith(isAvailable: false, isLoading: false, enabled: false, errorMessage: null));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(isAvailable: true, isLoading: false, enabled: false, errorMessage: null));
      return;
    }

    emit(state.copyWith(isAvailable: true, isLoading: true, errorMessage: null));
    try {
      final enabled = await _profiles.isEnabled().timeout(operationTimeout);
      emit(state.copyWith(isLoading: false, enabled: enabled, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, enabled: false, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _syncSub?.cancel();
    return super.close();
  }
}
