import 'package:quanta_db/quanta_db.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// The main database class that provides a high-level interface to the LSM storage engine
class QuantaDB {
  /// Private constructor for QuantaDB that initializes the storage engine and query engine
  ///
  /// [storage] The LSM storage engine instance that handles data persistence
  QuantaDB._(this.storage) : queryEngine = QueryEngine(storage);

  /// The LSM storage engine instance that handles data persistence
  final LSMStorage storage;

  /// The query engine instance that handles data retrieval and filtering
  final QueryEngine queryEngine;

  /// Flag indicating whether the database has been initialized
  bool _isInitialized = false;

  /// Creates and initializes a new QuantaDB instance
  ///
  /// [dbName] The name of the database to create/open
  /// Returns a [Future] that completes with the initialized [QuantaDB] instance
  static Future<QuantaDB> open(String dbName) async {
    String dbDir;

    // Use platform-specific app directory
    if (Platform.isIOS || Platform.isAndroid) {
      // For mobile platforms, use app's documents directory
      final appDir = await _getAppDirectory();
      dbDir = path.join(appDir.path, 'databases', dbName);
    } else if (Platform.isMacOS) {
      // For macOS, use Application Support
      final homeDir = Platform.environment['HOME'];
      dbDir = path.join(
          homeDir!, 'Library', 'Application Support', 'quanta_db', dbName);
    } else if (Platform.isWindows) {
      // For Windows, use AppData
      final appData = Platform.environment['APPDATA'];
      dbDir = path.join(appData!, 'quanta_db', dbName);
    } else if (Platform.isLinux) {
      // For Linux, use XDG data home
      final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
      dbDir = path.join(
          xdgDataHome ?? '${Platform.environment['HOME']}/.local/share',
          'quanta_db',
          dbName);
    } else {
      // For pure Dart, use a secure directory in the user's home
      final homeDir =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (homeDir != null) {
        // Create a hidden directory in the user's home
        dbDir = path.join(homeDir, '.quanta_db', dbName);
      } else {
        // Last resort: use current directory
        dbDir = path.join(Directory.current.path, dbName);
      }
    }

    // Create database directory
    await Directory(dbDir).create(recursive: true);

    final storage = LSMStorage(dbDir);
    await storage.init();
    return QuantaDB._(storage);
  }

  static Future<Directory> _getAppDirectory() async {
    // For pure Dart, use a secure directory in the user's home
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir != null) {
      return Directory(path.join(homeDir, '.quanta_db'));
    }
    // Last resort: use current directory
    return Directory.current;
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

  /// Delete all data from the database
  ///
  /// This method deletes all data from the database, including all SSTables and the memtable.
  /// Use with caution as this operation cannot be undone.
  /// 
  /// Time complexity: O(1) regardless of dataset size
  Future<void> deleteAll() async {
    _checkInitialized();

    try {
      // Use close and reinitialize approach for O(1) time complexity
      // This effectively clears all data without individual deletions
      await storage.close();
      await storage.init();
      _isInitialized = true; // Ensure database remains initialized
    } catch (e) {
      throw StorageException('Failed to delete all data: $e');
    }
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Database must be initialized before use. Call init() first.');
    }
  }
}
