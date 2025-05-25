// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'package:quanta_db/src/common/change_types.dart';
import 'package:quanta_db/src/storage/storage_interface.dart';

/// Web-specific storage implementation using IndexedDB
class WebStorage implements StorageInterface {
  WebStorage(this.dbName);
  final String dbName;
  dynamic _db; // Use dynamic for compatibility with Flutter web
  final _changeController = StreamController<ChangeEvent>.broadcast();

  @override
  Future<void> init() async {
    try {
      _db = await html.window.indexedDB?.open(
        dbName,
        version: 1,
        onUpgradeNeeded: (event) {
          final db = event.target.result;
          if (!db.objectStoreNames.contains('data')) {
            db.createObjectStore('data');
          }
        },
      );
    } catch (e) {
      throw Exception('Failed to initialize IndexedDB: $e');
    }
  }

  @override
  Future<void> put<T>(String key, T value) async {
    if (_db == null) {
      throw StateError('Database not initialized');
    }

    try {
      final transaction = _db.transaction('data', 'readwrite');
      final store = transaction.objectStore('data');
      await store.put(value, key);
      await transaction.completed;
      _changeController.add(ChangeEvent(
        key: key,
        value: value,
        type: T,
        changeType: ChangeType.insert,
      ));
    } catch (e) {
      throw Exception('Failed to put value: $e');
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    if (_db == null) {
      throw StateError('Database not initialized');
    }

    try {
      final transaction = _db.transaction('data', 'readonly');
      final store = transaction.objectStore('data');
      final value = await store.get(key);
      return value as T?;
    } catch (e) {
      throw Exception('Failed to get value: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    if (_db == null) {
      throw StateError('Database not initialized');
    }

    try {
      final transaction = _db.transaction('data', 'readwrite');
      final store = transaction.objectStore('data');
      await store.delete(key);
      await transaction.completed;
      _changeController.add(ChangeEvent(
        key: key,
        value: null,
        type: dynamic,
        changeType: ChangeType.delete,
      ));
    } catch (e) {
      throw Exception('Failed to delete value: $e');
    }
  }

  @override
  Future<List<T>> getAll<T>() async {
    if (_db == null) {
      throw StateError('Database not initialized');
    }

    try {
      final transaction = _db.transaction('data', 'readonly');
      final store = transaction.objectStore('data');
      var cursor = await store.openCursor();
      final results = <T>[];

      while (cursor != null) {
        final value = cursor.value;
        if (value is T) {
          results.add(value);
        }
        cursor = await cursor.continue_();
      }

      return results;
    } catch (e) {
      throw Exception('Failed to get all values: $e');
    }
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries) async {
    if (_db == null) {
      throw StateError('Database not initialized');
    }

    try {
      final transaction = _db.transaction('data', 'readwrite');
      final store = transaction.objectStore('data');
      for (final entry in entries.entries) {
        await store.put(entry.value, entry.key);
      }
      await transaction.completed;
      _changeController.add(ChangeEvent(
        key: 'batch',
        value: entries,
        type: Map<String, T>,
        changeType: ChangeType.batch,
      ));
    } catch (e) {
      throw Exception('Failed to put values: $e');
    }
  }

  @override
  Future<void> close() async {
    _db = null;
  }

  @override
  Stream<ChangeEvent> get onChange => _changeController.stream;
}
