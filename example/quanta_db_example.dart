// ignore_for_file: avoid_print

import 'package:quanta_db/quanta_db.dart';
import 'package:quanta_db/src/serialization/model_serializer.dart';

// Example model class
class User with Serializable {
  final String name;
  final int age;
  final String city;

  User({required this.name, required this.age, required this.city});

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'city': city,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        name: json['name'] as String,
        age: json['age'] as int,
        city: json['city'] as String,
      );

  @override
  String toString() => 'User(name: $name, age: $age, city: $city)';
}

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
    final user = User(name: 'Jane Doe', age: 25, city: 'Los Angeles');
    await db.put<User>('user', user);

    // Retrieve and print all data
    print('String: ${await db.get<String>('name')}');
    print('Int: ${await db.get<int>('age')}');
    print('String: ${await db.get<String>('city')}');
    print('Bool: ${await db.get<bool>('isActive')}');
    print('Double: ${await db.get<double>('score')}');
    print('User: ${await db.get<User>('user')}');

    // Update data
    await db.put<int>('age', 31);
    print('Updated Age: ${await db.get<int>('age')}');

    // Delete data
    await db.delete('city');
    print('Deleted City: ${await db.get<String>('city')}');
  } finally {
    // Always close the database when done
    await db.close();
  }
}
