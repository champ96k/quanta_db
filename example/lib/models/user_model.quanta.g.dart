// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: prefer_const_declarations

part of 'user_model.dart';

// **************************************************************************
// QuantaGenerator
// **************************************************************************

// **************************************************************************
// QuantaGenerator
// **************************************************************************

extension UserJsonExtension on User {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  String toDebugString() {
    final fields = [
      'id: $id',
      'name: $name',
    ].join(", ");
    return "User($fields)";
  }
}

// **************************************************************************
// QuantaGenerator
// **************************************************************************

class UserAdapter {
  static const int schemaVersion = 1;
  static String? validate(User instance) {
    final errors = <String, String>{};

    final idError = FieldValidator.validateString(instance.id, []);
    if (idError != null) {
      errors['id'] = idError;
    }

    final nameError = FieldValidator.validateString(instance.name, []);
    if (nameError != null) {
      errors['name'] = nameError;
    }

    return errors.isEmpty ? null : errors.toString();
  }

  static Future<Map<String, dynamic>> toJson(User instance) async {
    final validationError = validate(instance);
    if (validationError != null) {
      throw ValidationException(validationError);
    }
    return instance.toJson();
  }

  static Future<User> fromJson(Map<String, dynamic> json) async {
    return UserJsonExtension.fromJson(json);
  }
}

class UserDao {
  final QuantaDB _db;
  UserDao(this._db);
  int get schemaVersion => UserAdapter.schemaVersion;

  Future<void> insert(User instance) async {
    final json = await UserAdapter.toJson(instance);
    String id = instance.id;

    // Handle auto-generated IDs
    if (id.isEmpty) {
      final entityPrefix = 'user_';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      id = entityPrefix + timestamp.toString();
    }

    await _db.put(id, json);
  }

  Future<User?> getById(String id) async {
    final json = await _db.get<Map<String, dynamic>>(id);
    if (json == null) return null;
    return await UserAdapter.fromJson(json);
  }

  Future<List<User>> getAll() async {
    final items = await _db.queryEngine
        .query<Map<String, dynamic>>(Query<Map<String, dynamic>>());
    final filtered =
        items.where((item) => item.keys.first.startsWith('user:')).toList();
    return Future.wait(
        filtered.map((item) => UserAdapter.fromJson(item.values.first)));
  }

  Future<void> update(User instance) async {
    final json = await UserAdapter.toJson(instance);
    await _db.put(instance.id, json);
  }

  Future<void> delete(String id) async {
    await _db.delete(id);
  }
}
