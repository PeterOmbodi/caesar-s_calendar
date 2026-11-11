import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart';
import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart';
import 'package:caesar_puzzle/infrastructure/persistence/puzzle_history_repository_impl.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PuzzleHistoryRepositoryImpl repository;
  final date = DateTime(2026, 11, 11);
  final now = DateTime.now().millisecondsSinceEpoch;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PuzzleHistoryRepositoryImpl(PuzzleHistoryDao(db));
  });

  tearDown(() => db.close());

  Future<String> session({required final String configId, final int? completedAt}) => repository.createSession(
    PuzzleSessionData(
      id: '',
      puzzleDate: date,
      configId: configId,
      difficulty: PuzzleSessionDifficulty.hard,
      status: completedAt == null ? PuzzleSessionStatus.unsolved : PuzzleSessionStatus.solved,
      startedAt: now - 60000,
      firstMoveAt: now - 60000,
      lastResumedAt: null,
      activeElapsedMs: 1000,
      updatedAt: now,
      completedAt: completedAt,
      moveIndex: 0,
      moveHistoryVersion: 1,
      pieces: const [],
      moveHistory: const [],
    ),
  );

  Future<Map<String, bool>> cleanById() async => {
    for (final s in await repository.watchSessionsByDate(puzzleDate: date).first) s.id: s.isClean,
  };

  test('help marks sessions that end after it, not the ones solved before', () async {
    final before = await session(configId: 'standard', completedAt: now - 10000);
    final unfinished = await session(configId: 'standard');
    final after = await session(configId: 'standard', completedAt: now + 60000);
    final otherLayout = await session(configId: 'custom');

    await repository.markPuzzleAssisted(puzzleDate: date, configId: 'standard');

    expect(await cleanById(), {before: true, unfinished: false, after: false, otherLayout: true});
    expect(await repository.isPuzzleAssisted(puzzleDate: date, configId: 'standard'), isTrue);
    expect(await repository.isPuzzleAssisted(puzzleDate: date, configId: 'custom'), isFalse);
  });

  test('later help keeps the first time', () async {
    await repository.markPuzzleAssisted(puzzleDate: date, configId: 'standard');
    final first = (await db.select(db.puzzleAssists).getSingle()).assistedAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.markPuzzleAssisted(puzzleDate: date, configId: 'standard');

    expect((await db.select(db.puzzleAssists).getSingle()).assistedAt, first);
  });

  test('clearing local data drops the help marks', () async {
    await repository.markPuzzleAssisted(puzzleDate: date, configId: 'standard');
    await repository.clearLocalData();

    expect(await repository.isPuzzleAssisted(puzzleDate: date, configId: 'standard'), isFalse);
  });
}
