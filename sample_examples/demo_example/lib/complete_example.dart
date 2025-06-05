// ignore_for_file: avoid_print

import 'dart:async';
import 'package:quanta_db/quanta_db.dart';

import 'model/user.dart';

void main() async {
  // Initialize the database
  final db = await QuantaDB.open('complete_example');
  await db.init();

  try {
    // Create a query engine
    final queryEngine = QueryEngine(db.storage);

    // Example 1: Basic CRUD Operations
    print('\n=== Example 1: Basic CRUD Operations ===');
    await _demonstrateCRUD(db);

    // Example 2: Query Operations
    print('\n=== Example 2: Query Operations ===');
    await _demonstrateQueries(queryEngine);

    // Example 3: Transactions
    print('\n=== Example 3: Transactions ===');
    await _demonstrateTransactions(db);

    // Example 4: Error Handling
    print('\n=== Example 4: Error Handling ===');
    await _demonstrateErrorHandling(db);

    // Example 5: Reactive Queries
    print('\n=== Example 5: Reactive Queries ===');
    await _demonstrateReactiveQueries(queryEngine);

    // Example 6: Batch Operations
    print('\n=== Example 6: Batch Operations ===');
    await _demonstrateBatchOperations(db);

    // Clean up
    await db.close();
  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> _demonstrateCRUD(QuantaDB db) async {
  // Create
  final user = User(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    isActive: true,
    lastLogin: DateTime.now(),
  );
  await db.put('user:1', user);
  print('Created user: $user');

  print('Created toDebugString: ${user.toDebugString()}');

  // Read
  final retrievedUser = await db.get<User>('user:1');
  print('Retrieved user: ${retrievedUser?.toDebugString()}');

  // Update
  final updatedUser = User(
    id: '1',
    name: 'John Doe Updated',
    email: 'john.updated@example.com',
    isActive: true,
    lastLogin: DateTime.now(),
  );
  await db.put('user:1', updatedUser);
  print('Updated user: ${updatedUser.toDebugString()}');

  // Delete
  await db.delete('user:1');
  final deletedUser = await db.get<User>('user:1');
  print('After deletion: ${deletedUser?.toDebugString()}');
}

Future<void> _demonstrateQueries(QueryEngine queryEngine) async {
  // Store some test data
  await _storeTestData(queryEngine.storage);

  // Basic query with filtering
  final activeUsers = await queryEngine.query<User>(
    Query<User>().where((user) => user.isActive),
  );
  print('Active users: ${activeUsers.length}');

  // Query with sorting
  final sortedUsers = await queryEngine.query<User>(
    Query<User>().sortBy((user) => user.lastLogin),
  );
  print('Users sorted by last login: ${sortedUsers.length}');

  // Query with pagination
  final paginatedUsers = await queryEngine.query<User>(
    Query<User>().take(2).skip(1),
  );
  print('Paginated users: ${paginatedUsers.length}');

  // Complex query with multiple conditions
  final complexQuery = await queryEngine.query<User>(
    Query<User>()
        .where((user) => user.isActive)
        .where((user) => user.email.contains('example.com'))
        .sortBy((user) => user.name),
  );
  print('Complex query results: ${complexQuery.length}');
}

Future<void> _demonstrateTransactions(QuantaDB db) async {
  // Start a transaction
  await db.storage.transaction((txn) async {
    // Create multiple users atomically
    final user1 = User(
      id: 'txn:1',
      name: 'Transaction User 1',
      email: 'txn1@example.com',
      isActive: true,
      lastLogin: DateTime.now(),
    );
    await txn.put('user:txn:1', user1);

    final user2 = User(
      id: 'txn:2',
      name: 'Transaction User 2',
      email: 'txn2@example.com',
      isActive: true,
      lastLogin: DateTime.now(),
    );
    await txn.put('user:txn:2', user2);

    // If any operation fails, the entire transaction is rolled back
  });
  print('Transaction completed successfully');

  // Add detailed verification
  final user1 = await db.get<User>('user:txn:1');
  final user2 = await db.get<User>('user:txn:2');
  print('Transaction users:');
  print('User 1: ${user1?.toJson()}');
  print('User 2: ${user2?.toJson()}');
}

Future<void> _demonstrateErrorHandling(QuantaDB db) async {
  print('\nTesting error handling scenarios:');

  try {
    // Try to get a non-existent key
    print('\n1. Getting non-existent key:');
    final result = await db.get('non-existent-key');
    print('Result: $result'); // Should print null
  } catch (e) {
    if (e is StorageException) {
      print('Storage error: $e');
    } else {
      print('Unexpected error: $e');
    }
  }

  try {
    // Try to put invalid data
    print('\n2. Putting invalid data:');
    final invalidData = <String, dynamic>{
      'id': 'invalid',
      'name': 'Invalid User',
      // Missing required fields: email, isActive, lastLogin
    };
    print('Attempting to store invalid data: $invalidData');
    await db.put<User>('invalid-key', invalidData as User); // Force type error
  } catch (e) {
    print('Caught error: ${e.runtimeType}');
    if (e is TypeException) {
      print('Type error: $e');
    } else if (e is ValidationException) {
      print('Validation error: $e');
    } else if (e is StorageException) {
      print('Storage error: $e');
    } else {
      print('Unexpected error: $e');
    }
  }

  try {
    // Try to use an invalid query
    print('\n3. Using invalid query:');
    final queryEngine = QueryEngine(db.storage);
    await queryEngine.query<User>(
      Query<User>().where((user) => throw Exception('Invalid predicate')),
    );
  } catch (e) {
    if (e is QueryException) {
      print('Query error: $e');
    } else {
      print('Unexpected error: $e');
    }
  }

  try {
    // Try to put empty key
    print('\n4. Putting empty key:');
    await db.put(
        '',
        User(
          id: '1',
          name: 'Test User',
          email: 'test@example.com',
          isActive: true,
          lastLogin: DateTime.now(),
        ));
  } catch (e) {
    if (e is ArgumentError) {
      print('Argument error: $e');
    } else {
      print('Unexpected error: $e');
    }
  }

  try {
    // Try to put null value
    print('\n5. Putting null value:');
    await db.put('test-key', null);
  } catch (e) {
    if (e is ArgumentError) {
      print('Argument error: $e');
    } else {
      print('Unexpected error: $e');
    }
  }
}

Future<void> _demonstrateReactiveQueries(QueryEngine queryEngine) async {
  // Add debouncing to prevent duplicate events
  final activeUsersStream = queryEngine
      .watch<User, User>(
        Query<User>().where((user) => user.isActive),
      )
      .distinct(); // Add distinct() to prevent duplicate events

  // Add proper error handling and logging
  final subscription1 = activeUsersStream.listen(
    (user) => print('Active user updated: ${user.name}'),
    onError: (error) => print('Error in active users stream: $error'),
    onDone: () => print('Stream completed'),
  );

  final userStatsStream = queryEngine.watch<User, Map<String, dynamic>>(
    Query<User>().aggregate((users) {
      return {
        'total': users.length,
        'active': users.where((u) => u.isActive).length,
        'domains': users.map((u) => u.email.split('@').last).toSet().length,
      };
    }),
  );

  // Listen to streams
  final subscription2 = userStatsStream.listen(
    (stats) => print('User stats updated: $stats'),
    onError: (error) => print('Error in stats stream: $error'),
  );

  // Make some changes to trigger updates
  await Future.delayed(const Duration(seconds: 1));
  await _storeTestData(queryEngine.storage);
  await Future.delayed(const Duration(seconds: 1));

  // Clean up subscriptions
  subscription1.cancel();
  subscription2.cancel();
}

Future<void> _storeTestData(LSMStorage storage) async {
  // Store multiple users with different properties
  final users = [
    User(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      isActive: true,
      lastLogin: DateTime.now(),
    ),
    User(
      id: '2',
      name: 'Jane Smith',
      email: 'jane@company.com',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    User(
      id: '3',
      name: 'Bob Wilson',
      email: 'bob@example.com',
      isActive: false,
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  for (final user in users) {
    await storage.put('user:${user.id}', user);
  }
  print('Test data stored successfully');
}

Future<void> _demonstrateBatchOperations(QuantaDB db) async {
  try {
    // Create a batch of users
    final users = {
      'user:batch:1': User(
        id: 'batch:1',
        name: 'Batch User 1',
        email: 'batch1@example.com',
        isActive: true,
        lastLogin: DateTime.now(),
      ),
      'user:batch:2': User(
        id: 'batch:2',
        name: 'Batch User 2',
        email: 'batch2@example.com',
        isActive: true,
        lastLogin: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      'user:batch:3': User(
        id: 'batch:3',
        name: 'Batch User 3',
        email: 'batch3@example.com',
        isActive: false,
        lastLogin: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    };

    // Store all users in a single batch operation
    print('Storing ${users.length} users in batch...');
    await db.storage.putAll(users);
    print('Batch operation completed successfully');

    // Verify the batch operation
    for (final entry in users.entries) {
      final retrievedUser = await db.get<User>(entry.key);
      print('Retrieved user from batch: ${retrievedUser?.name}');
      print(
          'Validation status: ${retrievedUser != null ? "Success" : "Failed"}');
    }
  } catch (e) {
    print('Batch operation error: $e');
  }
}
