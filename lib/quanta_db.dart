library quanta_db;

import 'dart:typed_data';
import 'src/storage/lsm_storage.dart';
import 'src/serialization/serializer.dart';

/// The main database class that provides a high-level interface to the LSM storage engine
class QuantaDB {
  final LSMStorage _storage;
  bool _isInitialized = false;
  final Map<Type, Serializer> _serializers = {
    String: StringSerializer(),
    int: IntSerializer(),
    double: DoubleSerializer(),
    bool: BoolSerializer(),
  };

  /// Create a new QuantaDB instance
  ///
  /// [dataDir] is the directory where the database files will be stored
  QuantaDB(String dataDir)
      : _storage = LSMStorage(LSMConfig(
          dataDir: dataDir,
        ));

  /// Initialize the database
  Future<void> init() async {
    if (_isInitialized) return;
    await _storage.init();
    _isInitialized = true;
  }

  /// Register a serializer for a specific type
  void registerSerializer<T>(Serializer<T> serializer) {
    _serializers[T] = serializer;
  }

  /// Put a value into the database
  ///
  /// [key] and [value] must be non-null
  Future<void> put<T>(String key, T value) async {
    _checkInitialized();
    final serializer = _getSerializer<T>();
    await _storage.put(
      Uint8List.fromList(key.codeUnits),
      serializer.serialize(value),
    );
  }

  /// Get a value from the database
  ///
  /// Returns null if the key doesn't exist
  Future<T?> get<T>(String key) async {
    _checkInitialized();
    final value = await _storage.get(Uint8List.fromList(key.codeUnits));
    if (value == null) return null;

    final serializer = _getSerializer<T>();
    return serializer.deserialize(value);
  }

  /// Delete a value from the database
  Future<void> delete(String key) async {
    _checkInitialized();
    await _storage.delete(Uint8List.fromList(key.codeUnits));
  }

  /// Close the database and release resources
  Future<void> close() async {
    if (!_isInitialized) return;
    await _storage.close();
    _isInitialized = false;
  }

  Serializer<T> _getSerializer<T>() {
    final serializer = _serializers[T];
    if (serializer == null) {
      throw StateError('No serializer registered for type $T');
    }
    return serializer as Serializer<T>;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Database must be initialized before use. Call init() first.');
    }
  }
}
