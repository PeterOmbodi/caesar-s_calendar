import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DriftModule {
  @lazySingleton
  AppDatabase get database => AppDatabase();

  @lazySingleton
  PuzzleHistoryDao puzzleHistoryDao(final AppDatabase db) => PuzzleHistoryDao(db);
}
