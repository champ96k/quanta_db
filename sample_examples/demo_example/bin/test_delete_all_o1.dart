import 'dart:async';
import 'package:quanta_db/quanta_db.dart';

// A simple user model for testing
class User {
  final String id;
  final String name;
  final int age;
  final bool isActive;

  User(this.id, this.name, this.age, this.isActive);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'isActive': isActive,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      map['id'],
      map['name'],
      map['age'],
      map['isActive'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, age: $age, isActive: $isActive}';
  }
}

Future<void> main() async {
  print('Starting performance test for O(1) deleteAll method...');
  
  // Open the database
  var db = await QuantaDB.open('delete_all_o1_test');
  
  try {
    // Test with small dataset (100 records)
    await testDeleteAll(db, 100, 'small');
    
    // Test with medium dataset (5,000 records)
    await testDeleteAll(db, 5000, 'medium');
    
    // Test with large dataset (20,000 records)
    await testDeleteAll(db, 20000, 'large');
    
  } catch (e) {
    print('Error during test: $e');
  } finally {
    // Close the database
    await db.close();
    print('\nTest completed.');
  }
}

Future<void> testDeleteAll(QuantaDB db, int recordCount, String datasetType) async {
  print('\n=== Testing with $datasetType dataset ($recordCount records) ===');
  
  // Insert records
  print('Inserting $recordCount records...');
  final Stopwatch insertStopwatch = Stopwatch()..start();
  
  for (int i = 0; i < recordCount; i++) {
    final user = User(
      'user_${datasetType}_$i',
      'User $i',
      20 + (i % 50), // Ages between 20-69
      i % 2 == 0, // Half active, half inactive
    );
    
    await db.storage.put(user.id, user.toMap());
    
    // Print progress for large datasets
    if (recordCount > 1000 && (i + 1) % 1000 == 0) {
      print('Inserted ${i + 1} records...');
    }
  }
  
  insertStopwatch.stop();
  print('Inserted $recordCount records in ${insertStopwatch.elapsedMilliseconds}ms');
  
  // Verify record count
  final allKeys = await db.storage.keys();
  print('Total records in database: ${allKeys.length}');
  
  // Delete all records and measure time
  print('\nDeleting all records using O(1) deleteAll method...');
  final Stopwatch deleteStopwatch = Stopwatch()..start();
  
  try {
    await db.deleteAll();
    deleteStopwatch.stop();
    print('Deleted all records in ${deleteStopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    deleteStopwatch.stop();
    print('Error during deleteAll: $e');
    print('Attempting to reopen the database...');
    
    // Reopen the database
    db = await QuantaDB.open('delete_all_o1_test');
    print('Database reopened successfully.');
  }
  
  // Verify deletion
  final remainingKeys = await db.storage.keys();
  print('Remaining records in database: ${remainingKeys.length}');
  
  if (remainingKeys.isEmpty) {
    print('Success: All records were deleted successfully!');
  } else {
    print('Warning: Some records were not deleted. Remaining: ${remainingKeys.length}');
  }
}