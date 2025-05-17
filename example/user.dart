import 'package:quanta_db/annotations/quanta_annotations.dart';
import 'package:quanta_db/src/serialization/model_serializer.dart';

part 'user.g.dart';

@QuantaEntity()
class User implements Serializable {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.lastLogin,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        email = json['email'] as String,
        isActive = json['isActive'] as bool,
        lastLogin = DateTime.parse(json['lastLogin'] as String);

  @QuantaId()
  final String id;

  @QuantaField()
  final String name;

  @QuantaField()
  @QuantaIndex()
  final String email;

  @QuantaField()
  @QuantaIndex()
  @QuantaReactive()
  final bool isActive;

  @QuantaField()
  @QuantaIndex()
  @QuantaReactive()
  final DateTime lastLogin;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isActive': isActive,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isActive: $isActive, lastLogin: $lastLogin)';
  }
}
