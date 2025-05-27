---
id: schema-versioning-examples
title: Schema Versioning Code Examples
sidebar_label: Code Examples
sidebar_position: 2
description: Learn how to use QuantaDB's automatic schema versioning with minimal code
---

# Schema Versioning Code Examples

This document shows the minimal code you need to write to use QuantaDB's schema versioning system.

## Basic Usage

### 1. Define Your Model

```dart
import 'package:quanta_db/quanta_db.dart';

@QuantaEntity
class User {
  final String id;
  final String name;
  final String email;
  
  User({
    required this.id,
    required this.name,
    required this.email,
  });
}
```

### 2. Add a New Field

```dart
@QuantaEntity
class User {
  final String id;
  final String name;
  final String email;
  final int age;  // New field added
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,  // Added to constructor
  });
}
```

That's it! QuantaDB automatically:
- Detects the new field
- Generates the migration
- Updates the schema
- Handles data migration

## Common Scenarios

### Adding an Index

```dart
@QuantaEntity
class User {
  @Index  // Add this annotation
  final String email;
  
  // ... other fields
}
```

### Making a Field Optional

```dart
@QuantaEntity
class User {
  final String? phone;  // Make it nullable
  
  // ... other fields
}
```

### Adding Validation

```dart
@QuantaEntity
class User {
  @ValidateEmail  // Add validation
  final String email;
  
  // ... other fields
}
```

## Best Practices

1. **Model Design**
   ```dart
   @QuantaEntity
   class User {
     // Use final fields
     final String id;
     
     // Use proper types
     final DateTime createdAt;
     
     // Use nullable for optional fields
     final String? middleName;
   }
   ```

2. **Field Types**
   ```dart
   @QuantaEntity
   class Product {
     // Use appropriate types
     final int quantity;
     final double price;
     final bool inStock;
     final List<String> tags;
     final Map<String, dynamic> metadata;
   }
   ```

3. **Relationships**
   ```dart
   @QuantaEntity
   class Order {
     final String id;
     final String userId;  // Reference to User
     final List<String> productIds;  // References to Products
   }
   ```

## What You Don't Need to Write

Remember, you don't need to write:
- Migration files
- Schema version code
- Rollback logic
- Version tracking code
- Migration registry code
- Schema storage code

All of these are handled automatically by QuantaDB.

## Error Handling

QuantaDB handles errors automatically, but you can catch them if needed:

```dart
try {
  // Your model changes
} on SchemaMigrationError catch (e) {
  print('Migration failed: ${e.message}');
}
```

## Performance Tips

1. **Batch Changes**
   ```dart
   // Make all related changes at once
   @QuantaEntity
   class User {
     final String name;
     final String email;
     final String phone;
   }
   ```

2. **Use Proper Types**
   ```dart
   @QuantaEntity
   class Product {
     // Use specific types instead of dynamic
     final int stock;
     final double price;
     final List<String> categories;
   }
   ```

## Common Patterns

### Adding Timestamps

```dart
@QuantaEntity
class Post {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Soft Delete

```dart
@QuantaEntity
class Comment {
  final String id;
  final String content;
  final bool isDeleted;
  final DateTime? deletedAt;
}
```

### Version Tracking

```dart
@QuantaEntity
class Document {
  final String id;
  final String content;
  final int version;
  final DateTime lastModified;
}
```

Remember: All migrations, version tracking, and schema updates are handled automatically by QuantaDB. You only need to focus on your model design. 