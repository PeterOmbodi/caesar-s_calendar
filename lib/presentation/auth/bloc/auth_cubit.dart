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
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _lastCloudUidKey = 'last_cloud_uid';

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
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      emit(state.copyWith(user: null, isLoading: false, errorMessage: null));
      return;
    }

    emit(state.copyWith(user: currentUser, isLoading: true, errorMessage: null));
    try {
      await _runWithSyncPaused(() async {
        await _prepareLocalDataForSignedInUser(currentUser.uid);
        await _syncService.syncOnce();
        await _publicProfileService.publishNow();
      });
      await _setLastCloudUid(currentUser.uid);
      emit(state.copyWith(user: currentUser, isLoading: false, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(user: currentUser, isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _runWithSyncPaused(() async {
        final result = await _auth.signInWithGoogle();
        await _handleAuthResult(result);
      });
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _runWithSyncPaused(() async {
        final result = await _auth.signInWithApple();
        await _handleAuthResult(result);
      });
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    final previousUid = _auth.currentUser?.uid;
    emit(state.copyWith(isLoading: true, errorMessage: null, pendingCloudReplace: null));
    try {
      await _runWithSyncPaused(() async {
        if (previousUid != null) {
          await _setLastCloudUid(previousUid);
        }
        await _auth.signOut();
      });
      emit(state.copyWith(user: null, isLoading: false, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> confirmCloudReplace() async {
    final request = state.pendingCloudReplace;
    if (request == null) return;
    emit(state.copyWith(isLoading: true, errorMessage: null, pendingCloudReplace: null));
    try {
      await _runWithSyncPaused(() async {
        await _completeSignedInUserTransition(request.uid);
      });
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> cancelCloudReplace() async {
    emit(state.copyWith(isLoading: true, errorMessage: null, pendingCloudReplace: null));
    try {
      await _runWithSyncPaused(() async {
        await _auth.signOut();
      });
      emit(state.copyWith(user: null, isLoading: false, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteAccount() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _runWithSyncPaused(() async {
        await _auth.deleteCurrentAccount();
        await _clearLastCloudUid();
        await _resetLocalProfile();
      });
      emit(state.copyWith(user: null, isLoading: false, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _runWithSyncPaused(final Future<void> Function() action) async {
    await _syncRunner.pause();
    try {
      await action();
    } finally {
      _syncRunner.resume(requestImmediateSync: false);
    }
  }

  void _onUserChanged(final User? user) {
    emit(state.copyWith(user: user, isLoading: false));
  }

  Future<void> _handleAuthResult(final Either<AuthFailure, UserCredential> result) async {
    await result.fold(
      (final failure) async {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (_) async {
        final uid = _auth.currentUser?.uid;
        if (uid == null) {
          emit(state.copyWith(isLoading: false, errorMessage: 'Signed-in user is missing.'));
          return;
        }
        final hasCloudData = await _syncService.hasCloudData(uid);
        final hasLocalSessions = await _historyRepository.hasAnyLocalSessions();
        if (hasCloudData && hasLocalSessions) {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: null,
              pendingCloudReplace: PendingCloudReplaceRequest(uid: uid),
            ),
          );
          return;
        }
        await _completeSignedInUserTransition(uid);
      },
    );
  }

  Future<void> _completeSignedInUserTransition(final String uid) async {
    await _prepareLocalDataForSignedInUser(uid);
    await _syncService.syncOnce();
    await _publicProfileService.publishNow();
    await _setLastCloudUid(uid);
    emit(state.copyWith(isLoading: false, errorMessage: null, pendingCloudReplace: null));
  }

  Future<void> _prepareLocalDataForSignedInUser(final String uid) async {
    final lastCloudUid = await _getLastCloudUid();
    final hasCloudData = await _syncService.hasCloudData(uid);

    final shouldClearLocalData = lastCloudUid != null || hasCloudData;
    if (shouldClearLocalData) {
      await _resetLocalProfile();
      return;
    }

    await _syncService.clearAllSyncCheckpoints();
  }

  Future<void> _resetLocalProfile() async {
    await _historyRepository.clearLocalData();
    await _syncService.clearAllSyncCheckpoints();
    _puzzleHistoryUseCase.resetSession();
  }

  Future<String?> _getLastCloudUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCloudUidKey);
  }

  Future<void> _setLastCloudUid(final String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCloudUidKey, uid);
  }

  Future<void> _clearLastCloudUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCloudUidKey);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
