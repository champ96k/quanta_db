import 'dart:collection';
import 'dart:convert';
import 'package:quanta_db/src/serialization/dart_bson.dart';

/// A memory table that stores key-value pairs in a sorted order using SplayTreeMap
class MemTable {
  /// Creates a new MemTable instance
  MemTable({String? path}) : path = path ?? '';

  /// The path where this MemTable is stored
  final String path;

  /// The underlying sorted map storing the key-value pairs
  final _table = SplayTreeMap<String, dynamic>();

  /// The current size of the memtable in bytes
  int _size = 0;

  /// Add a key-value pair to the memtable
  void put<T>(String key, T value) {
    _table[key] = value;
    // Calculate size based on UTF-8 encoded key and Bson encoded value
    _size += utf8.encode(key).length + DartBson.encode(value).length;
  }

  /// Get a value by key
  T? get<T>(String key) {
    return _table[key] as T?;
  }

  /// Delete a key
  void delete(String key) {
    final value = _table[key];
    if (value != null) {
      _size -= utf8.encode(key).length + DartBson.encode(value).length;
    }
    _table.remove(key);
  }

  /// Get the current size of the memtable in bytes
  int get size => _size;

  /// Get all entries in the memtable
  Map<String, dynamic> get entries => Map.unmodifiable(_table);

  /// Clear the memtable
  void clear() {
    _table.clear();
    _size = 0;
  }
}
