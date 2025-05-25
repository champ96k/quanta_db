---
sidebar_position: 7
---

# Error Handling

Proper error handling is crucial for building robust applications with QuantaDB. This section covers various error handling scenarios and best practices.

## Basic Error Handling

### 1. Try-Catch Blocks

The most basic form of error handling is using try-catch blocks:

```dart
try {
  // Try to get a non-existent key
  await db.get('non-existent-key');
} catch (e) {
  print('Expected error for non-existent key: $e');
}
```

### 2. Type-Specific Error Handling

QuantaDB throws specific types of exceptions that you can catch and handle appropriately:

```dart
try {
  // Try to put invalid data
  await db.put('invalid-key', Object());
} catch (e) {
  if (e is QuantaDBException) {
    print('Database error: ${e.message}');
  } else {
    print('Unexpected error: $e');
  }
}
```

## Common Error Scenarios

### 1. Non-Existent Keys

```dart
try {
  final value = await db.get('non-existent-key');
  if (value == null) {
    print('Key does not exist');
  }
} catch (e) {
  print('Error accessing key: $e');
}
```

### 2. Invalid Data Types

```dart
try {
  // Try to store an invalid object
  await db.put('invalid-key', Object());
} catch (e) {
  print('Error storing invalid data: $e');
}
```

### 3. Invalid Queries

```dart
try {
  final queryEngine = QueryEngine(db.storage);
  await queryEngine.query<User>(
    Query<User>()
        .where((user) => user.email.length > 100), // Invalid but type-safe
  );
} catch (e) {
  print('Error executing query: $e');
}
```

## Error Handling in Transactions

### 1. Transaction Rollback

```dart
try {
  await db.storage.transaction((txn) async {
    await txn.put('key1', 'value1');
    throw Exception('Operation failed');
    // Transaction will be rolled back
  });
} catch (e) {
  print('Transaction failed: $e');
  // Verify rollback
  final value = await db.get('key1');
  print('Value after rollback: $value'); // Should be null
}
```

### 2. Nested Error Handling

```dart
try {
  await db.storage.transaction((txn) async {
    try {
      await txn.put('key1', 'value1');
      await txn.put('key2', 'value2');
    } catch (e) {
      print('Error within transaction: $e');
      // Transaction will still be rolled back
      rethrow; // Re-throw to trigger transaction rollback
    }
  });
} catch (e) {
  print('Transaction failed: $e');
}
```

## Error Handling in Queries

### 1. Query Validation

```dart
try {
  final queryEngine = QueryEngine(db.storage);
  await queryEngine.query<User>(
    Query<User>()
        .where((user) => user.email.contains('@')) // Valid query
        .sortBy((user) => user.name),
  );
} catch (e) {
  print('Query error: $e');
}
```

### 2. Type Safety in Queries

```dart
try {
  final queryEngine = QueryEngine(db.storage);
  await queryEngine.query<User>(
    Query<User>()
        .where((user) => user.isActive)
        .where((user) => user.email.length > 100), // Invalid condition
  );
} catch (e) {
  print('Type safety error in query: $e');
}
```

## Error Handling in Reactive Queries

### 1. Stream Error Handling

```dart
final activeUsersStream = queryEngine.watch<User, User>(
  Query<User>().where((user) => user.isActive),
);

final subscription = activeUsersStream.listen(
  (user) => print('Active user updated: ${user.name}'),
  onError: (error) {
    print('Error in active users stream: $error');
    // Implement retry logic or error recovery
  },
  cancelOnError: false, // Continue listening after errors
);
```

### 2. Aggregate Query Error Handling

```dart
final userStatsStream = queryEngine.watch<User, Map<String, dynamic>>(
  Query<User>().aggregate((users) {
    try {
      return {
        'total': users.length,
        'active': users.where((u) => u.isActive).length,
        'domains': users.map((u) => u.email.split('@').last).toSet().length,
      };
    } catch (e) {
      print('Error in aggregate function: $e');
      return {'error': e.toString()};
    }
  }),
);
```

## Best Practices

1. **Always Use Try-Catch**
   ```dart
   try {
     await db.put('key', value);
   } catch (e) {
     // Handle error appropriately
     print('Error: $e');
   }
   ```

2. **Specific Error Types**
   ```dart
   try {
     await db.get('key');
   } catch (e) {
     if (e is QuantaDBException) {
       // Handle database-specific errors
     } else if (e is TypeError) {
       // Handle type errors
     } else {
       // Handle unexpected errors
     }
   }
   ```

3. **Error Recovery**
   ```dart
   Future<void> retryOperation() async {
     int attempts = 0;
     while (attempts < 3) {
       try {
         await db.put('key', value);
         break;
       } catch (e) {
         attempts++;
         if (attempts == 3) rethrow;
         await Future.delayed(Duration(seconds: attempts));
       }
     }
   }
   ```

4. **Logging and Monitoring**
   ```dart
   try {
     await db.put('key', value);
   } catch (e, stackTrace) {
     print('Error: $e');
     print('Stack trace: $stackTrace');
     // Log to monitoring service
   }
   ```

## Next Steps

- Learn about [Transactions](./transactions.md) for atomic operations
- Explore [Batch Operations](./batch-operations.md) for efficient bulk data operations
- Check out [Query Operations](./query-operations.md) for retrieving data 