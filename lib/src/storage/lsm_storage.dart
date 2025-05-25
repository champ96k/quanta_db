import 'dart:async';
import 'dart:io';

import 'package:quanta_db/src/common/change_types.dart';
import 'package:quanta_db/src/storage/compaction_manager.dart';
import 'package:quanta_db/src/storage/memtable.dart';
import 'package:quanta_db/src/storage/sstable.dart';
import 'package:quanta_db/src/storage/storage_interface.dart';

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
class LSMStorage implements StorageInterface {
  LSMStorage(this.path)
      : _memTable = MemTable(path: path),
        _sstables = [],
        _compactionManager = CompactionManager(path);
  final String path;
  final MemTable _memTable;
  final List<SSTable> _sstables;
  final CompactionManager _compactionManager;
  final _changeController = StreamController<ChangeEvent>.broadcast();

  @override
  Stream<ChangeEvent> get onChange => _changeController.stream;

  /// Execute a transaction
  Future<void> transaction(
      Future<void> Function(Transaction txn) callback) async {
    final txn = Transaction(this);
    try {
      await callback(txn);
      await txn.commit();
    } catch (e) {
      await txn.rollback();
      rethrow;
    }
  }

  @override
  Future<void> init() async {
    // Create data directory if it doesn't exist
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Load existing SSTables
    await _loadSSTables();
  }

  /// Load existing SSTables from disk
  Future<void> _loadSSTables() async {
    final dir = Directory(path);
    if (!await dir.exists()) return;

    final files = await dir.list().toList();
    for (final file in files) {
      if (file.path.endsWith('.sst')) {
        try {
          final sstable = await SSTable.load(file.path);
          _sstables.add(sstable);
        } catch (e) {
          // ignore: avoid_print
          print('Error loading SSTable ${file.path}: $e');
          // Optionally delete corrupted files
          await file.delete();
        }
      }
    }
  }

  @override
  Future<void> put<T>(String key, T value) async {
    _memTable.put(key, value);
    _changeController.add(ChangeEvent(
      key: key,
      value: value,
      type: T,
      changeType: ChangeType.insert,
    ));

    // Check if memtable needs to be flushed
    if (_memTable.size >= LSMConfig(dataDir: path).maxMemTableSize) {
      await _flushMemTable();
    }
  }

  /// Put multiple key-value pairs into the storage in a single batch
  @override
  Future<void> putAll<T>(Map<String, T> entries) async {
    // Add all entries to memtable
    for (final entry in entries.entries) {
      _memTable.put(entry.key, entry.value);
    }

    // Add batch change event
    _changeController.add(ChangeEvent(
      key: 'batch',
      value: entries,
      type: Map<String, T>,
      changeType: ChangeType.batch,
    ));

    // Check if memtable needs to be flushed
    if (_memTable.size >= LSMConfig(dataDir: path).maxMemTableSize) {
      await _flushMemTable();
    }
  }

  /// Flush the memtable to disk as a new SSTable
  Future<void> _flushMemTable() async {
    final entries = _memTable.entries;
    if (entries.isEmpty) return;

    // Create new SSTable
    final memTable = MemTable(path: path);
    for (final entry in entries.entries) {
      memTable.put(entry.key, entry.value);
    }
    final sstable = await SSTable.create(
      memTable,
      0,
      DateTime.now().millisecondsSinceEpoch,
    );

    _sstables.add(sstable);
    _memTable.clear();

    // Schedule compaction if needed
    await _scheduleCompaction();
  }

  /// Schedule compaction of SSTables if needed
  Future<void> _scheduleCompaction() async {
    final config = LSMConfig(dataDir: path);
    final levelSizes = <int, int>{};
    final levelTables = <int, List<SSTable>>{};

    // Group tables by level and calculate sizes
    for (final table in _sstables) {
      final size = await File(table.path).length();
      levelSizes[table.level] = (levelSizes[table.level] ?? 0) + size;
      levelTables[table.level] = [...(levelTables[table.level] ?? []), table];
    }

    // Check each level for compaction
    for (var level = 0; level < config.maxLevels; level++) {
      final size = levelSizes[level] ?? 0;
      if (size > config.maxLevelSize) {
        final tables = levelTables[level] ?? [];
        if (tables.length > 1) {
          _compactionManager.scheduleCompaction(tables, level + 1);
        }
      }
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    final value = await _memTable.get(key);
    if (value != null) return value as T;

    for (final sstable in _sstables) {
      final value = await sstable.get(key);
      if (value != null) return value as T;
    }

    return null;
  }

  @override
  Future<void> delete(String key) async {
    _memTable.delete(key);
    _changeController.add(ChangeEvent(
      key: key,
      value: null,
      type: dynamic,
      changeType: ChangeType.delete,
    ));
  }

  @override
  Future<List<T>> getAll<T>() async {
    final results = <T>[];

    // Get items from memtable
    for (final entry in _memTable.entries.entries) {
      if (entry.value is T) {
        results.add(entry.value as T);
      }
    }

    // Get items from SSTables
    for (final sstable in _sstables) {
      final entries = await sstable.getAll();
      for (final entry in entries.entries) {
        if (entry.value is T) {
          results.add(entry.value as T);
        }
      }
    }

    return results;
  }

  @override
  Future<void> close() async {
    await _compactionManager.dispose();
  }
}

/// A transaction for atomic operations
class Transaction {
  Transaction(this._storage) : _memTable = MemTable();
  final LSMStorage _storage;
  final MemTable _memTable;
  final _changes = <ChangeEvent>[];

  /// Put a key-value pair in the transaction
  Future<void> put<T>(String key, T value) async {
    _memTable.put(key, value);
    _changes.add(ChangeEvent(
      key: key,
      value: value,
      type: T,
      changeType: ChangeType.insert,
    ));
  }

  /// Delete a key in the transaction
  Future<void> delete(String key) async {
    _memTable.delete(key);
    _changes.add(ChangeEvent(
      key: key,
      value: null,
      type: dynamic,
      changeType: ChangeType.delete,
    ));
  }

  /// Commit the transaction
  Future<void> commit() async {
    // Apply changes to the main storage
    for (final entry in _memTable.entries.entries) {
      await _storage.put(entry.key, entry.value);
    }
  }

  /// Rollback the transaction
  Future<void> rollback() async {
    _memTable.clear();
    _changes.clear();
  }
}
