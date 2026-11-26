import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initials are the first letters of the first two words', () {
    expect(AccountDisplay.avatarInitials('Swift Otter 47'), 'SO');
    expect(AccountDisplay.avatarInitials('peter  ombodi'), 'PO');
    expect(AccountDisplay.avatarInitials('Peter'), 'P');
    expect(AccountDisplay.avatarInitials('  '), '?');
  });

  test('the account name wins over the nickname', () {
    expect(AccountDisplay.nameOrNickname(const _User(uid: 'u1', displayName: 'Peter Ombodi')), 'Peter Ombodi');
  });

  test('without a name the player is shown by the nickname from rankings', () {
    expect(AccountDisplay.nameOrNickname(const _User(uid: 'u1')), NicknameGenerator.fromUid('u1'));
    expect(AccountDisplay.nameOrNickname(const _User(uid: 'u1', displayName: '  ')), NicknameGenerator.fromUid('u1'));
  });

  test('no user, no name', () {
    expect(AccountDisplay.nameOrNickname(null), isNull);
  });
}

class _User {
  const _User({required this.uid, this.displayName});

  final String uid;
  final String? displayName;
  List<Object> get providerData => const [];
}
