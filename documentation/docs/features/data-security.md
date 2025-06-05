---
sidebar_position: 7
---

# Data Security

QuantaDB prioritizes the security of your local data, offering built-in features to help you protect sensitive information.

## Field-Level Encryption

QuantaDB provides field-level encryption through the `@QuantaEncrypted` annotation:

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;
  
  @QuantaEncrypted()
  final String password;  // This field will be encrypted at rest
  
  @QuantaField(required: true)
  final String name;
  
  User({required this.id, required this.password, required this.name});
}
```

## Secure Storage

QuantaDB automatically handles platform-specific secure directory management:

- **iOS/Android**: Uses app's documents directory
- **macOS**: Uses Application Support directory
- **Windows**: Uses AppData directory
- **Linux**: Uses XDG data home directory
- **Pure Dart**: Uses secure directory in user's home

## Access Control

Control field visibility using the `@QuantaVisibleTo` annotation:

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;
  
  @QuantaVisibleTo(['admin'])
  final String email;  // Only visible to admin users
  
  @QuantaField(required: true)
  final String name;
}
```

## Data Validation

Built-in validation support through the `@QuantaField` annotation:

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaField(
    required: true,
    min: 0,
    max: 120,
    pattern: r'^[a-zA-Z]+$'
  )
  final String name;
  
  @QuantaField(
    required: true,
    validator: 'email'
  )
  final String email;
}
```

## Audit Logging

Enable audit logging for database operations:

```dart
final db = await QuantaDB.open(
  'my_database',
  enableAuditLogging: true
);
```

## Best Practices

1. **Encryption**
   - Use `@QuantaEncrypted` for sensitive data
   - Consider encrypting personally identifiable information
   - Keep encryption keys secure

2. **Access Control**
   - Use `@QuantaVisibleTo` for field-level access control
   - Implement proper role-based access control
   - Regularly audit access permissions

3. **Validation**
   - Always validate input data
   - Use appropriate validation rules
   - Consider custom validators for complex rules

4. **Storage**
   - Let QuantaDB handle secure storage locations
   - Don't store sensitive data in insecure locations
   - Regularly backup encrypted data

5. **Audit Logging**
   - Enable audit logging for sensitive operations
   - Regularly review audit logs
   - Implement log rotation and retention policies 