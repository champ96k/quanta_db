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

    // Example 7: Schema Migrations
    print('\n=== Example 7: Schema Migrations ===');
    await _demonstrateSchemaMigrations(db);

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

  // Read
  final retrievedUser = await db.get<User>('user:1');
  print('Retrieved user: $retrievedUser');

  // Update
  final updatedUser = User(
    id: '1',
    name: 'John Doe Updated',
    email: 'john.updated@example.com',
    isActive: true,
    lastLogin: DateTime.now(),
  );
  await db.put('user:1', updatedUser);
  print('Updated user: $updatedUser');

  // Delete
  await db.delete('user:1');
  final deletedUser = await db.get<User>('user:1');
  print('After deletion: $deletedUser');
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

  // Verify transaction results
  final user1 = await db.get<User>('user:txn:1');
  final user2 = await db.get<User>('user:txn:2');
  print('Transaction users: ${user1 != null && user2 != null}');
}

Future<void> _demonstrateErrorHandling(QuantaDB db) async {
  try {
    // Try to get a non-existent key
    await db.get('non-existent-key');
  } catch (e) {
    print('Expected error for non-existent key: $e');
  }

  try {
    // Try to put invalid data
    await db.put('invalid-key', Object());
  } catch (e) {
    print('Expected error for invalid data: $e');
  }

  try {
    // Try to use an invalid query
    final queryEngine = QueryEngine(db.storage);
    await queryEngine.query<User>(
      Query<User>()
          .where((user) => user.email.length > 100), // Invalid but type-safe
    );
  } catch (e) {
    print('Expected error for invalid query: $e');
  }
}

Future<void> _demonstrateReactiveQueries(QueryEngine queryEngine) async {
  // Set up reactive queries
  final activeUsersStream = queryEngine.watch<User, User>(
    Query<User>().where((user) => user.isActive),
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
  final subscription1 = activeUsersStream.listen(
    (user) => print('Active user updated: ${user.name}'),
    onError: (error) => print('Error in active users stream: $error'),
  );

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
  }
}

Future<void> _demonstrateSchemaMigrations(QuantaDB db) async {
  // Initial schema
  final oldSchema = {
    'fields': {
      'id': {'type': 'String', 'nullable': false},
      'name': {'type': 'String', 'nullable': false},
      'email': {'type': 'String', 'nullable': true},
    },
    'indexes': [
      {
        'name': 'email_idx',
        'fields': ['email'],
        'unique': true
      }
    ],
  };

  // New schema with changes
  final newSchema = {
    'fields': {
      'id': {'type': 'String', 'nullable': false},
      'name': {'type': 'String', 'nullable': false},
      'email': {'type': 'String', 'nullable': true},
      'age': {'type': 'int', 'nullable': true}, // New field
      'isActive': {'type': 'bool', 'nullable': false}, // New field
    },
    'indexes': [
      {
        'name': 'email_idx',
        'fields': ['email'],
        'unique': true
      },
      {
        'name': 'active_idx',
        'fields': ['isActive'],
        'unique': false
      }
    ],
  };

  // Generate migration
  final generator = MigrationGenerator();
  await generator.generateMigration(
    'User',
    1,
    2,
    oldSchema,
    newSchema,
  );

  print('Migration script generated successfully');
  print('Check lib/migrations directory for the generated file');
}
