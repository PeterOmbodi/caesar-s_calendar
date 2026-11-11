import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/infrastructure/auth/auth_service.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

abstract final class DebugTools {
  /// Leaderboard entries already published stay as they are.
  static Future<void> resetTodayHelp() async {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    const configId = StandardPuzzleConfig.id;
    final db = getIt<AppDatabase>();
    await (db.delete(
      db.puzzleAssists,
    )..where((final row) => row.puzzleDate.equals(date) & row.configId.equals(configId))).go();
    final uid = getIt<AuthService>().currentUser?.uid;
    if (uid == null) return;
    await getIt<FirebaseFirestore>().doc('${FirestorePaths.userAssists(uid)}/${date}__$configId').delete();
  }
}
