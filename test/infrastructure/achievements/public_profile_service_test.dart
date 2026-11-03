import 'dart:async';

import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

const _anonymous = 'Swift Otter 47';
const _named = 'Peter O.';

/// Models the server: the profile and the nickname kept in past entries.
class _Repository implements LeaderboardRepository {
  String? source;
  String? entriesNickname;
  int publishes = 0;
  int deletions = 0;

  /// Holds the next deletion until the test completes it.
  Completer<void>? deleteGate;

  /// Thrown once by the next call.
  Object? deleteFailure;
  Object? renameFailure;

  /// Holds the next profile read until the test completes it.
  Completer<void>? readGate;

  @override
  Future<String?> nicknameSource(final String uid) async {
    final value = source;
    final gate = readGate;
    readGate = null;
    await gate?.future;
    return value;
  }

  @override
  Future<void> createProfile({required final String uid, required final LeaderboardProfile profile}) async =>
      source = profile.nicknameSource;

  @override
  Future<bool> publish({required final String uid, required final LeaderboardSnapshot snapshot}) async {
    if (source == null) return false;
    publishes++;
    source = snapshot.profile.nicknameSource;
    entriesNickname ??= snapshot.profile.nickname;
    return true;
  }

  @override
  Future<void> renameAll(final String uid, final String nickname) async {
    if (renameFailure case final failure?) {
      renameFailure = null;
      throw failure;
    }
    if (entriesNickname != null) entriesNickname = nickname;
  }

  @override
  Future<void> deleteAll(final String uid) async {
    if (deleteFailure case final failure?) {
      deleteFailure = null;
      throw failure;
    }
    source = null;
    final gate = deleteGate;
    deleteGate = null;
    await gate?.future;
    // Worst case: the profile created meanwhile is deleted too.
    source = null;
    deletions++;
    entriesNickname = null;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns the same snapshot until [results] changes.
class _Publisher implements LeaderboardPublisher {
  int results = 60000;

  /// Set to hold the next build, i.e. the time between reading consent and writing.
  Completer<void>? buildGate;

  static LeaderboardProfile _profile(final String? displayName) => LeaderboardProfile(
    nickname: displayName ?? _anonymous,
    nicknameSource: displayName == null ? LeaderboardProfile.sourceGenerated : LeaderboardProfile.sourceName,
    colorIndex: 0,
    streaks: const {},
  );

  @override
  LeaderboardSnapshot emptySnapshot({required final String uid, required final String? displayName}) =>
      LeaderboardSnapshot(profile: _profile(displayName), entries: const {});

  @override
  Future<LeaderboardSnapshot> build({
    required final String uid,
    required final String? displayName,
    required final DateTime now,
  }) async {
    final gate = buildGate;
    buildGate = null;
    await gate?.future;
    final profile = _profile(displayName);
    return LeaderboardSnapshot(
      profile: profile,
      entries: {
        'd2026-11-03_hard': DayEntry(
          uid: uid,
          nickname: profile.nickname,
          colorIndex: 0,
          reachedAt: DateTime(2026, 11, 3),
          timeMs: results,
          extraSolutions: 0,
        ),
      },
    );
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements AuthService {
  @override
  bool get isAvailable => true;

  @override
  User? get currentUser => _User();

  @override
  String? get currentDisplayName => _named;

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  String get uid => 'me';

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repository repository;
  late _Publisher publisher;

  PublicProfileService service() => PublicProfileService(auth: _Auth(), leaderboards: repository, publisher: publisher);

  setUp(() {
    repository = _Repository();
    publisher = _Publisher();
  });

  test('turning on creates the profile, then results are published', () async {
    final s = service()..setEnabled(true);
    expect(repository.source, LeaderboardProfile.sourceGenerated);

    await s.publishNow();

    expect(repository.publishes, 1);
  });

  test('unchanged results are not published again; changed ones are', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();

    await s.publishNow();
    await s.publishNow();
    expect(repository.publishes, 1);

    publisher.results = 50000;
    await s.publishNow();
    expect(repository.publishes, 2);
  });

  test('consent withdrawn on another device before reading stops publishing', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    expect(await s.isEnabled(), isTrue);

    repository.source = null;
    await s.publishNow();

    expect(repository.publishes, 0);
    expect(await s.isEnabled(), isFalse);
  });

  test('consent withdrawn while the snapshot is built does not recreate the profile', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    final gate = publisher.buildGate = Completer<void>();

    final run = s.publishNow();
    await pumpEventQueue();
    repository.source = null;
    gate.complete();
    await run;

    expect(repository.source, isNull);
    expect(repository.publishes, 0);
    expect(await s.isEnabled(), isFalse);
  });

  test('consent withdrawn after a publish republishes once given again', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    await s.publishNow();

    repository.source = null;
    await s.publishNow();
    s.setEnabled(true);
    await s.publishNow();

    expect(repository.publishes, 2);
  });

