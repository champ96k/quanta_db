class MemTable {
  MemTable({String? path}) : _data = {};
  final Map<String, dynamic> _data;
  int get size => _data.length;
  Map<String, dynamic> get entries => Map.unmodifiable(_data);
  Iterable<String> get keys => _data.keys;

  /// Put a value
  void put(String key, dynamic value) {
    _data[key] = value;
  }

  /// Get a value
  dynamic get(String key) {
    return _data[key];
  }

  /// Delete a value
  void delete(String key) {
    _data.remove(key);
  }

  /// Clear all data
  void clear() {
    _data.clear();
  }
}
