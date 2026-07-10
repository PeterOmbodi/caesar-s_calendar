import 'dart:async';

import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_status_service.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggle is re-enabled when the profile update times out', () async {
    final status = SyncStatusService();
    final cubit = PublicProfileCubit.withOperationTimeout(
      _HangingPublicProfileService(),
      _FakeAuthService(),
      _FakeSyncRunner(),
      status,
      operationTimeout: const Duration(milliseconds: 10),
    );
    await cubit.stream.firstWhere((final state) => !state.isLoading);

    await cubit.toggleEnabled(true);

    expect(cubit.state.isUpdating, isFalse);
    expect(cubit.state.enabled, isFalse);
    expect(cubit.state.errorMessage, contains('TimeoutException'));
    await cubit.close();
    await status.dispose();
  });
}

class _HangingPublicProfileService implements PublicProfileService {
  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(final bool enabled) => Completer<void>().future;

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
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}
