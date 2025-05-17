// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// QuantaGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

class UserAdapter {
  static Map<String, dynamic> toJson(User instance) => {
        'id': instance.id,
        'name': instance.name,
        'email': instance.email,
        'password': instance.password,
        'isActive': instance.isActive,
        'tempSessionToken': instance.tempSessionToken,
      };
  static User fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        isActive: json['isActive'] as bool,
        tempSessionToken: json['tempSessionToken'] as String,
      );
  static String _encrypt(String value) {
    // TODO: Implement encryption
    return value;
  }

  static String _decrypt(String value) {
    // TODO: Implement decryption
    return value;
  }
}

class UserDao {
  final _db; // TODO: Inject your database instance
  UserDao(this._db);
  Future<void> insert(User instance) async {
    final json = UserAdapter.toJson(instance);
    // TODO: Implement insert with index updates
  }

  Future<User?> getById(String id) async {
    // TODO: Implement getById
    return null;
  }

  Future<List<User>> getAll() async {
    // TODO: Implement getAll
    return [];
  }

  Future<void> update(User instance) async {
    final json = UserAdapter.toJson(instance);
    // TODO: Implement update with index updates
  }

  Future<void> delete(String id) async {
    // TODO: Implement delete with index cleanup
  }
}
