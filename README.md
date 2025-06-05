# QuantaDB

[![Pub Version](https://img.shields.io/pub/v/quanta_db.svg)](https://pub.dev/packages/quanta_db)
[![License](https://img.shields.io/github/license/champ96k/quanta_db)](https://github.com/champ96k/quanta_db/blob/master/LICENSE)
[![Dart CI](https://github.com/champ96k/quanta_db/actions/workflows/dart.yml/badge.svg)](https://github.com/champ96k/quanta_db/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/champ96k/quanta_db/branch/master/graph/badge.svg)](https://codecov.io/gh/champ96k/quanta_db)
[![Documentation](https://img.shields.io/badge/Documentation-API-blue)](https://quantadb.netlify.app/)

> ⚠️ **BETA RELEASE**  
> This project is currently in **beta**. While it's functional and available for use, it may still undergo changes. Please use with caution in production environments and report any bugs or issues.

📚 **Documentation**: Visit our [documentation site](https://quantadb.netlify.app/) for detailed guides and API references.

A high-performance, type-safe NoSQL database for Dart and Flutter applications.

<p align="center">
  <img src="https://raw.githubusercontent.com/champ96k/quanta_db/master/logo.png" alt="QuantaDB Logo" width="400"/>
</p>

## Features

- 🚀 **Performance**: Optimized for speed with LSM-Tree storage
- 🔒 **Type Safety**: Compile-time type checking and validation
- 🔄 **Reactive**: Real-time data synchronization
- 📊 **Query Engine**: Powerful querying capabilities
- 🔄 **Transactions**: ACID-compliant transactions
- 📈 **Scalability**: Efficient handling of large datasets
- 🛠 **Developer Experience**: Annotation-driven code generation
- 🔄 **Schema Migrations**: Automatic schema version management
- ✅ **Field Validation**: Built-in validation with custom rules
- 🔐 **Access Control**: Field-level visibility control
- 🔄 **Relationships**: Support for one-to-many and many-to-many relationships

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  quanta_db: ^0.0.5
```

You can install packages from the command line:

```bash
$ dart pub get
```

## Quick Start

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

## Usage

### Basic Operations

```dart
// Open database
final db = await QuantaDB.open('my_database');

// Put data
await db.put('key', {'name': 'value'});

// Get data
final data = await db.get('key');

// Delete data
await db.delete('key');

// Close database
await db.close();
```

### Using Annotations

QuantaDB provides a rich set of annotations for defining your data models:

#### Entity Annotations

```dart
@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;

  @QuantaField(required: true)
  final String name;
}
```

#### Index Annotations

```dart
@QuantaIndex()
final String email;

@QuantaCompositeIndex(fields: ['firstName', 'lastName'])
final String fullName;
```

#### Relationship Annotations

```dart
@QuantaHasMany(targetEntity: Post, foreignKey: 'userId')
final List<Post> posts;

@QuantaManyToMany(targetEntity: Group)
final List<Group> groups;
```

### Type Support

The code generator supports a comprehensive range of data types:

#### Primitive Types

```dart
final String name;
final int age;
final double score;
final bool isActive;
final DateTime createdAt;
```

#### Complex Types

```dart
final List<String> tags;
final Map<String, dynamic> metadata;
final Set<String> permissions;
```

#### Enums

```dart
enum UserType { admin, user, guest }

final UserType? userType;
```

### Field Validation

```dart
@QuantaField(
  required: true,
  min: 0,
  max: 120,
  pattern: r'^[a-zA-Z]+$'
)
final String name;
```

### Reactive Fields

```dart
@QuantaReactive()
final DateTime lastLogin;

// Watch for changes
final queryEngine = QueryEngine(db.storage);
final stream = queryEngine.watch<User, User>(
  Query<User>().where((user) => user.lastLogin != null)
);
await for (final user in stream) {
  print('User logged in at: ${user.lastLogin}');
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

**As you can see, QuantaDB demonstrates significantly faster performance across all operations.**

**[Check out the benchmark code here](https://github.com/champ96k/quanta_db/blob/master/example/demo_example/lib/complete_example.dart)** to run it yourself and see the details.

## Why QuantaDB?

Existing local databases for Dart/Flutter often have external dependencies or performance limitations. QuantaDB aims to overcome these challenges by implementing a Log-Structured Merge Tree (LSM-Tree) storage engine from scratch in pure Dart, coupled with an annotation-driven code generation system for a developer-friendly experience.

Our goals include:

- Achieving competitive read and write performance.
- Providing a simple and intuitive API.
- Ensuring data durability and consistency.
- Supporting complex data models with relationships and indexing.
- Offering a reactive query system for real-time updates.

## Architecture

QuantaDB is built with a layered architecture to separate concerns and improve maintainability. The core of the database is the LSM-Tree storage engine.

### High-Level Architecture

Below is a high-level overview of the QuantaDB architecture:

![QuantaDB High-Level Architecture](https://raw.githubusercontent.com/champ96k/quanta_db/master/design_diagram.png)

- **Application Layer**: Provides the public API and integrates with the annotation and code generation systems.
- **Core Engine Layer**: Contains the central logic for query processing, LSM storage management, and transactions.
- **Storage Layer**: Implements the core storage components like MemTable, SSTable Manager, Bloom Filters, and Compaction.
- **Platform Layer**: Interacts with the underlying file system and utilizes isolate workers for background tasks.

### Data Flow

Here's a diagram illustrating the typical data flow within QuantaDB:

![QuantaDB Data Flow](https://raw.githubusercontent.com/champ96k/quanta_db/master/design_flow.png)

- Data enters through the API.
- Queries are processed by the Query Engine.
- Write operations go through the MemTable and are eventually flushed to SSTables.
- Read operations utilize Bloom Filters and the MemTable before hitting SSTables.
- Compaction runs in the background to merge and optimize SSTables.

## Additional Information

- [Documentation](https://quantadb.netlify.app/)
- [API Reference](https://pub.dev/documentation/quanta_db/latest/)
- [GitHub Repository](https://github.com/champ96k/quanta_db)
- [Issue Tracker](https://github.com/champ96k/quanta_db/issues)
- [Discussions](https://github.com/champ96k/quanta_db/discussions)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- **Tushar Nikam** - [LinkedIn](https://www.linkedin.com/in/tushar-nikam-dev/)

## Contributors

### Code Contributors
<a href="https://github.com/champ96k/quanta_db/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=champ96k/quanta_db" />
</a>

### Issue Contributors
<a href="https://github.com/champ96k/quanta_db/issues">
  <img src="https://img.shields.io/github/issues/champ96k/quanta_db" alt="Total Issues" />
</a>

<a href="https://github.com/champ96k/quanta_db/issues?q=is%3Aissue+is%3Aclosed">
  <img src="https://img.shields.io/github/issues-closed/champ96k/quanta_db" alt="Closed Issues" />
</a>

<a href="https://github.com/champ96k/quanta_db/issues">
  <img src="https://img.shields.io/github/issues-open/champ96k/quanta_db" alt="Open Issues" />
</a>

<br>

> View all contributors and their issues on our [GitHub Issues page](https://github.com/champ96k/quanta_db/issues)

---

Made with ❤️ by the QuantaDB Team

![Visitor Count](https://visitor-badge.laobi.icu/badge?page_id=champ96k.quanta_db)