  test('a name toggle during a publish is kept and published by the next run', () async {
    repository
      ..source = LeaderboardProfile.sourceName
      ..entriesNickname = _named;
    final s = service();
    await s.isEnabled();
    final gate = publisher.buildGate = Completer<void>();

    final run = s.publishNow();
    await pumpEventQueue();
    s.setShowName(false);
    gate.complete();
    await run;
    expect(s.showName, isFalse);

    await s.publishNow();
    expect(s.showName, isFalse);
    expect(repository.source, LeaderboardProfile.sourceGenerated);
    expect(repository.entriesNickname, _anonymous);
  });

  test('a failed rename is repaired after a restart', () async {
    repository
      ..source = LeaderboardProfile.sourceName
      ..entriesNickname = _named;
    final first = service();
    await first.isEnabled();
    first.setShowName(false);
    repository.renameFailure = StateError('unavailable');

    await expectLater(first.publishNow(), throwsStateError);
    expect(repository.source, LeaderboardProfile.sourceGenerated);
    expect(repository.entriesNickname, _named);

    await service().publishNow();

    expect(repository.entriesNickname, _anonymous);
  });

  test('name setting from another device is picked up', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    await s.isEnabled();

    repository.source = LeaderboardProfile.sourceName;
    await s.publishNow();

    expect(s.showName, isTrue);
  });

  test('turning off deletes and does not publish', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    await s.isEnabled();

    s.setEnabled(false);
    await s.publishNow();

    expect(repository.deletions, 1);
    expect(repository.publishes, 0);
  });

  test('a failed deletion is retried', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    await s.isEnabled();
    s.setEnabled(false);
    repository.deleteFailure = StateError('unavailable');

    await expectLater(s.publishNow(), throwsStateError);
    await s.publishNow();

    expect(repository.deletions, 1);
  });

  test('turning on again during a deletion recreates the profile', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    await s.isEnabled();
    s.setEnabled(false);
    final gate = repository.deleteGate = Completer<void>();

    final run = s.publishNow();
    await pumpEventQueue();
    s.setEnabled(true);
    gate.complete();
    await run;

    expect(repository.source, LeaderboardProfile.sourceGenerated);
    await s.publishNow();
    expect(repository.publishes, 1);
  });

  test('turning off while the profile is read is not undone by the stale answer', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    final gate = repository.readGate = Completer<void>();

    final run = s.publishNow();
    await pumpEventQueue();
    s.setEnabled(false);
    gate.complete();
    await run;
    expect(await s.isEnabled(), isFalse);
    expect(repository.publishes, 0);

    await s.publishNow();
    expect(repository.deletions, 1);
    expect(repository.source, isNull);
  });

  test('turning off during the first read in isEnabled is kept', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    final s = service();
    final gate = repository.readGate = Completer<void>();

    final read = s.isEnabled();
    await pumpEventQueue();
    s.setEnabled(false);
    gate.complete();

    expect(await read, isFalse);
  });
}
