---
sidebar_position: 1
---

# Introduction

QuantaDB is a modern, high-performance NoSQL local database built entirely in Dart. It is designed to be a fast, reliable, and easy-to-use data storage solution for both Flutter applications and pure Dart projects.

Built from scratch with a focus on performance and developer experience, QuantaDB leverages a Log-Structured Merge Tree (LSM-Tree) storage engine and annotation-driven code generation.

## Key Features ✨

- **High Performance**: LSM-Tree based storage engine optimized for speed.
- **Scalable Architecture**: Seamlessly handle growing amounts of data.
- **Flexible Data Model**: Adapt to changing data structures easily.
- **Reliable and Durable**: Ensuring data safety and availability.
- **Easy Integration**: Effortlessly integrate with your applications.
- **Powerful Query Engine**: Efficient data retrieval, filtering, and sorting.
- **Data Security**: Built-in encryption support.
- **Advanced Indexing**: Support for single and composite indexes.
- **Real-time Updates**: Reactive queries with change notifications.
- **Type Safety**: Strong typing with code generation.
- **Cross-Platform**: Works on all platforms supported by Dart/Flutter.
- **Developer Experience**: Annotation-driven code generation.

## Why Choose QuantaDB?

QuantaDB aims to overcome the limitations of existing local databases by providing a pure Dart implementation with a high-performance LSM-Tree engine. Our goals are to offer competitive read/write performance, a simple API, data durability, support for complex data models, and a reactive query system.

## Performance

QuantaDB is designed for speed. Benchmarks show significantly faster performance compared to other popular Dart/Flutter local databases, especially for write operations. [Check out the benchmark code on GitHub](https://github.com/champ96k/quanta_db#performance-benchmarks--).

## Architecture

QuantaDB features a layered architecture with the core LSM-Tree storage engine. [Learn more about the architecture on GitHub](https://github.com/champ96k/quanta_db#architecture).

## Getting Started

To start using QuantaDB, add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  quanta_db: ^0.0.5 # Use the latest version
```

Then, run `dart pub get` or `flutter pub get`.

Import the package and open your database:

```dart
import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Open the database
  final db = await QuantaDB.open('my_database');

  // Use the database...

  // Close the database when done
  await db.close();
}
```

QuantaDB automatically handles platform-specific secure directory management.

## Contributing and Support

We welcome contributions! Please see the [CONTRIBUTING.md](https://github.com/champ96k/quanta_db/blob/master/CONTRIBUTING.md) for details.

If you need help, check the [Issue Tracker](https://github.com/champ96k/quanta_db/issues) or [Discussions](https://github.com/champ96k/quanta_db/discussions) on GitHub.
