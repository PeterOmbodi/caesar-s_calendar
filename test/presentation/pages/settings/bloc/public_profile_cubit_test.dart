import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status_service.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggle applies at once and queues the publish', () async {
    final status = SyncStatusService();
    final profiles = _FakePublicProfileService();
    final runner = _FakeSyncRunner();
    final cubit = PublicProfileCubit(profiles, _FakeAuthService(), runner, status);
    await cubit.stream.firstWhere((final state) => !state.isLoading);

    cubit.toggleEnabled(true);
    expect(cubit.state.enabled, isTrue);
    cubit.toggleEnabled(false);
    expect(cubit.state.enabled, isFalse);

    expect(profiles.calls, [true, false]);
    expect(runner.publishRequests, 2);
    await cubit.close();
    await status.dispose();
  });
}

class _FakePublicProfileService implements PublicProfileService {
  final calls = <bool>[];

  @override
  Future<bool> isEnabled() async => false;

  @override
  void setEnabled(final bool enabled) => calls.add(enabled);

  @override
  bool get showName => false;

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService implements AuthService {
  @override
  bool get isAvailable => true;

  @override
  User? get currentUser => _FakeUser();

  @override
  Stream<User?> userChanges() => const Stream<User?>.empty();

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncRunner implements SyncRunner {
  int publishRequests = 0;

  @override
  void publishProfileNow() => publishRequests++;

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}
