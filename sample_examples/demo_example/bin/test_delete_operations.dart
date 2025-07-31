// ignore_for_file: avoid_print

import 'package:demo_example/model/user.dart';
import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Initialize the database
  final db = await QuantaDB.open('test_delete_operations');
  await db.init();

  try {
    // Test batch delete operations
    print('\n=== Testing Batch Delete Operations ===');
    await _testBatchDeleteOperations(db);

    // Test delete all operations
    print('\n=== Testing Delete All Operations ===');
    await _testDeleteAllOperations(db);

    print('\nAll tests completed successfully!');
  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Clean up
    await db.close();
  }
}

Future<void> _testBatchDeleteOperations(QuantaDB db) async {
  try {
    // First, create some users to delete
    final users = {
      'user:delete:1': User(
        id: 'delete:1',
        name: 'Delete User 1',
        email: 'delete1@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
      'user:delete:2': User(
        id: 'delete:2',
        name: 'Delete User 2',
        email: 'delete2@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
      'user:delete:3': User(
        id: 'delete:3',
        name: 'Delete User 3',
        email: 'delete3@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
    };

    // Store all users in a single batch operation
    print('Storing ${users.length} users for deletion demonstration...');
    await db.storage.putAll(users);

    // Verify users were created
    for (final key in users.keys) {
      final user = await db.get<User>(key);
      print('Created user: ${user?.name}');
    }

    // Create a list of keys to delete
    final keysToDelete = users.keys.toList();

    // Delete all users in a batch using transaction
    print(
        'Deleting ${keysToDelete.length} users in batch using transaction...');
    try {
      await db.storage.transaction((txn) async {
        for (final key in keysToDelete) {
          // First check if the key exists
          final exists = await db.get(key) != null;
          if (exists) {
            await txn.delete(key);
          } else {
            print('Key $key not found, skipping delete');
          }
        }
      });
      print('Batch delete operation completed successfully');
    } catch (e) {
      print('Error during batch delete: $e');
    }

    // Verify the deletion
    for (final key in keysToDelete) {
      final user = await db.get<User>(key);
      print(
          'User $key after deletion: ${user == null ? "Successfully deleted" : "Failed to delete"}');
    }
  } catch (e) {
    print('Batch delete operation error: $e');
  }
}

Future<void> _testDeleteAllOperations(QuantaDB db) async {
  try {
    // First, create some users to delete
    final users = {
      'user:delete:1': User(
        id: 'delete:1',
        name: 'Delete User 1',
        email: 'delete1@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
      'user:delete:2': User(
        id: 'delete:2',
        name: 'Delete User 2',
        email: 'delete2@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
      'user:delete:3': User(
        id: 'delete:3',
        name: 'Delete User 3',
        email: 'delete3@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
    };

    // Store all users in a single batch operation
    print('Storing ${users.length} users for deletion demonstration...');
    await db.storage.putAll(users);

    // Verify users were created
    for (final key in users.keys) {
      final user = await db.get<User>(key);
      print('Created user: ${user?.name}');
    }

    // Delete all data
    print('Deleting all data...');
    await db.deleteAll();
    print('Delete all operation completed successfully');

    // Verify all users were deleted
    for (final key in users.keys) {
      final user = await db.get<User>(key);
      print(
          'User $key after delete all: ${user == null ? "Successfully deleted" : "Failed to delete"}');
    }
  } catch (e) {
    print('Delete all operation error: $e');
  }
}
