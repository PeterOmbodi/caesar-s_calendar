import 'dart:async';

import 'package:caesar_puzzle/infrastructure/auth/auth_failure.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firebase_bootstrap.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
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

  Future<Either<AuthFailure, UserCredential>> signInWithGoogle() async {
    if (!isAvailable) return Left(const AuthUnavailableFailure());
    if (kIsWeb) {
      return _signInWithGoogleOnWeb();
    }
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return Left(const AuthUnavailableFailure('Google sign-in is not supported on this platform'));
    }
    try {
      await _google.initialize(clientId: _googleWebClientId.isNotEmpty ? _googleWebClientId : null);
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

  Future<Either<AuthFailure, UserCredential>> _signInWithGoogleOnWeb() async {
    try {
      final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
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

  Future<Either<AuthFailure, UserCredential>> signInWithApple() async {
    if (!isAvailable) return Left(const AuthUnavailableFailure());
    if (kIsWeb) {
      return _signInWithAppleOnWeb();
    }
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return Left(const AuthUnavailableFailure('Apple sign-in is not supported on this platform'));
    }
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, accessToken: appleCredential.authorizationCode);
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

  Future<Either<AuthFailure, UserCredential>> _signInWithAppleOnWeb() async {
    try {
      final provider = AppleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      await _ensureUserDoc();
      return Right(result);
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign-in failed: $e');
      return Left(AuthUnknownFailure(e.message ?? e.code));
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

  Future<void> deleteCurrentAccount() async {
    if (!isAvailable) {
      throw const AuthUnavailableFailure();
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthUnavailableFailure('No signed-in user to delete');
    }

    final providerKind = _providerKindForUser(user);
    if (providerKind != null && !user.isAnonymous) {
      await _reauthenticate(user, providerKind);
    }

    final uid = user.uid;
    await user.delete();
    try {
      await _deleteCloudData(uid);
    } catch (e) {
      debugPrint('Cloud cleanup after account deletion failed: $e');
    }
    await _signOutProviderSessions();
  }

  Future<void> _ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final now = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'createdAt': now,
      'updatedAt': now,
      'isAnonymous': user.isAnonymous,
    }, SetOptions(merge: true));
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

  AuthProviderKind? _providerKindForUser(final User user) {
    for (final profile in user.providerData) {
      switch (profile.providerId) {
        case 'apple.com':
          return AuthProviderKind.apple;
        case 'google.com':
          return AuthProviderKind.google;
      }
    }
    return null;
  }

  Future<void> _reauthenticate(final User user, final AuthProviderKind providerKind) async {
    if (kIsWeb) {
      await _reauthenticateOnWeb(user, providerKind);
      return;
    }
    final credential = switch (providerKind) {
      AuthProviderKind.google => await _reauthenticateWithGoogle(),
      AuthProviderKind.apple => await _reauthenticateWithApple(),
    };
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _reauthenticateOnWeb(final User user, final AuthProviderKind providerKind) async {
    final provider = switch (providerKind) {
      AuthProviderKind.google => GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      AuthProviderKind.apple => AppleAuthProvider(),
    };
    await user.reauthenticateWithPopup(provider);
  }

  Future<AuthCredential> _reauthenticateWithGoogle() async {
    await _google.initialize(clientId: _googleWebClientId.isNotEmpty ? _googleWebClientId : null);
    if (!_google.supportsAuthenticate()) {
      throw const AuthUnavailableFailure('Google re-authentication is not supported on this platform');
    }

    final account = await _google.authenticate(scopeHint: const ['email']);
    final auth = account.authentication;
    return GoogleAuthProvider.credential(idToken: auth.idToken);
  }

  Future<AuthCredential> _reauthenticateWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    return OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, accessToken: appleCredential.authorizationCode);
  }

  Future<void> _deleteCloudData(final String uid) async {
    await _deleteCollection(FirestorePaths.userSessions(uid));
    await _deleteCollection(FirestorePaths.userConfigs(uid));
    await _deleteCollection(FirestorePaths.userSolvedSolutions(uid));
    await _deleteCollection('${FirestorePaths.userDoc(uid)}/solutionCounts');
    await _firestore.doc(FirestorePaths.publicUserDoc(uid)).delete().catchError((_) {});
    await _firestore.doc(FirestorePaths.userDoc(uid)).delete().catchError((_) {});
  }

  Future<void> _deleteCollection(final String path) async {
    while (true) {
      final snapshot = await _firestore.collection(path).limit(200).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _signOutProviderSessions() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }
    try {
      await _google.signOut();
    } catch (_) {
      // Provider session cleanup should not hide account deletion success.
    }
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
