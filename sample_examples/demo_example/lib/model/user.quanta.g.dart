// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

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
      email: json['email'] as String,
      isActive: json['isActive'] as bool,
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      userType: UserType.values.firstWhere((e) => e.name == json['userType']),
      roles: (json['roles'] as List).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isActive': isActive,
      'lastLogin': lastLogin.toIso8601String(),
      'userType': userType?.name,
      'roles': roles,
    };
  }

  String toDebugString() {
    final fields = [
      'id: $id',
      'name: $name',
      'email: $email',
      'isActive: $isActive',
      'lastLogin: $lastLogin',
      'userType: $userType',
      'roles: $roles',
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

    final emailError = FieldValidator.validateString(instance.email, []);
    if (emailError != null) {
      errors['email'] = emailError;
    }

    final isActiveError = FieldValidator.validateBoolean(
        value: instance.isActive, annotations: []);
    if (isActiveError != null) {
      errors['isActive'] = isActiveError;
    }

    final lastLoginError = FieldValidator.validate(instance.lastLogin, []);
    if (lastLoginError != null) {
      errors['lastLogin'] = lastLoginError;
    }

    final userTypeError = FieldValidator.validate(instance.userType, []);
    if (userTypeError != null) {
      errors['userType'] = userTypeError;
    }

    final rolesError = FieldValidator.validate(instance.roles, []);
    if (rolesError != null) {
      errors['roles'] = rolesError;
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
    await _db.put(instance.id, json);
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
