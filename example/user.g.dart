// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// QuantaGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:quanta_db/src/encryption/aes_encryption.dart';

class UserAdapter {
  static const int schemaVersion = 1;
  static String? validate(User instance) {
    final errors = <String, String>{};

    final idError = FieldValidator.validateString(instance.id, [QuantaId ()]);
    if (idError != null) {
      errors['id'] = idError;
    }

    final nameError = FieldValidator.validateString(instance.name, [QuantaField (defaultValue = Null (null); required = bool (false); validator = Null (null))]);
    if (nameError != null) {
      errors['name'] = nameError;
    }

    final emailError = FieldValidator.validateString(instance.email, [QuantaField (defaultValue = Null (null); required = bool (false); validator = Null (null)), QuantaIndex ()]);
    if (emailError != null) {
      errors['email'] = emailError;
    }

    final isActiveError = FieldValidator.validateBoolean(instance.isActive, [QuantaField (defaultValue = Null (null); required = bool (false); validator = Null (null)), QuantaIndex (), QuantaReactive ()]);
    if (isActiveError != null) {
      errors['isActive'] = isActiveError;
    }

    final lastLoginError = FieldValidator.validate(instance.lastLogin, [QuantaField (defaultValue = Null (null); required = bool (false); validator = Null (null)), QuantaIndex (), QuantaReactive ()]);
    if (lastLoginError != null) {
      errors['lastLogin'] = lastLoginError;
    }

    return errors.isEmpty ? null : errors.toString();
  }

  static Future<Map<String, dynamic>> toJson(User instance) async {
    final validationError = validate(instance);
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    return {
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'isActive': instance.isActive,
      'lastLogin': instance.lastLogin,
    };
  }
  static Future<User> fromJson(Map<String, dynamic> json) async => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    isActive: json['isActive'] as bool,
    lastLogin: json['lastLogin'] as DateTime,
  );
}


class UserDao {
  final _db; // TODO: Inject your database instance
  UserDao(this._db);
  int get schemaVersion => UserAdapter.schemaVersion;

  Future<void> insert(User instance) async {
    final json = await UserAdapter.toJson(instance);
    await _db.put('${instance.id}', json);
  }

  Future<User?> getById(String id) async {
    final json = await _db.get<Map<String, dynamic>>(id);
    if (json == null) return null;
    return await UserAdapter.fromJson(json);
  }

  Future<List<User>> getAll() async {
    final items = await _db.getAll<Map<String, dynamic>>();
    return items
        .where((item) => item.keys.first.startsWith('user:'))
        .map((item) => await UserAdapter.fromJson(item.values.first))
        .toList();
  }

  Future<void> update(User instance) async {
    final json = await UserAdapter.toJson(instance);
    await _db.put('${instance.id}', json);
  }

  Future<void> delete(String id) async {
    await _db.delete(id);
  }

}
