// ignore_for_file: avoid_print

import 'dart:io';
import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Create a temporary directory for the test database
  final tempDir = await Directory.systemTemp.createTemp('quanta_db_test_');
  print('Created temporary directory: ${tempDir.path}');
  
  try {
    // Open the database in the temporary directory
    print('\nOpening database...');
    final db = await QuantaDB.open(tempDir.path);
    await db.init();
    print('Database initialized');
    
    // Populate the database with test data
    print('\nPopulating database with test data...');
    await db.put('test:1', {'name': 'Test 1', 'value': 100});
    await db.put('test:2', {'name': 'Test 2', 'value': 200});
    await db.put('test:3', {'name': 'Test 3', 'value': 300});
    print('Added 3 test records');
    
    // Verify data was stored
    print('\nVerifying data was stored:');
    final value1 = await db.get('test:1');
    final value2 = await db.get('test:2');
    final value3 = await db.get('test:3');
    
    print('test:1 = $value1');
    print('test:2 = $value2');
    print('test:3 = $value3');
    
    // Delete all data
    print('\nDeleting all data...');
    await db.deleteAll();
    print('All data deleted');
    
    // Verify all data was deleted
    print('\nVerifying all data was deleted:');
    final deletedValue1 = await db.get('test:1');
    final deletedValue2 = await db.get('test:2');
    final deletedValue3 = await db.get('test:3');
    
    print('test:1 = $deletedValue1');
    print('test:2 = $deletedValue2');
    print('test:3 = $deletedValue3');
    
    // Add new data after deletion
    print('\nAdding new data after deletion...');
    await db.put('test:new', {'name': 'New Test', 'value': 999});
    print('Added new test record');
    
    // Verify new data exists
    print('\nVerifying new data exists:');
    final newValue = await db.get('test:new');
    print('test:new = $newValue');
    
    // Close the database
    print('\nClosing database...');
    await db.close();
    print('Database closed');
    
    print('\nTest completed successfully!');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Clean up the temporary directory
    print('\nCleaning up temporary directory...');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      print('Temporary directory deleted');
    }
  }
}