import 'package:benchmark/benchmark.dart';
import 'package:quanta_db/quanta_db.dart';

Future<void> main() async {
  const operations = 10000; // Number of operations to perform

  // QuantaDB
  final quanta = QuantaDBWrapper(await QuantaDB.open('benchmark_quanta'));
  await quanta.init();
  final quantaWrite = await _benchmarkWrite(quanta, operations, 'QuantaDB');
  final quantaRead = await _benchmarkRead(quanta, operations, 'QuantaDB');
  await quanta.close();

  // Hive
  final hive = HiveDBWrapper('benchmark_hive');
  await hive.init();
  final hiveWrite = await _benchmarkWrite(hive, operations, 'Hive');
  final hiveRead = await _benchmarkRead(hive, operations, 'Hive');
  await hive.close();

  // SQLite
  final sqlite = SQLiteDBWrapper('benchmark_sqlite');
  await sqlite.init();
  final sqliteWrite = await _benchmarkWrite(sqlite, operations, 'SQLite');
  final sqliteRead = await _benchmarkRead(sqlite, operations, 'SQLite');
  await sqlite.close();

  print('Benchmark Results:\n');
  print(quantaWrite);
  print(quantaRead);
  print(hiveWrite);
  print(hiveRead);
  print(sqliteWrite);
  print(sqliteRead);
}

Future<BenchmarkResult> _benchmarkWrite(
    Database db, int operations, String dbName) async {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < operations; i++) {
    await db.put('key_$i', 'value_$i');
  }
  stopwatch.stop();
  return BenchmarkResult(
    operation: 'Write',
    database: dbName,
    operations: operations,
    totalTime: stopwatch.elapsed,
    averageTime:
        Duration(milliseconds: stopwatch.elapsedMilliseconds ~/ operations),
  );
}

Future<BenchmarkResult> _benchmarkRead(
    Database db, int operations, String dbName) async {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < operations; i++) {
    await db.get('key_$i');
  }
  stopwatch.stop();
  return BenchmarkResult(
    operation: 'Read',
    database: dbName,
    operations: operations,
    totalTime: stopwatch.elapsed,
    averageTime:
        Duration(milliseconds: stopwatch.elapsedMilliseconds ~/ operations),
  );
}
