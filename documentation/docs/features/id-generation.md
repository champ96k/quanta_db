---
sidebar_position: 11
---

# ID Generation

QuantaDB provides flexible ID generation capabilities for your entities. You can choose between manual ID assignment or automatic ID generation based on your needs.

## Manual ID Assignment

By default, QuantaDB expects you to provide IDs manually:

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;
  
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

## Auto-Generated IDs

To enable automatic ID generation, use the `autoGenerate` parameter in the `@QuantaId` annotation:

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId(autoGenerate: true)
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

### ID Format

Auto-generated IDs follow this format:
- Prefix: Entity name in lowercase (e.g., 'user_')
- Timestamp: Current milliseconds since epoch
Example: `user_1647123456789`

### Custom Prefix

You can specify a custom prefix for your IDs:

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId(autoGenerate: true, prefix: 'usr_')
  final String id;
  
  final String name;
  final String email;
}
```

This will generate IDs like: `usr_1647123456789`

## Best Practices

1. **Choose the Right Strategy**
   - Use manual IDs when you need specific ID formats or have existing ID systems
   - Use auto-generated IDs for new entities or when ID format doesn't matter

2. **ID Uniqueness**
   - Auto-generated IDs are guaranteed to be unique within a single database instance
   - For distributed systems, consider adding additional uniqueness measures

3. **ID Length**
   - Auto-generated IDs are typically 20-25 characters long
   - Consider this when designing your database schema

4. **ID Prefixes**
   - Use meaningful prefixes to identify entity types
   - Helps with debugging and data organization

## Example Usage

```dart
void main() async {
  final db = await QuantaDB.open('my_database');
  final userDao = UserDao(db);
  
  // Create user with auto-generated ID
  final user = User(
    id: '',  // Will be auto-generated
    name: 'John',
    email: 'john@example.com'
  );
  
  await userDao.insert(user);
  print('Created user with ID: ${user.id}');
  
  // Create user with manual ID
  final user2 = User(
    id: 'user_manual_123',
    name: 'Jane',
    email: 'jane@example.com'
  );
  
  await userDao.insert(user2);
  print('Created user with ID: ${user2.id}');
}
```

## Limitations

1. Auto-generated IDs are not guaranteed to be sequential
2. IDs are not reversible (cannot extract creation time from ID)
3. IDs are not suitable for sorting by creation time
4. Maximum length of auto-generated IDs is fixed

## Future Enhancements

Planned improvements for ID generation:
1. Sequential ID generation
2. UUID support
3. Custom ID generation strategies
4. ID validation and constraints 