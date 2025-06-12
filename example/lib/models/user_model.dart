import 'package:quanta_db/quanta_db.dart';

part 'user_model.quanta.g.dart';

@QuantaEntity(version: 1)
class User {
  @QuantaId()
  final String id;

  @QuantaField(required: true)
  final String name;

  User({required this.id, required this.name});
}
