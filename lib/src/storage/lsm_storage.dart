import 'dart:async';
import 'dart:io';

import 'package:quanta_db/src/common/change_types.dart';
import 'package:quanta_db/src/storage/compaction_manager.dart';
import 'package:quanta_db/src/storage/memtable.dart';
import 'package:quanta_db/src/storage/sstable.dart';

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
  LSMStorage(this.path)
      : _memTable = MemTable(path: path),
        _sstables = [],
        _compactionManager = CompactionManager(path);
  final String path;
  final MemTable _memTable;
  final List<SSTable> _sstables;
  final CompactionManager _compactionManager;
  final _changeController = StreamController<ChangeEvent>.broadcast();

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

  /// Initialize the storage engine
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

  /// Put a key-value pair into the storage
  Future<void> put<T>(String key, T value) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    if (value == null) {
      throw ArgumentError('Value cannot be null');
    }

    try {
      // Validate value type
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
    } catch (e) {
      if (e is TypeException) rethrow;
      throw StorageException('Failed to put value: $e');
    }
  }

  /// Put multiple key-value pairs into the storage in a single batch
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

  /// Get a value by key
  Future<T?> get<T>(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }

    try {
      final value = await _memTable.get(key);
      if (value != null) {
        if (value is! T) {
          throw TypeException('Expected type $T but got ${value.runtimeType}');
        }
        return value;
      }

      for (final sstable in _sstables) {
        final value = await sstable.get(key);
        if (value != null) {
          if (value is! T) {
            throw TypeException(
                'Expected type $T but got ${value.runtimeType}');
          }
          return value;
        }
      }

      return null;
    } catch (e) {
      if (e is TypeException) rethrow;
      throw StorageException('Failed to get value: $e');
    }
  }

  /// Delete a key
  Future<void> delete(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }

    try {
      // Check if key exists before deleting
      final exists = await get(key) != null;
      if (!exists) {
        throw StorageException('Key not found: $key');
      }

      _memTable.delete(key);
      _changeController.add(ChangeEvent(
        key: key,
        value: null,
        type: dynamic,
        changeType: ChangeType.delete,
      ));
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to delete key: $e');
    }
  }

  /// Get all items of a specific type
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
      for (final key in entries.keys) {
        final value = entries[key];
        if (value is T) {
          results.add(value);
        }
      }
    }

    return results;
  }

  /// Get all keys in storage
  Future<List<String>> keys() async {
    return _memTable.keys.toList();
  }

  /// Close the storage engine
  Future<void> close() async {
    await _flushMemTable();
    await _compactionManager.dispose();
    _changeController.close();
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

/// Custom exceptions
class StorageException implements Exception {
  StorageException(this.message);
  final String message;
  @override
  String toString() => 'StorageException: $message';
}

class TypeException implements Exception {
  TypeException(this.message);
  final String message;
  @override
  String toString() => 'TypeException: $message';
}

class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;
  @override
  String toString() => 'ValidationException: $message';
}
