// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) 'dart:io' as platform;

/// Manages storage operations for the database
class StorageManager {
  StorageManager(this._dbName) {
    if (kIsWeb) {
      _initIndexedDB();
    }
  }
  final Map<String, Uint8List> _memoryStorage = {};
  final String _dbName;
  dynamic _indexedDB;

  Future<void> _initIndexedDB() async {
    if (kIsWeb) {
      final request = platform.window.indexedDB?.open(_dbName, 1);
      request?.onUpgradeNeeded.listen((event) {
        final db = event.target.result;
        if (!db.objectStoreNames.contains('quanta_db')) {
          db.createObjectStore('quanta_db');
        }
      });
      request?.onSuccess.listen((event) {
        _indexedDB = event.target.result;
      });
    }
  }

  String _keyToString(Uint8List key) {
    return String.fromCharCodes(key);
  }

  /// Store a value with the given key
  Future<void> put(Uint8List key, Uint8List value) async {
    final keyStr = _keyToString(key);
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readwrite');
      final store = transaction.objectStore('quanta_db');
      await store.put(value, keyStr);
    } else {
      _memoryStorage[keyStr] = value;
    }
  }

  /// Retrieve a value by key
  Future<Uint8List?> get(Uint8List key) async {
    final keyStr = _keyToString(key);
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readonly');
      final store = transaction.objectStore('quanta_db');
      final request = store.get(keyStr);
      return await request.onSuccess.first.then((event) => event.target.result);
    } else {
      return _memoryStorage[keyStr];
    }
  }

  /// Delete a value by key
  Future<void> delete(Uint8List key) async {
    final keyStr = _keyToString(key);
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readwrite');
      final store = transaction.objectStore('quanta_db');
      await store.delete(keyStr);
    } else {
      _memoryStorage.remove(keyStr);
    }
  }

  /// Check if a key exists
  Future<bool> exists(Uint8List key) async {
    final keyStr = _keyToString(key);
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readonly');
      final store = transaction.objectStore('quanta_db');
      final request = store.get(keyStr);
      final result =
          await request.onSuccess.first.then((event) => event.target.result);
      return result != null;
    } else {
      return _memoryStorage.containsKey(keyStr);
    }
  }

  /// Get all keys with a given prefix
  Future<List<Uint8List>> getKeysWithPrefix(Uint8List prefix) async {
    final prefixStr = _keyToString(prefix);
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readonly');
      final store = transaction.objectStore('quanta_db');
      final request = store.getAllKeys();
      final keys =
          await request.onSuccess.first.then((event) => event.target.result);
      return keys
          .where((key) => key.startsWith(prefixStr))
          .map((key) => Uint8List.fromList(key.codeUnits))
          .toList();
    } else {
      return _memoryStorage.keys
          .where((key) => key.startsWith(prefixStr))
          .map((key) => Uint8List.fromList(key.codeUnits))
          .toList();
    }
  }

  /// Clear all data
  Future<void> clear() async {
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readwrite');
      final store = transaction.objectStore('quanta_db');
      await store.clear();
    } else {
      _memoryStorage.clear();
    }
  }

  /// Get all keys in storage
  Future<List<Uint8List>> keys() async {
    if (kIsWeb && _indexedDB != null) {
      final transaction = _indexedDB.transaction(['quanta_db'], 'readonly');
      final store = transaction.objectStore('quanta_db');
      final request = store.getAllKeys();
      final keys =
          await request.onSuccess.first.then((event) => event.target.result);
      return keys.map((key) => Uint8List.fromList(key.codeUnits)).toList();
    } else {
      return _memoryStorage.keys
          .map((key) => Uint8List.fromList(key.codeUnits))
          .toList();
    }
  }
}
