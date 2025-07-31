import 'dart:io';
import 'package:test/test.dart';
import 'package:quanta_db/quanta_db.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for the test database
    tempDir = await Directory.systemTemp.createTemp('quanta_db_test_');
  });

  tearDown(() async {
    // Clean up the temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deleteAll removes all data from the database', () async {
    // Create a new database instance for this test
    final db = await QuantaDB.open(tempDir.path);
    await db.init();
    
    try {
      // Populate the database with test data
      await db.put('test:1', {'name': 'Test 1', 'value': 100});
      await db.put('test:2', {'name': 'Test 2', 'value': 200});
      await db.put('test:3', {'name': 'Test 3', 'value': 300});
      
      // Verify data was stored
      final value1 = await db.get('test:1');
      final value2 = await db.get('test:2');
      final value3 = await db.get('test:3');
      
      expect(value1, isNotNull);
      expect(value2, isNotNull);
      expect(value3, isNotNull);
      
      // Delete all data
      await db.deleteAll();
      
      // Verify all data was deleted
      final deletedValue1 = await db.get('test:1');
      final deletedValue2 = await db.get('test:2');
      final deletedValue3 = await db.get('test:3');
      
      expect(deletedValue1, isNull);
      expect(deletedValue2, isNull);
      expect(deletedValue3, isNull);
    } finally {
      // Always close the database
      await db.close();
    }
  });

  test('deleteAll allows adding new data after deletion', () async {
    // Create a new database instance for this test
    final db = await QuantaDB.open(tempDir.path);
    await db.init();
    
    try {
      // Populate the database with test data
      await db.put('test:1', {'name': 'Test 1', 'value': 100});
      
      // Delete all data
      await db.deleteAll();
      
      // Add new data after deletion
      await db.put('test:new', {'name': 'New Test', 'value': 999});
      
      // Verify old data is gone and new data exists
      final oldValue = await db.get('test:1');
      final newValue = await db.get('test:new');
      
      expect(oldValue, isNull);
      expect(newValue, isNotNull);
      expect(newValue['name'], equals('New Test'));
      expect(newValue['value'], equals(999));
    } finally {
      // Always close the database
      await db.close();
    }
  });

  test('deleteAll works with empty database', () async {
    // Create a new database instance for this test
    final db = await QuantaDB.open(tempDir.path);
    await db.init();
    
    try {
      // Delete all data on an empty database
      await db.deleteAll();
      
      // Verify we can still add data
      await db.put('test:empty', {'name': 'After Empty Delete', 'value': 42});
      
      // Verify data was stored
      final value = await db.get('test:empty');
      
      expect(value, isNotNull);
      expect(value['name'], equals('After Empty Delete'));
      expect(value['value'], equals(42));
    } finally {
      // Always close the database
      await db.close();
    }
  });
}