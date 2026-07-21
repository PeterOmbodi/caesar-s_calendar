import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthFailure {
  const AuthFailure(this.message);

  final String message;
}

enum AuthProviderKind {
  google('Google'),
  apple('Apple');

  const AuthProviderKind(this.label);

  final String label;
}

final class AuthUnavailableFailure extends AuthFailure {
  const AuthUnavailableFailure([super.message = 'Auth is not available']);
}

final class AuthCanceledFailure extends AuthFailure {
  const AuthCanceledFailure([super.message = 'Sign-in canceled']);
}

final class AuthPopupFailure extends AuthFailure {
  const AuthPopupFailure()
    : super(
        'Sign-in popup could not be completed. Allow pop-ups for this site in your browser settings and try again.',
      );
}

final class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure([super.message = 'Unknown auth error']);
}

final class AuthAccountSwitchRequiredFailure extends AuthFailure {
  AuthAccountSwitchRequiredFailure(this.providerKind, {this.credential})
    : super('This ${providerKind.label} account is already linked to another profile.');

  final AuthProviderKind providerKind;
  final AuthCredential? credential;
}

AuthFailure authFailureFromWebPopupError(final Object error) {
  if (error is FirebaseAuthException) {
    if (_isWebPopupFailureCode(error.code) || _looksLikeWebPopupFailure(error.message)) {
      return const AuthPopupFailure();
    }
    return AuthUnknownFailure(error.message ?? error.code);
  }
  if (error is TimeoutException || _looksLikeWebPopupFailure(error.toString())) {
    return const AuthPopupFailure();
  }
  return AuthUnknownFailure(error.toString());
}

bool _isWebPopupFailureCode(final String code) => switch (code) {
  'popup-blocked' || 'auth/popup-blocked' => true,
  'popup-closed-by-user' || 'auth/popup-closed-by-user' => true,
  'cancelled-popup-request' || 'auth/cancelled-popup-request' => true,
  'web-context-cancelled' || 'auth/web-context-cancelled' => true,
  _ => false,
};

bool _looksLikeWebPopupFailure(final String? message) {
  if (message == null) return false;
  final normalized = message.toLowerCase();
  return normalized.contains('popup') &&
      (normalized.contains('blocked') ||
          normalized.contains('closed') ||
          normalized.contains('cancelled') ||
          normalized.contains('canceled') ||
          normalized.contains('timeout') ||
          normalized.contains('timed out'));
}
