import 'package:quanta_db/quanta_db.dart';
import 'package:path/path.dart' as path;

/// The main database class that provides a high-level interface to the LSM storage engine
class QuantaDB {
  /// Create a new QuantaDB instance
  ///
  /// `dbName` is the name of the database
  /// `baseDir` is the base directory where the database files will be stored (defaults to 'quanta_db')
  QuantaDB._(this.storage) : queryEngine = QueryEngine(storage);

  final LSMStorage storage;
  final QueryEngine queryEngine;
  bool _isInitialized = false;

  static Future<QuantaDB> open(String dbName,
      {String? baseDir = 'quanta_db'}) async {
    final dbDir = path.join(baseDir ?? 'quanta_db', dbName);
    final storage = LSMStorage(dbDir);
    await storage.init();
    return QuantaDB._(storage);
  }

  /// Initialize the database
  Future<void> init() async {
    if (_isInitialized) return;
    await storage.init();
    _isInitialized = true;
  }

  /// Put a value into the database
  ///
  /// [key] and [value] must be non-null
  Future<void> put<T>(String key, T value) async {
    _checkInitialized();
    await storage.put(key, value);
  }

  /// Get a value from the database
  ///
  /// Returns null if the key doesn't exist
  Future<T?> get<T>(String key) async {
    _checkInitialized();
    return storage.get<T>(key);
  }

  /// Delete a value from the database
  Future<void> delete(String key) async {
    _checkInitialized();
    await storage.delete(key);
  }

  /// Close the database and release resources
  Future<void> close() async {
    if (!_isInitialized) return;
    await storage.close();
    _isInitialized = false;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Database must be initialized before use. Call init() first.');
    }
  }
}
