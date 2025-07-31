---
sidebar_position: 4
---

# Basic CRUD Operations

This section guides you through the fundamental Create, Read, Update, and Delete (CRUD) operations in QuantaDB. These operations form the basis of interacting with your data.

We assume you have already initialized and opened your QuantaDB instance as shown in the [Usage](./usage.md) section.

Let's use a simple `User` model for these examples (ensure your model is defined and code-generated if you are using type safety, as discussed in the [Type Safety](./features/type-safety.md) feature overview).

```dart
// Assuming your User model looks something like this:
class User {
  final String id;
  String name;
  String email;
  bool isActive;
  DateTime lastLogin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.lastLogin,
  });

  // Add methods for serialization/deserialization if not using code generation
  // Map<String, dynamic> toMap() { .... }
  // static User fromMap(Map<String, dynamic> map) { ... }
}
```

### Create (Put)

To create or insert a new record, use the `put` method. If a record with the same key already exists, `put` will update it.

```dart
// Example from example/demo_example/lib/complete_example.dart
Future<void> _demonstrateCRUD(QuantaDB db) async {
  // Create
  final user = User(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    isActive: true,
    lastLogin: DateTime.now(),
  );
  await db.put('user:1', user); // Key-value pair: 'user:1' is the key, user object is the value
  print('Created user: $user');

  // ... (rest of the CRUD operations will follow)
}
```

The `put` method takes a unique `key` (String) and the `value` (your data object or Map). QuantaDB stores data as key-value pairs.

### Read (Get)

To retrieve a record by its key, use the `get` method. You can optionally specify the expected type using generics if you are using type safety.

```dart
// Example from example/demo_example/lib/complete_example.dart
Future<void> _demonstrateCRUD(QuantaDB db) async {
  // ... (Create part)

  // Read
  final retrievedUser = await db.get<User>('user:1'); // Use <User> if using type safety
  print('Retrieved user: $retrievedUser');

  // ... (rest of the CRUD operations will follow)
}
```

The `get` method returns the value associated with the provided key, or `null` if the key does not exist.

### Update (Put)

As mentioned, the `put` method is also used for updating existing records. Simply call `put` with the same key as an existing record, and the value will be overwritten.

```dart
// Example from example/demo_example/lib/complete_example.dart
Future<void> _demonstrateCRUD(QuantaDB db) async {
  // ... (Create and Read parts)

  // Update
  final updatedUser = User(
    id: '1',
    name: 'John Doe Updated',
    email: 'john.updated@example.com',
    isActive: true,
    lastLogin: DateTime.now(),
  );
  await db.put('user:1', updatedUser); // Use the same key 'user:1'
  print('Updated user: $updatedUser');

  // ... (Delete part will follow)
}
```

### Delete

To remove a record from the database, use the `delete` method, providing the key of the record you want to remove.

```dart
// Example from example/demo_example/lib/complete_example.dart
Future<void> _demonstrateCRUD(QuantaDB db) async {
  // ... (Create, Read, and Update parts)

  // Delete
  await db.delete('user:1');
  final deletedUser = await db.get<User>('user:1'); // Try to get it after deletion
  print('After deletion: $deletedUser'); // Should print null
}
```

The `delete` method removes the key-value pair associated with the given key.

### Delete All

To remove all data from the database, use the `deleteAll` method. This is useful for scenarios like logging out a user, clearing cache, or resetting the application state.

```dart
// Example of deleting all data from the database
Future<void> _demonstrateDeleteAll(QuantaDB db) async {
  print('Deleting all data from the database...');
  
  // Call the deleteAll method - O(1) time complexity regardless of dataset size
  await db.deleteAll();
  
  print('All data has been deleted from the database');
}
```

> ⚠️ **Warning**: The `deleteAll` method removes all data from the database with O(1) time complexity. This operation cannot be undone, so use it with caution.

**Time Complexity**: The `deleteAll` method has O(1) time complexity, meaning it takes constant time regardless of how many records are in the database. This makes it extremely efficient for clearing large datasets.

These basic CRUD operations are the foundation for managing data in QuantaDB. In the next sections, we will explore more advanced topics like querying and transactions.
