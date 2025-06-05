---
sidebar_position: 1
---

# Introduction

[![Pub Version](https://img.shields.io/pub/v/quanta_db.svg)](https://pub.dev/packages/quanta_db)
[![License](https://img.shields.io/github/license/champ96k/quanta_db)](https://github.com/champ96k/quanta_db/blob/master/LICENSE)
[![Dart CI](https://github.com/champ96k/quanta_db/actions/workflows/dart.yml/badge.svg)](https://github.com/champ96k/quanta_db/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/champ96k/quanta_db/branch/master/graph/badge.svg)](https://codecov.io/gh/champ96k/quanta_db)
[![Documentation](https://img.shields.io/badge/Documentation-API-blue)](https://quantadb.netlify.app/)

> ⚠️ **BETA RELEASE**  
> This project is currently in **beta**. While it's functional and available for use, it may still undergo changes. Please use with caution in production environments and report any bugs or issues.

QuantaDB is a modern, high-performance NoSQL local database built entirely in Dart. It is designed to be a fast, reliable, and easy-to-use data storage solution for both Flutter applications and pure Dart projects.

Built from scratch with a focus on performance and developer experience, QuantaDB leverages a Log-Structured Merge Tree (LSM-Tree) storage engine and annotation-driven code generation.

## Key Features ✨

- **High Performance**: LSM-Tree based storage engine optimized for speed
- **Data Security**: Built-in encryption support for sensitive data
- **Advanced Indexing**: Support for single, composite, and unique indexes
- **Real-time Updates**: Reactive queries with change notifications
- **Type Safety**: Strong typing with code generation
- **Cross-Platform**: Works on all platforms supported by Dart/Flutter
- **Query Engine**: Powerful query capabilities with filtering and sorting
- **Transaction Support**: ACID compliant transactions
- **Scalability**: Efficient handling of large datasets
- **Developer Experience**: Annotation-driven code generation
- **Schema Migrations**: Automatic schema version management
- **Field Validation**: Built-in validation with custom rules
- **Access Control**: Field-level visibility control
- **Relationships**: Support for one-to-many and many-to-many relationships

## Why Choose QuantaDB?

QuantaDB aims to overcome the limitations of existing local databases by providing a pure Dart implementation with a high-performance LSM-Tree engine. Our goals are to offer:

- Competitive read and write performance
- Simple and intuitive API
- Data durability and consistency
- Support for complex data models with relationships and indexing
- Reactive query system for real-time updates

## Architecture

QuantaDB features a layered architecture:

- **Application Layer**: Public API and code generation integration
- **Core Engine Layer**: Query processing and LSM storage management
- **Storage Layer**: MemTable, SSTable Manager, Bloom Filters, and Compaction
- **Platform Layer**: File system interaction and background tasks

## Getting Started

To start using QuantaDB, add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  quanta_db: ^0.0.6 # Use the latest version
```

Then, run `dart pub get` or `flutter pub get`.

Import the package and open your database:

```dart
import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Open the database
  final db = await QuantaDB.open('my_database');

  // Define your model
  @QuantaEntity(version: 1)
  class User {
    @QuantaId()
    final String id;

    @QuantaField(required: true)
    final String name;

    @QuantaIndex()
    final String email;

    User({required this.id, required this.name, required this.email});
  }

  // Insert data
  final user = User(id: '1', name: 'John', email: 'john@example.com');
  await db.put('user:1', user);

  // Query data
  final queryEngine = QueryEngine(db.storage);
  final users = await queryEngine.query<User>(
    Query<User>().where((user) => user.name.startsWith('J'))
  );
  print('Users: $users');

  // Close the database
  await db.close();
}
```

## Performance

QuantaDB is designed for speed. Here are benchmark results comparing QuantaDB's performance for 10,000 operations:

| Operation | QuantaDB | Hive  | SQLite |
| --------- | -------- | ----- | ------ |
| Write     | 30ms     | 216ms | 3290ms |
| Read      | 9ms      | 8ms   | 299ms  |
| Batch     | 15ms     | 180ms | 2800ms |
| Query     | 25ms     | 45ms  | 150ms  |

[Check out the benchmark code](https://github.com/champ96k/quanta_db/blob/master/example/demo_example/lib/complete_example.dart) to run it yourself.

## Contributing and Support

We welcome contributions! Please see the [CONTRIBUTING.md](https://github.com/champ96k/quanta_db/blob/master/CONTRIBUTING.md) for details.

If you need help, check the [Issue Tracker](https://github.com/champ96k/quanta_db/issues) or [Discussions](https://github.com/champ96k/quanta_db/discussions) on GitHub.
