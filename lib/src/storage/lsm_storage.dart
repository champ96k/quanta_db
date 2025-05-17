import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'memtable.dart';
import 'sstable.dart';

/// Configuration for the LSM storage engine
class LSMConfig {
  const LSMConfig({
    required this.dataDir,
    this.maxMemTableSize = 64 * 1024 * 1024, // 64MB
    this.maxLevelSize = 256 * 1024 * 1024, // 256MB
    this.maxLevels = 7,
  });
  final String dataDir;
  final int maxMemTableSize;
  final int maxLevelSize;
  final int maxLevels;
}

/// The main LSM-Tree storage engine
class LSMStorage {
  LSMStorage(this.config)
      : _memTable = MemTable(),
        _levels = List.generate(config.maxLevels, (_) => []);
  final LSMConfig config;
  MemTable _memTable;
  final List<List<SSTable>> _levels;
  int _nextTableId = 0;
  final _compactionPort = ReceivePort();
  Isolate? _compactionIsolate;

  /// Initialize the storage engine
  Future<void> init() async {
    // Create data directory if it doesn't exist
    final dir = Directory(config.dataDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Start compaction worker
    await _startCompactionWorker();
  }

  /// Put a key-value pair into the storage
  Future<void> put(Uint8List key, Uint8List value) async {
    _memTable.put(key, value);

    // Check if memtable needs to be flushed
    if (_memTable.size >= config.maxMemTableSize) {
      await _flushMemTable();
    }
  }

  /// Get a value by key
  Future<Uint8List?> get(Uint8List key) async {
    // Check memtable first
    final memValue = _memTable.get(key);
    if (memValue != null) {
      return memValue;
    }

    // Check each level's SSTables
    for (final level in _levels) {
      for (final table in level) {
        final value = await table.get(key);
        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  /// Delete a key
  Future<void> delete(Uint8List key) async {
    _memTable.delete(key);
  }

  /// Flush the current memtable to disk
  Future<void> _flushMemTable() async {
    if (_memTable.size == 0) return;

    // Create new SSTable
    final tableId = _nextTableId++;
    final tablePath = path.join(config.dataDir, 'table_$tableId.sst');
    final table = SSTable(
      filePath: tablePath,
      level: 0,
      id: tableId,
    );

    // Write memtable contents to SSTable
    await table.write(_memTable.entries);
    _levels[0].add(table);

    // Create new memtable
    _memTable = MemTable();

    // Trigger compaction if needed
    _triggerCompaction();
  }

  /// Trigger compaction if needed
  void _triggerCompaction() {
    for (int level = 0; level < config.maxLevels - 1; level++) {
      if (_shouldCompactLevel(level)) {
        _compactionPort.sendPort.send(level);
        break;
      }
    }
  }

  /// Check if a level needs compaction
  bool _shouldCompactLevel(int level) {
    if (level == 0) {
      return _levels[level].length >= 4;
    }

    int totalSize = 0;
    for (final table in _levels[level]) {
      totalSize += table.file.lengthSync();
    }
    return totalSize >= config.maxLevelSize;
  }

  /// Start the compaction worker isolate
  Future<void> _startCompactionWorker() async {
    _compactionIsolate = await Isolate.spawn(
      _compactionWorker,
      _compactionPort.sendPort,
    );
  }

  /// Compaction worker function
  static void _compactionWorker(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is int) {
        // TODO: Implement compaction logic
        // This will be implemented in the next phase
      }
    });
  }

  /// Close the storage engine
  Future<void> close() async {
    // Flush memtable if it has data
    if (_memTable.size > 0) {
      await _flushMemTable();
    }

    // Stop compaction worker
    _compactionIsolate?.kill();
    _compactionPort.close();
  }
}
