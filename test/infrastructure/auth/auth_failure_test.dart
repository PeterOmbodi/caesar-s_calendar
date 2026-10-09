import 'dart:async';

import 'package:caesar_puzzle/infrastructure/auth/auth_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authFailureFromWebPopupError', () {
    test('explains that pop-ups may need to be allowed when the browser blocks the sign-in window', () {
      final failure = authFailureFromWebPopupError(FirebaseAuthException(code: 'popup-blocked'));

      expect(failure, isA<AuthPopupFailure>());
      expect(failure.message, contains('Allow pop-ups'));
      expect(failure.message, contains('browser settings'));
      expect(failure.message, isNot(contains('Safari')));
    });

    test('uses the same guidance when the popup closes before sign-in completes', () {
      final failure = authFailureFromWebPopupError(FirebaseAuthException(code: 'popup-closed-by-user'));

      expect(failure, isA<AuthPopupFailure>());
      expect(failure.message, contains('Allow pop-ups'));
    });

    test('uses the same guidance when waiting for the popup times out', () {
      final failure = authFailureFromWebPopupError(TimeoutException('Timed out waiting for sign-in popup'));

      expect(failure, isA<AuthPopupFailure>());
      expect(failure.message, contains('Allow pop-ups'));
    });

    test('keeps unknown Firebase errors unchanged', () {
      final failure = authFailureFromWebPopupError(
        FirebaseAuthException(code: 'network-request-failed', message: 'Network error'),
      );

      expect(failure, isA<AuthUnknownFailure>());
      expect(failure.message, 'Network error');
    });
  });
}
