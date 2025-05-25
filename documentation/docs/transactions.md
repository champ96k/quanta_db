---
sidebar_position: 6
---

# Transactions

Transactions in QuantaDB ensure that multiple database operations are executed atomically - either all operations succeed, or none of them do. This is crucial for maintaining data consistency in your application.

## Basic Transaction Usage

Transactions are executed using the `transaction` method on the storage instance. Here's a basic example:

```dart
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
```

## Transaction Properties

### 1. Atomicity
All operations within a transaction are treated as a single unit. If any operation fails, the entire transaction is rolled back:

```dart
try {
  await db.storage.transaction((txn) async {
    // First operation succeeds
    await txn.put('key1', 'value1');
    
    // Second operation fails
    throw Exception('Operation failed');
    
    // This operation never executes
    await txn.put('key2', 'value2');
  });
} catch (e) {
  print('Transaction failed: $e');
  // Verify that no changes were made
  final value1 = await db.get('key1');
  final value2 = await db.get('key2');
  print('key1: $value1, key2: $value2'); // Both should be null
}
```

### 2. Isolation
Transactions are isolated from each other. Changes made in one transaction are not visible to other transactions until the transaction is committed:

```dart
// Transaction 1
await db.storage.transaction((txn1) async {
  await txn1.put('shared:key', 'value1');
  
  // Start Transaction 2 in parallel
  db.storage.transaction((txn2) async {
    // This will not see the changes from txn1
    final value = await txn2.get('shared:key');
    print('Transaction 2 sees: $value'); // Will be null or previous value
  });
  
  // Transaction 1's changes are not yet visible
});
```

### 3. Consistency
Transactions maintain database consistency by ensuring all operations either complete successfully or are rolled back:

```dart
await db.storage.transaction((txn) async {
  // Update related records atomically
  final user = User(
    id: 'user:1',
    name: 'John Doe',
    email: 'john@example.com',
    isActive: true,
    lastLogin: DateTime.now(),
  );
  
  // Update user record
  await txn.put('user:1', user);
  
  // Update user's settings
  await txn.put('settings:user:1', {
    'theme': 'dark',
    'notifications': true,
  });
  
  // Update user's profile
  await txn.put('profile:user:1', {
    'bio': 'Software Developer',
    'location': 'New York',
  });
  
  // All updates succeed or none do
});
```

## Best Practices

1. **Keep Transactions Short**
   ```dart
   // Good: Short, focused transaction
   await db.storage.transaction((txn) async {
     await txn.put('key1', 'value1');
     await txn.put('key2', 'value2');
   });

   // Avoid: Long-running transactions
   await db.storage.transaction((txn) async {
     // Don't include complex business logic or external API calls
     await txn.put('key1', 'value1');
     await someExternalApiCall(); // Bad practice
     await txn.put('key2', 'value2');
   });
   ```

2. **Error Handling**
   ```dart
   try {
     await db.storage.transaction((txn) async {
       // Transaction operations
     });
   } catch (e) {
     // Handle transaction failure
     print('Transaction failed: $e');
     // Implement retry logic or fallback behavior
   }
   ```

3. **Verify Transaction Results**
   ```dart
   await db.storage.transaction((txn) async {
     // Perform operations
   });
   
   // Verify the results after transaction completion
   final user1 = await db.get<User>('user:txn:1');
   final user2 = await db.get<User>('user:txn:2');
   print('Transaction users: ${user1 != null && user2 != null}');
   ```

## Common Use Cases

1. **Batch Updates**
   ```dart
   await db.storage.transaction((txn) async {
     for (var i = 0; i < 100; i++) {
       await txn.put('batch:$i', 'value$i');
     }
   });
   ```

2. **Related Data Updates**
   ```dart
   await db.storage.transaction((txn) async {
     // Update user and their related data atomically
     await txn.put('user:1', user);
     await txn.put('user:1:settings', settings);
     await txn.put('user:1:preferences', preferences);
   });
   ```

3. **Data Migration**
   ```dart
   await db.storage.transaction((txn) async {
     // Migrate data to new schema
     final oldData = await txn.get('old:key');
     if (oldData != null) {
       final newData = migrateToNewSchema(oldData);
       await txn.put('new:key', newData);
       await txn.delete('old:key');
     }
   });
   ```
