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

final class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure([super.message = 'Unknown auth error']);
}

final class AuthAccountSwitchRequiredFailure extends AuthFailure {
  AuthAccountSwitchRequiredFailure(this.providerKind, {this.credential})
    : super('This ${providerKind.label} account is already linked to another profile.');

  final AuthProviderKind providerKind;
  final AuthCredential? credential;
}

