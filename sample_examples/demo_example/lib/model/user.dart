import 'package:quanta_db/quanta_db.dart';

part 'user.quanta.g.dart';

@QuantaEntity(version: 1)
class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.lastLogin,
    this.userType,
    this.roles = const [],
  });

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

  final UserType? userType;
  final List<String> roles;
}

enum UserType {
  admin,
  user,
}
