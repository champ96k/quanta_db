import 'package:quanta_db/annotations/quanta_annotations.dart';
import 'package:quanta_db/src/serialization/model_serializer.dart';

part 'user.g.dart';

@QuantaEntity()
class User implements Serializable {
  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        email = json['email'] as String,
        password = json['password'] as String,
        isActive = json['isActive'] as bool,
        tempSessionToken = json['tempSessionToken'] as String? ?? '';
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.isActive,
    this.tempSessionToken = '',
  });

  @QuantaId()
  final String id;

  @QuantaField()
  final String name;

  @QuantaField()
  @QuantaIndex()
  final String email;

  @QuantaField()
  @QuantaEncrypted()
  final String password;

  @QuantaField()
  @QuantaReactive()
  bool isActive;

  @QuantaIgnore()
  String tempSessionToken;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isActive': isActive,
      'tempSessionToken': tempSessionToken,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isActive: $isActive)';
  }
}
