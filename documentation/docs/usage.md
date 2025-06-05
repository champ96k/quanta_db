---
sidebar_position: 3
---

# Usage

This section covers the basic usage of QuantaDB, from simple key-value operations to advanced features.

## Basic Operations

### Opening a Database

```dart
import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Open the database
  final db = await QuantaDB.open('my_database');
  
  // Use the database...
  
  // Don't forget to close it when done
  await db.close();
}
```

### Key-Value Operations

```dart
// Store data
await db.put('user:1', {
  'name': 'John',
  'email': 'john@example.com',
  'age': 30
});

// Retrieve data
final user = await db.get('user:1');
print('User: $user');

// Update data
await db.put('user:1', {
  'name': 'John Updated',
  'email': 'john@example.com',
  'age': 31
});

// Delete data
await db.delete('user:1');
```

## Working with Models

### Define Your Model

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;
  
  @QuantaField(required: true)
  final String name;
  
  @QuantaIndex()
  final String email;
  
  @QuantaField(required: true)
  final int age;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
  });
}
```

### Using Models with QuantaDB

```dart
// Create a user
final user = User(
  id: '1',
  name: 'John',
  email: 'john@example.com',
  age: 30
);

// Insert the user
await db.put('user:1', user);

// Find by ID
final found = await db.get<User>('user:1');

// Update user
final updatedUser = User(
  id: '1',
  name: 'John Updated',
  email: 'john@example.com',
  age: 31
);
await db.put('user:1', updatedUser);

// Delete user
await db.delete('user:1');
```

## Transactions

```dart
await db.storage.transaction((txn) async {
  // Create user
  final user = User(
    id: '1',
    name: 'John',
    email: 'john@example.com',
    age: 30
  );
  await txn.put('user:1', user);
  
  // Create profile
  final profile = Profile(
    userId: user.id,
    bio: 'Software Developer'
  );
  await txn.put('profile:1', profile);
});
```

## Queries

```dart
// Create a query engine
final queryEngine = QueryEngine(db.storage);

// Find all users
final allUsers = await queryEngine.query<User>(
  Query<User>()
);

// Find users by age
final youngUsers = await queryEngine.query<User>(
  Query<User>().where((user) => user.age < 30)
);

// Complex query
final results = await queryEngine.query<User>(
  Query<User>()
    .where((user) => user.age > 18)
    .where((user) => user.name.startsWith('J'))
    .sortBy((user) => user.age)
    .take(10)
);
```

## Real-time Updates

```dart
// Subscribe to changes
final subscription = queryEngine.watch<User, User>(
  Query<User>().where((user) => user.isActive)
).listen((user) {
  print('User changed: ${user.name}');
});

// Later, unsubscribe
subscription.cancel();
```

## Best Practices

1. **Resource Management**
   - Always close the database when done
   - Use try-finally blocks for cleanup
   - Handle errors appropriately

2. **Performance**
   - Use batch operations for multiple items
   - Create appropriate indexes
   - Monitor query performance

3. **Data Safety**
   - Use transactions for related operations
   - Implement proper error handling
   - Back up important data

4. **Code Organization**
   - Keep models in separate files
   - Use proper key naming conventions
   - Implement proper separation of concerns

## Tips

- QuantaDB is a **NoSQL** database using LSM-Trees
- Data is stored using a custom binary format (DartBson)
- Directory management is handled automatically
- All operations are asynchronous
- Transactions ensure data consistency
- Indexes improve query performance
- Real-time updates are supported
- Type safety is enforced through code generation

## Next Steps

- Read about [Advanced Features](features/)
- Check out [Code Examples](../code_examples)
- Review [Performance Tips](features/high-performance.md)
- Learn about [Data Security](features/data-security.md) 