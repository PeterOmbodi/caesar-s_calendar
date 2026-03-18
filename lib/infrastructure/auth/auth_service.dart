import 'dart:async';

import 'package:caesar_puzzle/infrastructure/auth/auth_failure.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firebase_bootstrap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

@lazySingleton
class AuthService {
  AuthService({
    required final FirebaseAuth firebaseAuth,
    required final FirebaseFirestore firestore,
    required final GoogleSignIn googleSignIn,
  }) : _auth = firebaseAuth,
       _firestore = firestore,
       _google = googleSignIn;

  static const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _google;

  bool get isAvailable => FirebaseBootstrap.result?.enabled ?? false;

  Stream<User?> authStateChanges() {
    if (!isAvailable) return const Stream<User?>.empty();
    return _auth.authStateChanges();
  }

  Stream<User?> userChanges() {
    if (!isAvailable) return const Stream<User?>.empty();
    return _auth.userChanges();
  }

  User? get currentUser => isAvailable ? _auth.currentUser : null;
  String? get currentDisplayName => _bestDisplayName(_auth.currentUser);
  String? get currentPhotoUrl => _bestPhotoUrl(_auth.currentUser);

  Future<User?> ensureSignedIn() async {
    if (!isAvailable) return null;
    if (_auth.currentUser != null) return _auth.currentUser;
    final credential = await _auth.signInAnonymously();
    await _ensureUserDoc();
    return credential.user ?? _auth.currentUser;
  }

  Future<Either<AuthFailure, UserCredential>> signInWithGoogle({required final bool linkIfAnonymous}) async {
    if (!isAvailable) return Left(const AuthUnavailableFailure());
    if (kIsWeb) {
      return _signInWithGoogleOnWeb(linkIfAnonymous: linkIfAnonymous);
    }
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return Left(const AuthUnavailableFailure('Google sign-in is not supported on this platform'));
    }
    try {
      await _google.initialize(
        clientId: _googleWebClientId.isNotEmpty ? _googleWebClientId : null,
      );
      if (!_google.supportsAuthenticate()) {
        return Left(const AuthUnavailableFailure('Google sign-in is not supported on this platform'));
      }
      final account = await _google.authenticate(scopeHint: const ['email']);
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final current = _auth.currentUser;
      if (linkIfAnonymous && current != null && current.isAnonymous) {
        try {
          final result = await current.linkWithCredential(credential);
          await _ensureUserDoc();
          return Right(result);
        } on FirebaseAuthException catch (e) {
          final failure = _mapLinkConflict(e, AuthProviderKind.google);
          if (failure != null) {
            return Left(failure);
          }
          rethrow;
        }
      }
      final result = await _auth.signInWithCredential(credential);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, UserCredential>> _signInWithGoogleOnWeb({required final bool linkIfAnonymous}) async {
    try {
      final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
      final current = _auth.currentUser;
      if (linkIfAnonymous && current != null && current.isAnonymous) {
        try {
          final result = await current.linkWithPopup(provider);
          await _ensureUserDoc();
          return Right(result);
        } on FirebaseAuthException catch (e) {
          final failure = _mapLinkConflict(e, AuthProviderKind.google);
          if (failure != null) {
            return Left(failure);
          }
          rethrow;
        }
      }
      final result = await _auth.signInWithPopup(provider);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, UserCredential>> signInWithApple({required final bool linkIfAnonymous}) async {
    if (!isAvailable) return Left(const AuthUnavailableFailure());
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final current = _auth.currentUser;
      if (linkIfAnonymous && current != null && current.isAnonymous) {
        try {
          final result = await current.linkWithCredential(oauthCredential);
          await _ensureUserDoc();
          return Right(result);
        } on FirebaseAuthException catch (e) {
          final failure = _mapLinkConflict(e, AuthProviderKind.apple);
          if (failure != null) {
            return Left(failure);
          }
          rethrow;
        }
      }
      final result = await _auth.signInWithCredential(oauthCredential);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return Left(const AuthCanceledFailure());
      }
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, UserCredential>> switchToExistingProviderAccount({
    required final AuthProviderKind providerKind,
    final AuthCredential? credential,
  }) {
    if (credential != null) {
      return _signInWithExistingCredential(credential);
    }
    switch (providerKind) {
      case AuthProviderKind.google:
        return _switchToExistingGoogleAccount();
      case AuthProviderKind.apple:
        return _switchToExistingAppleAccount();
    }
  }

  Future<Either<AuthFailure, UserCredential>> _signInWithExistingCredential(final AuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Provider sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
    } catch (e) {
      debugPrint('Provider sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, UserCredential>> _switchToExistingGoogleAccount() async {
    if (kIsWeb) {
      return _signInWithGoogleOnWeb(linkIfAnonymous: false);
    }
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return Left(const AuthUnavailableFailure('Google sign-in is not supported on this platform'));
    }
    try {
      await _google.initialize(
        clientId: _googleWebClientId.isNotEmpty ? _googleWebClientId : null,
      );
      if (!_google.supportsAuthenticate()) {
        return Left(const AuthUnavailableFailure('Google sign-in is not supported on this platform'));
      }
      final account = await _google.authenticate(scopeHint: const ['email']);
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      final result = await _auth.signInWithCredential(credential);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, UserCredential>> _switchToExistingAppleAccount() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final result = await _auth.signInWithCredential(oauthCredential);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return Left(const AuthCanceledFailure());
      }
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.toString()));
    }
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await _auth.signOut();
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }
    try {
      await _google.signOut();
    } catch (_) {
      // Firebase auth state is already cleared; provider sign-out should not block local logout.
    }
  }

  Future<void> _ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final now = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'createdAt': now,
        'updatedAt': now,
        'isAnonymous': user.isAnonymous,
      },
      SetOptions(merge: true),
    );
  }

  AuthFailure? _mapLinkConflict(final FirebaseAuthException error, final AuthProviderKind providerKind) {
    switch (error.code) {
      case 'credential-already-in-use':
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return AuthAccountSwitchRequiredFailure(providerKind, credential: error.credential);
      default:
        return null;
    }
  }

  String? _bestDisplayName(final User? user) {
    final direct = user?.displayName?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final profile in user?.providerData ?? const <UserInfo>[]) {
      final candidate = profile.displayName?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  String? _bestPhotoUrl(final User? user) {
    final direct = user?.photoURL?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final profile in user?.providerData ?? const <UserInfo>[]) {
      final candidate = profile.photoURL?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }
}

// Minimal Either to avoid extra dependency.
sealed class Either<L, R> {
  const Either();
  T fold<T>(final T Function(L) left, final T Function(R) right);
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
  @override
  T fold<T>(final T Function(L) left, final T Function(R) right) => left(value);
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
  @override
  T fold<T>(final T Function(L) left, final T Function(R) right) => right(value);
}

