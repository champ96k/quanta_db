import 'package:quanta_db/quanta_db.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// The main database class that provides a high-level interface to the LSM storage engine
class QuantaDB {
  /// Create a new QuantaDB instance
  ///
  /// `dbName` is the name of the database
  /// The database will be stored in a platform-specific secure location
  QuantaDB._(this.storage) : queryEngine = QueryEngine(storage);

  final LSMStorage storage;
  final QueryEngine queryEngine;
  bool _isInitialized = false;

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

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Database must be initialized before use. Call init() first.');
    }
  }
}
