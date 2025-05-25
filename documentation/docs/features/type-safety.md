---
sidebar_position: 10
---

:::caution Coming Soon
This section is currently under development.
:::

# Type Safety

QuantaDB emphasizes type safety, providing a robust development experience by allowing you to work with your data using strong types. This reduces the likelihood of runtime errors related to incorrect data types and improves code maintainability.

Type safety in QuantaDB is primarily achieved through **annotation-driven code generation**. You define your data models using Dart classes and annotate them with specific QuantaDB annotations. A build runner then automatically generates code that handles the serialization and deserialization of your objects to and from the database's storage format (DartBson).

This generated code ensures that when you read data from the database, it is correctly mapped back to your defined Dart classes, and when you write data, your Dart objects are properly converted for storage.

This approach provides compile-time checks for your data models and database operations, giving you confidence in the type correctness of your code.

Here's a simplified example illustrating the concept:

```dart
import 'package:quanta_db/quanta_db.dart'; // Assuming necessary imports
import 'package:quanta_db/annotations.dart'; // Assuming annotations import

part 'my_data_models.g.dart'; // Generated file

// Define your data model using annotations
@QuantaEntity()
class User {
  @QuantaKey()
  final String id;
  final String name;
  final int age;

  User({required this.id, required this.name, required this.age});

  // Constructor for the generated code
  factory User.fromQuanta(Map<String, dynamic> json) => _\$UserFromQuanta(json);

  // Method for the generated code
  Map<String, dynamic> toQuanta() => _\$UserToQuanta(this);
}

// Example of using type-safe operations
void exampleUsage(QuantaDB db) async {
  final user = User(id: '123', name: 'Alice', age: 30);

  // Type-safe put operation
  await db.put<User>(user.id, user); // Use the User type argument

  // Type-safe get operation
  final retrievedUser = await db.get<User>(user.id); // Use the User type argument

  if (retrievedUser != null) {
    print('Retrieved user: ${retrievedUser.name}, Age: ${retrievedUser.age}');
    // You can directly access properties with confidence in their types
    int userAge = retrievedUser.age; // userAge is an int
  }
}
```

This example demonstrates how defining a `User` class with annotations allows QuantaDB to handle the storage and retrieval in a type-safe manner. The generated code (`my_data_models.g.dart`) would contain the actual serialization and deserialization logic.

Refer to the dedicated Code Generation and Schema definition sections for detailed instructions on setting up code generation and defining your data models with annotations.
 