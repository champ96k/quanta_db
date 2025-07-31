---
sidebar_position: 8
---

# Batch Operations

QuantaDB provides efficient batch operations for handling multiple records at once, significantly improving performance when dealing with large datasets.

## Batch Insertion

You can insert multiple records at once using the `putAll` method:

```dart
// Example of batch insertion
Future<void> batchInsert(QuantaDB db) async {
  final users = {
    'user:1': {'name': 'User 1', 'email': 'user1@example.com'},
    'user:2': {'name': 'User 2', 'email': 'user2@example.com'},
    'user:3': {'name': 'User 3', 'email': 'user3@example.com'},
  };
  
  // Insert all users in a single operation
  await db.storage.putAll(users);
}
```

## Batch Deletion

You can delete multiple records in a transaction:

```dart
// Example of batch deletion using transaction
Future<void> batchDelete(QuantaDB db) async {
  final keysToDelete = ['user:1', 'user:2', 'user:3'];
  
  await db.storage.transaction((txn) async {
    for (final key in keysToDelete) {
      await txn.delete(key);
    }
  });
}
```

## Delete All Records

To delete all records from the database, you can use the `deleteAll` method:

```dart
// Example of deleting all data from the database
Future<void> deleteAllRecords(QuantaDB db) async {
  // Delete all records with O(1) time complexity
  await db.deleteAll();
}
```

**Time Complexity**: The `deleteAll` method has O(1) time complexity, meaning it takes constant time regardless of how many records are in the database. This makes it extremely efficient for clearing large datasets.

> ⚠️ **Warning**: The `deleteAll` method removes all data from the database. This operation cannot be undone, so use it with caution.
