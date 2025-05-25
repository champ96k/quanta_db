---
sidebar_position: 3
---

# Usage

This section covers the basic usage of QuantaDB.

Import the package and open a database. QuantaDB automatically handles platform-specific secure directory management for both Flutter and pure Dart environments.

```dart
import 'package:quanta_db/quanta_db.dart';

void main() async {
  // Open the database
  // The database files will be stored in a platform-specific secure location
  final db = await QuantaDB.open('my_database');

  // Put some data
  await db.put('my_key', {'name': 'Quanta', 'version': 1.0});

  // Get data
  final data = await db.get('my_key');
  print('Retrieved data: $data');

  // Update data
  await db.put('my_key', {'name': 'QuantaDB', 'version': 1.1});
  final updatedData = await db.get('my_key');
  print('Updated data: $updatedData');

  // Delete data
  await db.delete('my_key');
  final deletedData = await db.get('my_key');
  print('Deleted data: $deletedData');

  // Close the database
  await db.close();
}
```

**Tips:**

* QuantaDB is a **NoSQL** database, using a key-value store model based on LSM-Trees.
* Data is stored using a custom binary serialization format (DartBson).
* Directory management is handled automatically for different platforms, ensuring secure storage locations. 