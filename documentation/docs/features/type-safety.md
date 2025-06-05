---
sidebar_position: 10
---

# Type Safety

QuantaDB emphasizes type safety, providing a robust development experience by allowing you to work with your data using strong types. This reduces the likelihood of runtime errors related to incorrect data types and improves code maintainability.

## ID Generation

QuantaDB supports both manual and automatic ID generation:

### Manual ID Assignment

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;  // Manual ID assignment
  
  final String name;
  final String email;
}

// Usage
final user = User(
  id: 'user_123',  // Manually assigned ID
  name: 'John',
  email: 'john@example.com'
);
```

### Auto-Generated IDs

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId(autoGenerate: true)  // Enable auto-generation
  final String id;
  
  final String name;
  final String email;
}

// Usage
final user = User(
  id: '',  // Empty ID will be auto-generated
  name: 'John',
  email: 'john@example.com'
);
```

Auto-generated IDs follow this format:
- Prefix: Entity name in lowercase (e.g., 'user_')
- Timestamp: Current milliseconds since epoch
- Random: 4-digit random number
Example: `user_16471234567891234`

## Type Safety Features

Type safety in QuantaDB is primarily achieved through **annotation-driven code generation**. You define your data models using Dart classes and annotate them with specific QuantaDB annotations. A build runner then automatically generates code that handles the serialization and deserialization of your objects to and from the database's storage format (DartBson).

This generated code ensures that when you read data from the database, it is correctly mapped back to your defined Dart classes, and when you write data, your Dart objects are properly converted for storage.

This approach provides compile-time checks for your data models and database operations, giving you confidence in the type correctness of your code.

## Example

```dart
import 'package:quanta_db/quanta_db.dart';

part 'my_data_models.g.dart';

@QuantaEntity()
class User {
  @QuantaId(autoGenerate: true)
  final String id;
  
  @QuantaField(required: true)
  final String name;
  
  @QuantaField(required: true)
  final int age;

  User({
    required this.id,
    required this.name,
    required this.age,
  });
}

// Type-safe operations
void main() async {
  final db = await QuantaDB.open('my_database');
  final queryEngine = QueryEngine(db.storage);
  
  // Create user with auto-generated ID
  final user = User(
    id: '',  // Will be auto-generated
    name: 'John',
    age: 30
  );
  
  await db.put('user:1', user);
  print('Created user with ID: ${user.id}');
  
  // Query users
  final users = await queryEngine.query<User>(
    Query<User>().where((user) => user.age > 25)
  );
  print('Found ${users.length} users over 25');
}
```

## Benefits

1. **Compile-time Type Checking**
   - Catch type errors before runtime
   - IDE support with autocompletion
   - Refactoring support

2. **Runtime Type Safety**
   - Automatic type conversion
   - Null safety support
   - Validation of required fields

3. **Code Generation**
   - Automatic serialization
   - Type-safe queries
   - Index management

4. **ID Management**
   - Flexible ID generation
   - Unique ID guarantees
   - Custom ID formats
 