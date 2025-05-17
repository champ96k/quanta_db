import 'dart:collection';
import 'dart:typed_data';

/// A memory table that stores key-value pairs in a sorted order using SplayTreeMap
class MemTable {
  final SplayTreeMap<Uint8List, Uint8List> _table;
  int _size = 0;

  MemTable() : _table = SplayTreeMap(_compareBytes);

  /// Add a key-value pair to the memtable
  void put(Uint8List key, Uint8List value) {
    _size += key.length + value.length;
    _table[key] = value;
  }

  /// Get a value by key
  Uint8List? get(Uint8List key) {
    return _table[key];
  }

  /// Delete a key
  void delete(Uint8List key) {
    if (_table.containsKey(key)) {
      _size -= key.length + _table[key]!.length;
      _table.remove(key);
    }
  }

  /// Get the current size of the memtable in bytes
  int get size => _size;

  /// Get all entries in the memtable
  Map<Uint8List, Uint8List> get entries => Map.unmodifiable(_table);

  /// Clear the memtable
  void clear() {
    _table.clear();
    _size = 0;
  }

  /// Compare two byte arrays for sorting
  static int _compareBytes(Uint8List a, Uint8List b) {
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) {
        return a[i].compareTo(b[i]);
      }
    }
    return a.length.compareTo(b.length);
  }
}
