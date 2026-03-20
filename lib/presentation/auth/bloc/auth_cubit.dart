import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_failure.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._auth,
    this._historyRepository,
    this._syncService,
    this._puzzleHistoryUseCase,
    this._syncRunner,
    this._publicProfileService,
  ) : super(AuthState.initial(isAvailable: _auth.isAvailable)) {
    _init();
  }

  final AuthService _auth;
  final PuzzleHistoryRepository _historyRepository;
  final SyncService _syncService;
  final PuzzleHistoryUseCase _puzzleHistoryUseCase;
  final SyncRunner _syncRunner;
  final PublicProfileService _publicProfileService;

  StreamSubscription<User?>? _sub;

  Future<void> _init() async {
    if (!_auth.isAvailable) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    await _sub?.cancel();
    _sub = _auth.userChanges().listen(
      _onUserChanged,
      onError: (final e, _) => emit(state.copyWith(isLoading: false, errorMessage: e.toString())),
    );
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _ensureGuestSession();
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _auth.signInWithGoogle(linkIfAnonymous: true);
    await _handleAuthResult(result);
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _auth.signInWithApple(linkIfAnonymous: true);
    await _handleAuthResult(result);
  }

  Future<void> confirmAccountSwitch() async {
    final request = state.pendingAccountSwitch;
    if (request == null) return;
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        pendingAccountSwitch: null,
      ),
    );
    try {
      await _runWithSyncPaused(() async {
        await _resetLocalProfile();
        final result = await _auth.switchToExistingProviderAccount(
          providerKind: request.providerKind,
          credential: request.credential,
        );
        await _handleAuthResult(result);
      });
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void cancelAccountSwitch() {
    emit(state.copyWith(isLoading: false, pendingAccountSwitch: null));
  }

  Future<void> signOut() async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        pendingAccountSwitch: null,
      ),
    );
    try {
      await _runWithSyncPaused(() async {
        await _resetLocalProfile();
        await _auth.signOut();
        await _ensureGuestSession();
      });
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteAccount() async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        pendingAccountSwitch: null,
      ),
    );
    try {
      await _runWithSyncPaused(() async {
        await _auth.deleteCurrentAccount();
        await _resetLocalProfile();
        await _ensureGuestSession();
      });
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _runWithSyncPaused(final Future<void> Function() action) async {
    await _syncRunner.pause();
    try {
      await action();
    } finally {
      _syncRunner.resume();
    }
  }

  Future<void> _ensureGuestSession() async {
    final user = await _auth.ensureSignedIn();
    emit(
      state.copyWith(
        user: user,
        isLoading: false,
        errorMessage: user == null ? 'Unable to sign in as guest.' : null,
      ),
    );
  }

  void _onUserChanged(final User? user) {
    emit(state.copyWith(user: user, isLoading: false));
  }

  Future<void> _handleAuthResult(final Either<AuthFailure, UserCredential> result) async {
    await result.fold((final failure) async {
      if (failure case final AuthAccountSwitchRequiredFailure switchFailure) {
        emit(
          state.copyWith(
            isLoading: false,
            pendingAccountSwitch: AccountSwitchRequest(
              providerKind: switchFailure.providerKind,
              credential: switchFailure.credential,
            ),
            errorMessage: failure.message,
          ),
        );
        return;
      }
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
    }, (_) async {
      _syncRunner.requestSync();
      await _publicProfileService.publishNow();
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          pendingAccountSwitch: null,
        ),
      );
    });
  }

  Future<void> _resetLocalProfile() async {
    await _historyRepository.clearLocalData();
    await _syncService.clearAllSyncCheckpoints();
    _puzzleHistoryUseCase.resetSession();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
