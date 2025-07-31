import 'dart:async';
import 'package:quanta_db/quanta_db.dart';

Future<void> main() async {
  print('Starting simple test for O(1) deleteAll method...');
  
  // Open the database
  final db = await QuantaDB.open('delete_all_simple_test');
  
  try {
    // Insert a small number of records
    final recordCount = 100;
    print('Inserting $recordCount records...');
    
    for (int i = 0; i < recordCount; i++) {
      await db.storage.put('key_$i', {'value': 'test_$i'});
    }
    
    // Verify record count
    final allKeys = await db.storage.keys();
    print('Total records in database: ${allKeys.length}');
    
    // Delete all records and measure time
    print('\nDeleting all records using O(1) deleteAll method...');
    final Stopwatch deleteStopwatch = Stopwatch()..start();
    
    await db.deleteAll();
    
    deleteStopwatch.stop();
    print('Deleted all records in ${deleteStopwatch.elapsedMilliseconds}ms');
    
    // Verify deletion
    final remainingKeys = await db.storage.keys();
    print('Remaining records in database: ${remainingKeys.length}');
    
    if (remainingKeys.isEmpty) {
      print('Success: All records were deleted successfully!');
    } else {
      print('Warning: Some records were not deleted. Remaining: ${remainingKeys.length}');
    }
  } catch (e) {
    print('Error during test: $e');
  } finally {
    // Close the database
    await db.close();
    print('\nTest completed.');
  }
}