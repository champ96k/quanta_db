import 'package:flutter_test/flutter_test.dart';
import 'package:quanta_db/storage/storage_manager.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  late StorageManager storage;

  setUpAll(() {
    // Skip tests if not running on web
    if (!kIsWeb) {
      fail('These tests should only run on web platform');
    }
  });

  setUp(() {
    storage = StorageManager('test_web_db');
  });

  group('StorageManager Web Tests', () {
    test('should store and retrieve data using IndexedDB', () async {
      final key = Uint8List.fromList([1, 2, 3]);
      final value = Uint8List.fromList([4, 5, 6]);

      // Store data
      await storage.put(key, value);

      // Retrieve data
      final retrieved = await storage.get(key);
      expect(retrieved, equals(value));
    });

    test('should handle multiple operations', () async {
      final key1 = Uint8List.fromList([1, 2, 3]);
      final value1 = Uint8List.fromList([4, 5, 6]);
      final key2 = Uint8List.fromList([7, 8, 9]);
      final value2 = Uint8List.fromList([10, 11, 12]);

      // Store multiple values
      await storage.put(key1, value1);
      await storage.put(key2, value2);

      // Verify both values
      expect(await storage.get(key1), equals(value1));
      expect(await storage.get(key2), equals(value2));

      // Delete one value
      await storage.delete(key1);
      expect(await storage.get(key1), isNull);
      expect(await storage.get(key2), equals(value2));
    });

    test('should handle prefix searches', () async {
      final prefix = Uint8List.fromList([1]);
      final key1 = Uint8List.fromList([1, 2, 3]);
      final key2 = Uint8List.fromList([1, 4, 5]);
      final key3 = Uint8List.fromList([2, 3, 4]);
      final value = Uint8List.fromList([1]);

      await storage.put(key1, value);
      await storage.put(key2, value);
      await storage.put(key3, value);

      final keys = await storage.getKeysWithPrefix(prefix);
      expect(keys.length, equals(2));
      expect(keys.any((k) => listEquals(k, key1)), isTrue);
      expect(keys.any((k) => listEquals(k, key2)), isTrue);
    });

    test('should clear all data', () async {
      final key = Uint8List.fromList([1, 2, 3]);
      final value = Uint8List.fromList([4, 5, 6]);

      await storage.put(key, value);
      expect(await storage.get(key), equals(value));

      await storage.clear();
      expect(await storage.get(key), isNull);
    });
  });
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
