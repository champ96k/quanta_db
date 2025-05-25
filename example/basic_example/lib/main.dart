// ignore_for_file: avoid_print

import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Open the database
  final db = await QuantaDB()
    ..open(path: 'my_database');

  try {
    // Store some data
    await db.put('user:1', {
      'name': 'John Doe',
      'email': 'john@example.com',
      'age': 30,
    });

    // Store another record
    await db.put('user:2', {
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'age': 25,
    });

    // Retrieve data
    final user1 = await db.get('user:1');
    print('User 1: $user1');

    // Update data
    await db.put('user:1', {
      'name': 'John Doe',
      'email': 'john.doe@example.com', // Updated email
      'age': 31, // Updated age
    });

    // Retrieve updated data
    final updatedUser1 = await db.get('user:1');
    print('Updated User 1: $updatedUser1');

    // Delete data
    await db.delete('user:2');
    final deletedUser = await db.get('user:2');
    print('Deleted User 2: $deletedUser'); // Should be null

    // Query all users using queryEngine
    final queryEngine = QueryEngine(db.storage);
    final allUsers = await queryEngine.query<Map<String, dynamic>>(
      Query<Map<String, dynamic>>(),
    );
    print('All Users: $allUsers');
  } finally {
    // Always close the database when done
    await db.close();
  }
}
