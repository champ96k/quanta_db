import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:quanta_db/src/query/query_engine.dart';
import 'package:quanta_db/src/storage/lsm_storage.dart';
import 'package:quanta_db/src/storage/storage_interface.dart';
import 'package:quanta_db/src/storage/storage_web.dart'
    if (dart.library.io) 'package:quanta_db/src/storage/storage_web_stub.dart';

/// The main database class that provides a high-level interface to the LSM storage engine
class QuantaDB {
  factory QuantaDB() => _instance;
  QuantaDB._internal();
  static final QuantaDB _instance = QuantaDB._internal();

  /// Get the singleton instance
  static QuantaDB get instance => _instance;

  StorageInterface? _storage;
  late QueryEngine _queryEngine;
  bool _isInitialized = false;

  /// Get the storage instance
  StorageInterface get storage {
    if (!_isInitialized || _storage == null) {
      throw StateError('Database not initialized. Call open() first.');
    }
    return _storage!;
  }

  /// Get the query engine instance
  QueryEngine get queryEngine {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call open() first.');
    }
    return _queryEngine;
  }

  /// Check if the database is initialized
  bool get isInitialized => _isInitialized;

  /// Open the database
  Future<void> open({String? path}) async {
    if (_isInitialized) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dbPath = path ?? _getDefaultPath();
      await _createDbDirectory(dbPath);
      _storage = LSMStorage(dbPath);
    } else {
      _storage = WebStorage('quanta_db');
    }

    await _storage!.init();
    _queryEngine = QueryEngine(_storage!);
    _isInitialized = true;
  }

  /// Initialize the database
  Future<void> init() async {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call open() first.');
    }
  }

  /// Put a value in the database
  Future<void> put<T>(String key, T value) async {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call open() first.');
    }
    await _storage!.put(key, value);
  }

  /// Get a value from the database
  Future<T?> get<T>(String key) async {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call open() first.');
    }
    return _storage!.get<T>(key);
  }

  /// Delete a value from the database
  Future<void> delete(String key) async {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call open() first.');
    }
    await _storage!.delete(key);
  }

  /// Get all values of a type from the database
  Future<List<T>> getAll<T>() async {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call open() first.');
    }
    return _storage!.getAll<T>();
  }

  /// Close the database
  Future<void> close() async {
    if (!_isInitialized) return;

    _queryEngine.dispose();
    await _storage?.close();
    _storage = null;
    _isInitialized = false;
  }

  String _getDefaultPath() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return path.join(home!, '.quanta_db');
  }

  Future<void> _createDbDirectory(String dbPath) async {
    final dir = Directory(dbPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}

final db = QuantaDB();
