---
id: schema-versioning
title: Schema Versioning
sidebar_label: Schema Versioning
sidebar_position: 1
description: Automatic schema versioning and migration system
---

# Schema Versioning

> **Important Note**: You don't need to write any migration code manually! The schema versioning system is fully automated. When you make changes to your model classes, QuantaDB automatically:
> - Detects schema changes
> - Generates appropriate migration files
> - Manages version tracking
> - Handles rollbacks
> - Manages the migration registry
> - Handles schema storage
> - Builds migrations
> 
> The examples below are for understanding how the system works internally, but in practice, you'll never need to write any of this code yourself.

QuantaDB provides a robust schema versioning system that automatically manages database schema evolution through migrations.

## Overview

The schema versioning system automatically:
- Tracks schema changes over time
- Generates migration files
- Executes migrations in sequence
- Rolls back to previous versions
- Maintains migration history
- Manages migrations through a central registry

## How It Works Internally

> **Note**: The following sections explain how the system works internally. You don't need to write any of this code - it's all handled automatically by QuantaDB.

### 1. SchemaVersionManager

The core class that manages everything internally:

```dart
// Internal implementation - you don't need to write this
class SchemaVersionManager {
  final SchemaStorage _storage;
  
  // All version management is handled automatically
  Future<void> migrateTo(int version) async {
    // Automatic migration logic
  }
}
```

### 2. Migration Registry

The central registry that manages all migrations automatically:

```dart
// Internal implementation - you don't need to write this
class MigrationRegistry {
  static final Map<String, SchemaMigration> _migrations = {};
  
  // Migrations are registered automatically
  static void register(String name, SchemaMigration migration) {
    _migrations[name] = migration;
  }
}
```

### 3. Schema Storage

The storage layer that handles all schema persistence:

```dart
// Internal implementation - you don't need to write this
class SchemaStorage {
  final LSMStorage _storage;
  
  // All schema storage is handled automatically
  Future<void> putSchema(String table, Map<String, dynamic> schema) async {
    await _storage.put('$table:schema', schema);
  }
}
```

### 4. Migration Builder

The system that automatically generates all migration code:

```dart
// Internal implementation - you don't need to write this
class MigrationBuilder {
  // All migration code is generated automatically
  Future<void> buildMigration(String name, Map<String, dynamic> changes) async {
    // Automatic code generation
  }
}
```

## What You Actually Need to Do

As a developer, you only need to:

1. Define your model classes
2. Make changes to your models when needed
3. Let QuantaDB handle everything else automatically

Example of what you actually write:

```dart
// This is all you need to write
@QuantaEntity
class User {
  final String id;
  final String name;
  final String email;
  
  // Add or modify fields as needed
  // QuantaDB handles all migrations automatically
}
```

## Internal Architecture

> **Note**: The following sections explain the internal architecture. This is all handled automatically by QuantaDB.

### Schema Storage Features
- Persistent schema storage
- Version tracking
- Schema validation
- Change detection
- Atomic operations

### Migration Builder Features
- Automatic code generation
- Schema diff analysis
- Safe migration paths
- Rollback generation
- Type-safe migrations

## Error Handling

The system automatically handles:
- Migration failures
- Rollback procedures
- Version consistency
- Data integrity

## Performance Considerations

Everything is optimized automatically:
- Background migrations
- Optimized version checks
- Cached history queries
- Batched rollback operations

## Limitations

The system automatically handles:
- Sequential migration execution
- Rollback implementation
- Complex schema changes
- Large dataset migrations

## Future Enhancements

Planned automatic improvements:
- Parallel migration execution
- Schema diff visualization
- Migration conflict resolution
- Enhanced rollback capabilities