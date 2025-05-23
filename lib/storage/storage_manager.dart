import 'dart:typed_data';

/// Manages storage operations for the database
class StorageManager {
  final Map<String, Uint8List> _storage = {};

  String _keyToString(Uint8List key) {
    return String.fromCharCodes(key);
  }

  /// Store a value with the given key
  Future<void> put(Uint8List key, Uint8List value) async {
    _storage[_keyToString(key)] = value;
  }

  /// Retrieve a value by key
  Future<Uint8List?> get(Uint8List key) async {
    return _storage[_keyToString(key)];
  }

  /// Delete a value by key
  Future<void> delete(Uint8List key) async {
    _storage.remove(_keyToString(key));
  }

  /// Check if a key exists
  Future<bool> exists(Uint8List key) async {
    return _storage.containsKey(_keyToString(key));
  }

  /// Get all keys with a given prefix
  Future<List<Uint8List>> getKeysWithPrefix(Uint8List prefix) async {
    final prefixStr = _keyToString(prefix);
    return _storage.keys
        .where((key) => key.startsWith(prefixStr))
        .map((key) => Uint8List.fromList(key.codeUnits))
        .toList();
  }

  /// Clear all data
  Future<void> clear() async {
    _storage.clear();
  }
}
