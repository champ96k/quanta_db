import 'dart:convert';
import 'package:quanta_db/src/serialization/dart_bson.dart';

/// A memory table that stores key-value pairs in a sorted order using SplayTreeMap
class MemTable {
  /// Creates a new MemTable instance
  MemTable({String? path})
      : _data = {},
        path = path ?? '';

  /// The path where this MemTable is stored
  final String path;

  /// The underlying sorted map storing the key-value pairs
  final Map<String, dynamic> _data;

  /// The current size of the memtable in bytes
  int _size = 0;

  /// Add a key-value pair to the memtable
  void put(String key, dynamic value) {
    _data[key] = value;
    // Calculate size based on UTF-8 encoded key and Bson encoded value
    _size += utf8.encode(key).length + DartBson.encode(value).length;
  }

  /// Get a value by key
  dynamic get(String key) {
    return _data[key];
  }

  /// Delete a key
  void delete(String key) {
    final value = _data[key];
    if (value != null) {
      _size -= utf8.encode(key).length + DartBson.encode(value).length;
    }
    _data.remove(key);
  }

  /// Get the current size of the memtable in bytes
  int get size => _size;

  /// Get all entries in the memtable
  Map<String, dynamic> get entries => Map.unmodifiable(_data);

  /// Get all keys in the memtable
  Iterable<String> get keys => _data.keys;

  /// Clear the memtable
  void clear() {
    _data.clear();
    _size = 0;
  }
}
