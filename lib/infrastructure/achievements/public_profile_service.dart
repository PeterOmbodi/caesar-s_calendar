import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PublicProfileService {
  PublicProfileService({
    required final AppDatabase db,
    required final FirebaseFirestore firestore,
    required final AuthService auth,
  }) : _db = db,
       _firestore = firestore,
       _auth = auth;

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final AuthService _auth;

  Future<bool> isEnabled() async {
    final uid = _auth.currentUser?.uid;
    if (!_auth.isAvailable || uid == null) {
      return false;
    }
    return (await _firestore.doc(FirestorePaths.publicUserDoc(uid)).get()).exists;
  }

  Future<void> setEnabled(final bool enabled) async {
    final uid = _auth.currentUser?.uid;
    if (!_auth.isAvailable || uid == null) return;

    if (!enabled) {
      await _firestore.doc(FirestorePaths.publicUserDoc(uid)).delete();
      return;
    }

    await publishNow();
  }

  Future<void> publishNow() async {
    if (!_auth.isAvailable) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (!await isEnabled()) return;

    final solvedSessions = await _countSolvedSessions();
    final solvedVariants = await _countSolvedVariants();

    final payload = <String, Object?>{
      'uid': uid,
      'solvedSessions': solvedSessions,
      'solvedVariants': solvedVariants,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    final displayName = _auth.currentDisplayName;
    final photoUrl = _auth.currentPhotoUrl;
    if (displayName != null && displayName.isNotEmpty) {
      payload['displayName'] = displayName;
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      payload['photoUrl'] = photoUrl;
    }
    await _firestore.doc(FirestorePaths.publicUserDoc(uid)).set(payload, SetOptions(merge: true));
  }

  Future<int> _countSolvedSessions() async {
    final countExpr = _db.puzzleSessions.id.count();
    final query = _db.selectOnly(_db.puzzleSessions)
      ..where(_db.puzzleSessions.completedAt.isNotNull())
      ..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<int> _countSolvedVariants() async {
    final countExpr = _db.puzzleSolvedSolutions.solutionSignature.count();
    final query = _db.selectOnly(_db.puzzleSolvedSolutions)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }
}

