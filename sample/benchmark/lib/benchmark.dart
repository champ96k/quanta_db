import 'dart:async';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:quanta_db/quanta_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

abstract class Database {
  Future<void> init();
  Future<void> put(String key, dynamic value);
  Future<void> putAll(Map<String, dynamic> entries);
  Future<dynamic> get(String key);
  Future<void> delete(String key);
  Future<void> close();
}

class QuantaDBWrapper implements Database {
  final QuantaDB _db;
  QuantaDBWrapper(this._db);

  @override
  Future<void> init() async => await _db.init();

  @override
  Future<void> put(String key, dynamic value) async =>
      await _db.put(key, value);

  @override
  Future<void> putAll(Map<String, dynamic> entries) async =>
      await _db.storage.putAll(entries);

  @override
  Future<dynamic> get(String key) async => await _db.get(key);

  @override
  Future<void> delete(String key) async => await _db.delete(key);

  @override
  Future<void> close() async => await _db.close();
}

class HiveDBWrapper implements Database {
  late Box _box;
  final String _name;

  HiveDBWrapper(this._name);

  @override
  Future<void> init() async {
    final dir = Directory.current;
    Hive.init(dir.path);
    _box = await Hive.openBox(_name);
  }

  @override
  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) async {
    for (var entry in entries.entries) {
      await _box.put(entry.key, entry.value);
    }
  }

  @override
  Future<dynamic> get(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> close() async {
    await _box.close();
  }
}

class SQLiteDBWrapper implements Database {
  late sqflite_ffi.Database _db;
  final String _name;

  SQLiteDBWrapper(this._name);

  @override
  Future<void> init() async {
    sqflite_ffi.sqfliteFfiInit();
    sqflite_ffi.databaseFactory = sqflite_ffi.databaseFactoryFfi;
    final dbPath = await sqflite_ffi.getDatabasesPath();
    final dbFilePath = path.join(dbPath, '$_name.db');
    _db = await sqflite_ffi.databaseFactory.openDatabase(
      dbFilePath,
      options: sqflite_ffi.OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS kv_store (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        },
      ),
    );
  }

  @override
  Future<void> put(String key, dynamic value) async {
    await _db.insert(
      'kv_store',
      {'key': key, 'value': value.toString()},
      conflictAlgorithm: sqflite_ffi.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) async {
    for (var entry in entries.entries) {
      await _db.insert(
        'kv_store',
        {'key': entry.key, 'value': entry.value.toString()},
        conflictAlgorithm: sqflite_ffi.ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<dynamic> get(String key) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'kv_store',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'];
  }

  @override
  Future<void> delete(String key) async {
    await _db.delete(
      'kv_store',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> close() async {
    await _db.close();
  }
}

class BenchmarkResult {
  final String operation;
  final String database;
  final int operations;
  final Duration totalTime;
  final Duration averageTime;

  BenchmarkResult({
    required this.operation,
    required this.database,
    required this.operations,
    required this.totalTime,
    required this.averageTime,
  });

  @override
  String toString() {
    return '$database - $operation:\n'
        '  Total Operations: $operations\n'
        '  Total Time: ${totalTime.inMilliseconds}ms\n'
        '  Average Time: ${averageTime.inMicroseconds}µs\n';
  }
}

Future<BenchmarkResult> runBatchWriteBenchmark(
    Database db, String dbName, int operations) async {
  final stopwatch = Stopwatch()..start();

  // Create a batch of entries
  final entries = <String, dynamic>{};
  for (int i = 0; i < operations; i++) {
    entries['key_$i'] = 'value_$i';
  }

  // Perform batch write
  await db.putAll(entries);

  stopwatch.stop();
  return BenchmarkResult(
    operation: 'Batch Write',
    database: dbName,
    operations: operations,
    totalTime: stopwatch.elapsed,
    averageTime:
        Duration(milliseconds: stopwatch.elapsedMilliseconds ~/ operations),
  );
}
