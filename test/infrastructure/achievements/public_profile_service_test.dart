import 'package:caesar_puzzle/application/contracts/leaderboard_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/infrastructure/achievements/public_profile_service.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements LeaderboardRepository {
  String? source;
  final published = <String>[];
  final renamed = <String>[];
  int deletions = 0;

  @override
  Future<String?> nicknameSource(final String uid) async => source;

  @override
  Future<void> publish({required final String uid, required final LeaderboardSnapshot snapshot}) async {
    published.add(snapshot.profile.nickname);
    source = snapshot.profile.nicknameSource;
  }

  @override
  Future<void> renameAll(final String uid, final String nickname) async => renamed.add(nickname);

  @override
  Future<void> deleteAll(final String uid) async {
    deletions++;
    source = null;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Publisher implements LeaderboardPublisher {
  int builds = 0;

  LeaderboardSnapshot _snapshot(final String? displayName, final int version) => LeaderboardSnapshot(
    profile: LeaderboardProfile(
      nickname: displayName ?? 'Swift Otter 47',
      nicknameSource: displayName == null ? LeaderboardProfile.sourceGenerated : LeaderboardProfile.sourceName,
      colorIndex: 0,
      streaks: const {},
    ),
    entries: {
      'd2026-11-02_hard': LeaderboardEntry(
        uid: 'me',
        nickname: displayName ?? 'Swift Otter 47',
        colorIndex: 0,
        score: version,
        secondary: 0,
        reachedAt: DateTime(2026, 11, 2),
      ),
    },
  );

  @override
  LeaderboardSnapshot emptySnapshot({required final String uid, required final String? displayName}) =>
      _snapshot(displayName, 0);

  @override
  Future<LeaderboardSnapshot> build({
    required final String uid,
    required final String? displayName,
    required final DateTime now,
  }) async => _snapshot(displayName, ++builds);

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements AuthService {
  @override
  bool get isAvailable => true;

  @override
  User? get currentUser => _User();

  @override
  String? get currentDisplayName => 'Peter O.';

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
  late PublicProfileService service;

  setUp(() {
    repository = _Repository();
    service = PublicProfileService(auth: _Auth(), leaderboards: repository, publisher: _Publisher());
  });

  test('turning on publishes even before the profile reaches the server', () async {
    service.setEnabled(true);
    repository.source = null;

    await service.publishNow();

    expect(repository.published, isNotEmpty);
  });

  test('consent withdrawn on another device stops publishing', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    expect(await service.isEnabled(), isTrue);

    repository.source = null;
    final before = repository.published.length;
    await service.publishNow();

    expect(repository.published.length, before);
    expect(await service.isEnabled(), isFalse);
  });

  test('changing the name setting renames past entries too', () async {
    repository.source = LeaderboardProfile.sourceName;
    await service.isEnabled();

    service.setShowName(false);
    await service.publishNow();

    expect(repository.renamed, ['Swift Otter 47']);
    expect(repository.source, LeaderboardProfile.sourceGenerated);
  });

  test('name setting from another device is picked up', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    await service.isEnabled();

    repository.source = LeaderboardProfile.sourceName;
    await service.publishNow();

    expect(service.showName, isTrue);
    expect(repository.renamed, isEmpty);
  });

  test('turning off deletes and does not publish', () async {
    repository.source = LeaderboardProfile.sourceGenerated;
    await service.isEnabled();

    service.setEnabled(false);
    final before = repository.published.length;
    await service.publishNow();

    expect(repository.deletions, 1);
    expect(repository.published.length, before);
  });
}
