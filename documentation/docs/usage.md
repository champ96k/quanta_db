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

### Using the Generated DAO

```dart
// Get the DAO
final userDao = UserDao(db);

// Create a user
final user = User(
  id: '1',
  name: 'John',
  email: 'john@example.com',
  age: 30
);

// Insert the user
await userDao.insert(user);

// Find by ID
final found = await userDao.findById('1');

// Find by email (using index)
final byEmail = await userDao.findByEmail('john@example.com');

// Update user
user.name = 'John Updated';
await userDao.update(user);

// Delete user
await userDao.delete('1');
```

## Transactions

```dart
await db.transaction(() async {
  // Create user
  final user = User(
    id: '1',
    name: 'John',
    email: 'john@example.com',
    age: 30
  );
  await userDao.insert(user);
  
  // Create profile
  final profile = Profile(
    userId: user.id,
    bio: 'Software Developer'
  );
  await profileDao.insert(profile);
});
```

## Queries

```dart
// Find all users
final allUsers = await userDao.getAll();

// Find users by age
final youngUsers = await userDao.findByAge(30);

// Complex query
final results = await userDao.query()
  .where('age').greaterThan(18)
  .and('name').startsWith('J')
  .orderBy('age', descending: true)
  .limit(10)
  .execute();
```

## Real-time Updates

```dart
// Subscribe to changes
final subscription = userDao.watch().listen((event) {
  print('User changed: ${event.data}');
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
   - Use DAOs for data access
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