import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

const _anonymous = 'Swift Otter 47';
const _named = 'Peter O.';

/// Models the server: the profile document and the nickname in past entries.
class _Repository implements LeaderboardRepository {
  String? source;
  String? entriesNickname;
  int publishes = 0;
  int deletions = 0;
  bool failRename = false;

  @override
  Future<String?> nicknameSource(final String uid) async => source;

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
    if (failRename) throw StateError('unavailable');
    if (entriesNickname != null) entriesNickname = nickname;
  }

  @override
  Future<void> deleteAll(final String uid) async {
    deletions++;
    source = null;
    entriesNickname = null;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Publisher implements LeaderboardPublisher {
  /// Runs between reading consent and writing.
  void Function()? duringBuild;
  int _version = 0;

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
    final hook = duringBuild;
    duringBuild = null;
    hook?.call();
    final profile = _profile(displayName);
    return LeaderboardSnapshot(
      profile: profile,
      entries: {
        'd2026-11-03_hard': LeaderboardEntry(
          uid: 'me',
          nickname: profile.nickname,
          colorIndex: 0,
          score: 60000 + ++_version,
          secondary: 0,
          reachedAt: DateTime(2026, 11, 3),
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
    publisher.duringBuild = () => repository.deleteAll('me');

    await s.publishNow();

    expect(repository.source, isNull);
    expect(repository.publishes, 0);
    expect(await s.isEnabled(), isFalse);
  });

  test('a name toggle during a publish is kept and published by the next run', () async {
    repository.source = LeaderboardProfile.sourceName;
    repository.entriesNickname = _named;
    final s = service();
    await s.isEnabled();
    publisher.duringBuild = () => s.setShowName(false);

    await s.publishNow();
    expect(s.showName, isFalse);

    await s.publishNow();
    expect(s.showName, isFalse);
    expect(repository.source, LeaderboardProfile.sourceGenerated);
    expect(repository.entriesNickname, _anonymous);
  });

  test('a failed rename is repaired after a restart', () async {
    repository.source = LeaderboardProfile.sourceName;
    repository.entriesNickname = _named;
    final first = service();
    await first.isEnabled();
    first.setShowName(false);
    repository.failRename = true;

    await expectLater(first.publishNow(), throwsStateError);
    expect(repository.source, LeaderboardProfile.sourceGenerated);
    expect(repository.entriesNickname, _named);

    repository.failRename = false;
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
}
