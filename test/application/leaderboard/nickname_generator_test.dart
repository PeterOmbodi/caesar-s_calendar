import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('from the account name', () {
    test('first name and last initial', () {
      expect(NicknameGenerator.nickname(uid: 'u', displayName: 'Peter Ombodi'), 'Peter O.');
      expect(NicknameGenerator.nickname(uid: 'u', displayName: '  Anna  Maria   smith '), 'Anna S.');
    });

    test('single word stays as is', () {
      expect(NicknameGenerator.nickname(uid: 'u', displayName: 'Peter'), 'Peter');
    });

    test('non-Latin names', () {
      expect(NicknameGenerator.nickname(uid: 'u', displayName: 'Петро омбоді'), 'Петро О.');
      expect(NicknameGenerator.nickname(uid: 'u', displayName: '山田 太郎'), '山田 太.');
    });

    test('long first name is cut to fit', () {
      final nickname = NicknameGenerator.nickname(uid: 'u', displayName: '${'A' * 40} Brown');
      expect(nickname.length, NicknameGenerator.maxLength);
      expect(nickname, endsWith(' B.'));
    });

    test('email or empty name falls back to the uid', () {
      final fromUid = NicknameGenerator.nickname(uid: 'abc');
      expect(NicknameGenerator.nickname(uid: 'abc', displayName: 'peter@example.com'), fromUid);
      expect(NicknameGenerator.nickname(uid: 'abc', displayName: '   '), fromUid);
    });
  });

  group('from the uid', () {
    test('stable and in the expected shape', () {
      final nickname = NicknameGenerator.nickname(uid: 'Kx9dQ2mZ7rT1');
      expect(NicknameGenerator.nickname(uid: 'Kx9dQ2mZ7rT1'), nickname);
      expect(nickname, matches(RegExp(r'^[A-Z][a-z]+ [A-Z][a-z]+ [1-9]\d$')));
    });

    test('fits the limit and varies between users', () {
      final nicknames = {for (var i = 0; i < 200; i++) NicknameGenerator.nickname(uid: 'user$i')};
      expect(nicknames.every((final n) => n.length <= NicknameGenerator.maxLength), isTrue);
      expect(nicknames.length, greaterThan(190));
    });
  });

  test('color index is stable and in range', () {
    final indexes = [for (var i = 0; i < 100; i++) NicknameGenerator.colorIndex('user$i')];
    expect(indexes.every((final i) => i >= 0 && i < NicknameGenerator.colorCount), isTrue);
    expect(indexes.toSet().length, NicknameGenerator.colorCount);
    expect(NicknameGenerator.colorIndex('abc'), NicknameGenerator.colorIndex('abc'));
  });
}
