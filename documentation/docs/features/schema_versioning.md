---
id: schema_versioning
title: Schema Versioning
sidebar_position: 6
---

# Schema Versioning

QuantaDB provides automatic schema versioning and migration support through its code generation system.

## Basic Usage

Simply specify the version in your `@QuantaEntity` annotation:

```dart
@QuantaEntity(version: 1)
class User {
  final String id;
  final String name;
  final String email;
}
```

When you need to make changes, increment the version:

```dart
@QuantaEntity(version: 2)
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;  // New field
}
```

## Automatic Migrations

QuantaDB automatically handles schema changes:

1. **Field Additions**: New fields are added with their default values
2. **Field Removals**: Removed fields are safely dropped
3. **Type Changes**: Type conversions are handled automatically
4. **Index Updates**: Indexes are updated to reflect schema changes

## Migration Process

1. **Version Detection**: QuantaDB detects schema version changes
2. **Schema Analysis**: Changes are analyzed automatically
3. **Migration Generation**: Migration code is generated
4. **Data Migration**: Data is migrated to the new schema
5. **Version Update**: Schema version is updated

## Example

```dart
// Version 1
@QuantaEntity(version: 1)
class User {
  final String id;
  final String name;
  final String email;
}

// Version 2 - Adding a new field
@QuantaEntity(version: 2)
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;  // New optional field
}

// Version 3 - Modifying a field
@QuantaEntity(version: 3)
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;  // New required field
}
```

## Migration Features

- **Automatic Version Tracking**: Schema versions are tracked automatically
- **Safe Migrations**: All migrations are performed safely with rollback support
- **Type Safety**: Migrations are type-safe and validated at compile time
- **Performance**: Migrations are optimized for performance
- **Atomic Operations**: All migrations are atomic

## Best Practices

1. **Version Management**
   - Increment version for any schema changes
   - Document changes in version comments
   - Test migrations thoroughly

2. **Field Changes**
   - Add new fields as nullable when possible
   - Provide default values for required fields
   - Consider backward compatibility

3. **Migration Testing**
   - Test migrations with real data
   - Verify data integrity after migration
   - Test rollback scenarios

4. **Performance**
   - Migrate data in batches for large datasets
   - Schedule migrations during low-usage periods
   - Monitor migration progress

## Limitations

- Migrations must be sequential
- Complex schema changes may require manual intervention
- Large datasets may take time to migrate

## Future Enhancements

- Parallel migration support
- Custom migration scripts
- Migration preview and validation
- Migration progress tracking