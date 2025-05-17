// ignore_for_file: avoid_print

import 'package:quanta_db/quanta_db.dart';
import 'package:quanta_db/src/serialization/model_serializer.dart';

import 'user.dart';

void main() async {
  // Create a new database instance
  final db = QuantaDB('data');

  try {
    // Initialize the database
    await db.init();

    // Register the User model serializer
    db.registerSerializer(ModelSerializer<User>(User.fromJson));

    // Store different types of data
    await db.put<String>('name', 'John Doe');
    await db.put<int>('age', 30);
    await db.put<String>('city', 'New York');
    await db.put<bool>('isActive', true);
    await db.put<double>('score', 95.5);

    // Store a model
    final user = User(
      id: '1',
      name: 'Jane Doe',
      email: 'jane@example.com',
      password: 'secret',
      isActive: true,
    );
    await db.put<User>('user', user);

    // Retrieve and print all data
    print('String: [32m${await db.get<String>('name')}[0m');
    print('Int: [32m${await db.get<int>('age')}[0m');
    print('String: [32m${await db.get<String>('city')}[0m');
    print('Bool: [32m${await db.get<bool>('isActive')}[0m');
    print('Double: [32m${await db.get<double>('score')}[0m');
    print('User: [32m${await db.get<User>('user')}[0m');

    // Update data
    await db.put<int>('age', 31);
    print('Updated Age: [33m${await db.get<int>('age')}[0m');

    // Delete data
    await db.delete('city');
    print('Deleted City: [31m${await db.get<String>('city')}[0m');
  } finally {
    // Always close the database when done
    await db.close();
  }
}
