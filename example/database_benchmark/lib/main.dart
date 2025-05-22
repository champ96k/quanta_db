import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:quanta_db/quanta_db.dart';
import 'package:sqflite/sqflite.dart';

import 'models/benchmark_item.dart';

enum BenchmarkType { init, write, read, filterSort, update, dbSize, total }

const int operations = 50000;

class BenchmarkResult {
  final String dbName;
  final Map<BenchmarkType, double> times; // ms or size in KB
  BenchmarkResult(this.dbName, this.times);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Benchmark',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BenchmarkDashboard(),
    );
  }
}

class BenchmarkDashboard extends StatefulWidget {
  const BenchmarkDashboard({super.key});

  @override
  State<BenchmarkDashboard> createState() => _BenchmarkDashboardState();
}

class _BenchmarkDashboardState extends State<BenchmarkDashboard> {
  bool _isRunning = false;
  List<BenchmarkResult> _results = [];
  int _currentStep =
      0; // 0: none, 1: QuantaDB, 2: Hive, 3: SQFlite, 4: Isar, 5: ObjectBox

  Future<void> _runBenchmarks() async {
    setState(() {
      _isRunning = true;
      _currentStep = 1;
    });
    final List<BenchmarkResult> results = [];
    final items = List.generate(
      operations,
      (i) => BenchmarkItem(name: 'Item $i', value: i),
    );

    // --- QUANTA_DB ---
    final quantaTimes = await _benchmarkQuantaDb(items);
    results.add(BenchmarkResult('quanta_db', quantaTimes));
    setState(() {
      _currentStep = 2;
      _results = List.from(results);
    });
    await Future.delayed(const Duration(milliseconds: 100));

    // --- HIVE ---
    final hiveTimes = await _benchmarkHive(items);
    results.add(BenchmarkResult('Hive', hiveTimes));
    setState(() {
      _currentStep = 3;
      _results = List.from(results);
    });
    await Future.delayed(const Duration(milliseconds: 100));

    // --- SQFLITE ---
    final sqfliteTimes = await _benchmarkSqflite(items);
    results.add(BenchmarkResult('SQFlite', sqfliteTimes));
    setState(() {
      _currentStep = 4;
      _results = List.from(results);
    });
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _currentStep = 0;
      _results = List.from(results);
      _isRunning = false;
    });
  }

  Future<Map<BenchmarkType, double>> _benchmarkQuantaDb(
      List<BenchmarkItem> items) async {
    final totalStopwatch = Stopwatch()..start();
    final results = <BenchmarkType, double>{};

    // Init
    final initStopwatch = Stopwatch()..start();
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dir.path, 'quanta_benchmark');
    final db = await QuantaDB.open(dbPath);
    await db.init();
    initStopwatch.stop();
    results[BenchmarkType.init] = initStopwatch.elapsedMilliseconds.toDouble();

    // Write
    final writeStopwatch = Stopwatch()..start();
    for (final item in items) {
      await db.put(item.id, item.toMap());
    }
    writeStopwatch.stop();
    results[BenchmarkType.write] =
        writeStopwatch.elapsedMilliseconds.toDouble();

    // Read
    final readStopwatch = Stopwatch()..start();
    for (final item in items) {
      await db.get(item.id);
    }
    readStopwatch.stop();
    results[BenchmarkType.read] = readStopwatch.elapsedMilliseconds.toDouble();

    // Filter & Sort
    final filterStopwatch = Stopwatch()..start();
    final allItems = await Future.wait(items.map((item) => db.get(item.id)));
    allItems
        .where((item) => item != null)
        .toList()
        .sort((a, b) => a.toString().compareTo(b.toString()));
    filterStopwatch.stop();
    results[BenchmarkType.filterSort] =
        filterStopwatch.elapsedMilliseconds.toDouble();

    // Update
    final updateStopwatch = Stopwatch()..start();
    for (final item in items) {
      await db.put(item.id, item.toMap());
    }
    updateStopwatch.stop();
    results[BenchmarkType.update] =
        updateStopwatch.elapsedMilliseconds.toDouble();

    // DB Size
    final dbFile = File(path.join(dbPath, 'data.db'));
    results[BenchmarkType.dbSize] =
        dbFile.existsSync() ? dbFile.lengthSync() / 1024 : 0;

    await db.close();
    totalStopwatch.stop();
    results[BenchmarkType.total] =
        totalStopwatch.elapsedMilliseconds.toDouble();
    return results;
  }

  Future<Map<BenchmarkType, double>> _benchmarkHive(
      List<BenchmarkItem> items) async {
    final totalStopwatch = Stopwatch()..start();
    final results = <BenchmarkType, double>{};

    // Init
    final initStopwatch = Stopwatch()..start();
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    final box = await Hive.openBox('hive_benchmark');
    initStopwatch.stop();
    results[BenchmarkType.init] = initStopwatch.elapsedMilliseconds.toDouble();

    // Write
    final writeStopwatch = Stopwatch()..start();
    for (final item in items) {
      await box.put(item.id, item.toMap());
    }
    writeStopwatch.stop();
    results[BenchmarkType.write] =
        writeStopwatch.elapsedMilliseconds.toDouble();

    // Read
    final readStopwatch = Stopwatch()..start();
    for (final item in items) {
      await box.get(item.id);
    }
    readStopwatch.stop();
    results[BenchmarkType.read] = readStopwatch.elapsedMilliseconds.toDouble();

    // Filter & Sort
    final filterStopwatch = Stopwatch()..start();
    final allItems = box.values.toList();
    allItems.sort((a, b) => a.toString().compareTo(b.toString()));
    filterStopwatch.stop();
    results[BenchmarkType.filterSort] =
        filterStopwatch.elapsedMilliseconds.toDouble();

    // Update
    final updateStopwatch = Stopwatch()..start();
    for (final item in items) {
      await box.put(item.id, item.toMap());
    }
    updateStopwatch.stop();
    results[BenchmarkType.update] =
        updateStopwatch.elapsedMilliseconds.toDouble();

    // DB Size
    final dbFile = File(path.join(dir.path, 'hive_benchmark.hive'));
    results[BenchmarkType.dbSize] =
        dbFile.existsSync() ? dbFile.lengthSync() / 1024 : 0;

    await box.close();
    totalStopwatch.stop();
    results[BenchmarkType.total] =
        totalStopwatch.elapsedMilliseconds.toDouble();
    return results;
  }

  Future<Map<BenchmarkType, double>> _benchmarkSqflite(
      List<BenchmarkItem> items) async {
    final totalStopwatch = Stopwatch()..start();
    final results = <BenchmarkType, double>{};

    // Init
    final initStopwatch = Stopwatch()..start();
    final db = await openDatabase('sqflite_benchmark.db');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        name TEXT,
        value INTEGER,
        createdAt TEXT
      )
    ''');
    initStopwatch.stop();
    results[BenchmarkType.init] = initStopwatch.elapsedMilliseconds.toDouble();

    // Write
    final writeStopwatch = Stopwatch()..start();
    for (final item in items) {
      await db.insert('items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    writeStopwatch.stop();
    results[BenchmarkType.write] =
        writeStopwatch.elapsedMilliseconds.toDouble();

    // Read
    final readStopwatch = Stopwatch()..start();
    for (final item in items) {
      await db.query('items', where: 'id = ?', whereArgs: [item.id]);
    }
    readStopwatch.stop();
    results[BenchmarkType.read] = readStopwatch.elapsedMilliseconds.toDouble();

    // Filter & Sort
    final filterStopwatch = Stopwatch()..start();
    await db.query('items', orderBy: 'name');
    filterStopwatch.stop();
    results[BenchmarkType.filterSort] =
        filterStopwatch.elapsedMilliseconds.toDouble();

    // Update
    final updateStopwatch = Stopwatch()..start();
    for (final item in items) {
      await db
          .update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    }
    updateStopwatch.stop();
    results[BenchmarkType.update] =
        updateStopwatch.elapsedMilliseconds.toDouble();

    // DB Size
    final dbFile = File('sqflite_benchmark.db');
    results[BenchmarkType.dbSize] =
        dbFile.existsSync() ? dbFile.lengthSync() / 1024 : 0;

    await db.close();
    totalStopwatch.stop();
    results[BenchmarkType.total] =
        totalStopwatch.elapsedMilliseconds.toDouble();
    return results;
  }

  @override
  Widget build(BuildContext context) {
    const types = BenchmarkType.values;
    final dbColors = {
      'quanta_db': Colors.blue,
      'Hive': Colors.green,
      'SQFlite': Colors.orange,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Benchmark'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Database Performance Benchmark',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comparing $operations operations across different databases',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isRunning ? null : _runBenchmarks,
                      icon: _isRunning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isRunning ? 'Running...' : 'Run Benchmark'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    if (_isRunning)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          _currentStep == 1
                              ? 'Benchmarking QuantaDB...'
                              : _currentStep == 2
                                  ? 'Benchmarking Hive...'
                                  : _currentStep == 3
                                      ? 'Benchmarking SQFlite...'
                                      : 'Benchmarking ObjectBox...',
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_results.isNotEmpty)
              Expanded(
                child: ListView(
                  children: types.map((type) {
                    final maxValue = _results
                        .map((r) => r.times[type] ?? 0)
                        .reduce((a, b) => a > b ? a : b);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Card(
                        color: const Color(0xFF232B36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTypeTitle(type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '$operations Objects',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(_results.length, (i) {
                                  final db = _results[i];
                                  final value = db.times[type] ?? 0;
                                  final color = dbColors[db.dbName] ??
                                      Colors.primaries[
                                          i % Colors.primaries.length];
                                  final barHeight = maxValue > 0
                                      ? (value / maxValue) * 120
                                      : 0;
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        value > 0
                                            ? '${value.toInt()}${type == BenchmarkType.dbSize ? 'KB' : 'ms'}'
                                            : '-',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 32,
                                        height: barHeight.toDouble(),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        db.dbName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTypeTitle(BenchmarkType type) {
    switch (type) {
      case BenchmarkType.write:
        return 'Insert';
      case BenchmarkType.read:
        return 'Read';
      case BenchmarkType.filterSort:
        return 'Filter & Sort Query';
      case BenchmarkType.update:
        return 'Update';
      case BenchmarkType.dbSize:
        return 'DB Size';
      case BenchmarkType.init:
        return 'Init';
      case BenchmarkType.total:
        return 'Total';
      default:
        return '';
    }
  }
}
