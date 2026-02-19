import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openDatabaseConnectionImpl() => LazyDatabase(() async {
  final result = await WasmDatabase.open(
    databaseName: 'puzzle_history_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor.executor;
});
