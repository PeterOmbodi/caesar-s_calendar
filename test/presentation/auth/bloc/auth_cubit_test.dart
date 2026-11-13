import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_failure.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_service.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _Auth auth;
  late _Sync sync;
  late _Runner runner;

  AuthCubit cubit() => AuthCubit(auth, _History(), sync, PuzzleHistoryUseCase(_History()), runner);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    sync = _Sync();
    runner = _Runner();
  });

  test('a failed cloud-data check after sign-in signs out before any sync', () async {
    sync.hasCloudDataError = StateError('offline');
    final authCubit = cubit();
    await pumpEventQueue();

    await authCubit.signInWithGoogle();

    expect(auth.signOutCount, 1);
    expect(runner.exclusiveSyncs, 0);
    expect(authCubit.state.errorMessage, isNotNull);
    expect((await SharedPreferences.getInstance()).getString('last_cloud_uid'), isNull);
    await authCubit.close();
  });

  test('sync stays paused while the player decides whether to replace local data', () async {
    sync.cloudData = true;
    final authCubit = cubit();
    await pumpEventQueue();

    await authCubit.signInWithGoogle();

    expect(authCubit.state.pendingCloudReplace, isNotNull);
    expect(runner.paused, isTrue);

    await authCubit.cancelCloudReplace();

    expect(runner.paused, isFalse);
    expect(runner.exclusiveSyncs, 0);
    await authCubit.close();
  });

  test('launch with the same account needs no cloud check, so offline it stays signed in', () async {
    SharedPreferences.setMockInitialValues({'last_cloud_uid': 'u1'});
    auth.user = _User();
    sync.hasCloudDataError = StateError('offline');

    final authCubit = cubit();
    await pumpEventQueue();

    expect(auth.signOutCount, 0);
    expect(runner.exclusiveSyncs, 1);
    expect(runner.paused, isFalse);
    await authCubit.close();
  });
}

class _Auth implements AuthService {
  final _changes = StreamController<User?>.broadcast();
  User? user;
  int signOutCount = 0;

  @override
  bool get isAvailable => true;

  @override
  User? get currentUser => user;

  @override
  Stream<User?> userChanges() => _changes.stream;

  @override
  Future<Either<AuthFailure, UserCredential>> signInWithGoogle() async {
    user = _User();
    return Right(_Credential());
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    user = null;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  String get uid => 'u1';

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential implements UserCredential {
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sync implements SyncService {
  bool cloudData = false;
  Object? hasCloudDataError;

  @override
  Future<bool> hasCloudData(final String uid) async {
    if (hasCloudDataError case final error?) throw error;
    return cloudData;
  }

  @override
  Future<void> clearAllSyncCheckpoints() async {}

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _History implements PuzzleHistoryRepository {
  @override
  Future<bool> hasAnyLocalSessions() async => true;

  @override
  Future<void> clearLocalData() async {}

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Runner implements SyncRunner {
  bool paused = false;
  int exclusiveSyncs = 0;

  @override
  Future<void> pause() async {
    paused = true;
  }

  @override
  void resume({final bool requestImmediateSync = true}) {
    paused = false;
  }

  @override
  Future<void> runExclusiveSync() async {
    exclusiveSyncs++;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}
