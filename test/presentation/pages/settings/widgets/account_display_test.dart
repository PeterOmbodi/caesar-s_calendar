import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initials are the first letters of the first two words', () {
    expect(AccountDisplay.avatarInitials('Swift Otter 47'), 'SO');
    expect(AccountDisplay.avatarInitials('peter  ombodi'), 'PO');
    expect(AccountDisplay.avatarInitials('Peter'), 'P');
    expect(AccountDisplay.avatarInitials('  '), '?');
  });
}
