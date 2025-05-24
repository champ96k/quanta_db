import 'package:flutter_test/flutter_test.dart';
import 'package:quanta_db/quanta_db.dart';

import 'dart:io';

void main() {
  late LSMStorage storage;
  late String tempDir;

  setUp(() async {
    tempDir =
        '${Directory.systemTemp.path}/quanta_test_${DateTime.now().millisecondsSinceEpoch}';
    storage = LSMStorage(tempDir);
    await storage.init();
  });

  tearDown(() async {
    await storage.close();
    await Directory(tempDir).delete(recursive: true);
  });

  group('Batch Operations', () {
    test('should store multiple entries in a single batch', () async {
      // Create test data
      final entries = {
        'key1': 'value1',
        'key2': 'value2',
        'key3': 'value3',
      };

      // Store entries in batch
      await storage.putAll(entries);

      // Verify all entries were stored
      for (final entry in entries.entries) {
        final value = await storage.get<String>(entry.key);
        expect(value, equals(entry.value));
      }
    });

    test('should handle empty batch', () async {
      await storage.putAll({});
      // Should not throw any errors
    });

    test('should handle large batch operations', () async {
      // Create a large batch of entries
      final entries = Map<String, String>.fromIterables(
        List.generate(1000, (i) => 'key$i'),
        List.generate(1000, (i) => 'value$i'),
      );

      // Store entries in batch
      await storage.putAll(entries);

      // Verify all entries were stored
      for (final entry in entries.entries) {
        final value = await storage.get<String>(entry.key);
        expect(value, equals(entry.value));
      }
    });

    test('should handle mixed value types in batch', () async {
      final entries = {
        'string': 'value',
        'int': 42,
        'double': 3.14,
        'bool': true,
        'list': [1, 2, 3],
        'map': {'key': 'value'},
      };

      await storage.putAll(entries);

      // Verify all entries were stored with correct types
      expect(await storage.get<String>('string'), equals('value'));
      expect(await storage.get<int>('int'), equals(42));
      expect(await storage.get<double>('double'), equals(3.14));
      expect(await storage.get<bool>('bool'), equals(true));
      expect(await storage.get<List>('list'), equals([1, 2, 3]));
      expect(await storage.get<Map>('map'), equals({'key': 'value'}));
    });

    test('should handle batch operations with existing keys', () async {
      // First store some initial values
      await storage.putAll({
        'key1': 'old1',
        'key2': 'old2',
      });

      // Then update them in a batch
      await storage.putAll({
        'key1': 'new1',
        'key2': 'new2',
        'key3': 'new3',
      });

      // Verify the updates
      expect(await storage.get<String>('key1'), equals('new1'));
      expect(await storage.get<String>('key2'), equals('new2'));
      expect(await storage.get<String>('key3'), equals('new3'));
    });

    test('should trigger change events for batch operations', () async {
      final events = <ChangeEvent>[];
      final subscription = storage.onChange.listen(events.add);

      final entries = {
        'key1': 'value1',
        'key2': 'value2',
      };

      await storage.putAll(entries);

      // Verify that a single batch event was emitted
      expect(events.length, equals(1));
      expect(events.first.changeType, equals(ChangeType.batch));
      expect(events.first.value, equals(entries));

      await subscription.cancel();
    });

    test('should handle batch operations within transactions', () async {
      await storage.transaction((txn) async {
        final entries = {
          'key1': 'value1',
          'key2': 'value2',
        };

        // Store entries in batch within transaction
        for (final entry in entries.entries) {
          await txn.put(entry.key, entry.value);
        }
      });

      // Verify the transaction was committed
      expect(await storage.get<String>('key1'), equals('value1'));
      expect(await storage.get<String>('key2'), equals('value2'));
    });
  });
}
