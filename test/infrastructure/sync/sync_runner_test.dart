import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start can register lifecycle handling without requesting sync', () async {
    final runner = _TrackingSyncRunner();

    runner.start(requestImmediateSync: false);

    expect(runner.requestCount, 0);
    await runner.dispose();
  });

  test('start requests sync by default', () async {
    final runner = _TrackingSyncRunner();

    runner.start();

    expect(runner.requestCount, 1);
    await runner.dispose();
  });

  test('exclusive sync updates status after completing sync and profile publish', () async {
    final sync = _FakeSyncService();
    final profile = _FakePublicProfileService();
    final status = SyncStatusService();
    final runner = SyncRunner(_FakeAuthService(), sync, profile, status);

    await runner.pause();
    await runner.runExclusiveSync();

    expect(sync.syncCount, 1);
    expect(profile.publishCount, 1);
    expect(status.state.isSyncing, isFalse);
    expect(status.state.lastSuccessAtMs, isNotNull);
    await runner.dispose();
    await status.dispose();
  });
}

class _TrackingSyncRunner extends SyncRunner {
  _TrackingSyncRunner()
    : super(_FakeAuthService(), _FakeSyncService(), _FakePublicProfileService(), _FakeSyncStatusService());

  int requestCount = 0;

  @override
  void requestSync() {
    requestCount++;
  }
}

class _FakeAuthService implements AuthService {
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncService implements SyncService {
  int syncCount = 0;

  @override
  Future<void> syncOnce() async {
    syncCount++;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePublicProfileService implements PublicProfileService {
  int publishCount = 0;

  @override
  Future<void> publishNow() async {
    publishCount++;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncStatusService implements SyncStatusService {
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}
