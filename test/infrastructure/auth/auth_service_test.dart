import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses redirect sign-in for web running in iOS browser', () {
    expect(AuthService.shouldUseRedirectSignIn(isWeb: true, targetPlatform: TargetPlatform.iOS), isTrue);
  });

  test('keeps popup sign-in for desktop web browsers', () {
    expect(AuthService.shouldUseRedirectSignIn(isWeb: true, targetPlatform: TargetPlatform.macOS), isFalse);
  });

  test('keeps native provider sign-in outside web', () {
    expect(AuthService.shouldUseRedirectSignIn(isWeb: false, targetPlatform: TargetPlatform.iOS), isFalse);
  });
}
