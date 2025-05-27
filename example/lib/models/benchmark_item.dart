import 'package:uuid/uuid.dart';

class BenchmarkItem {
  final String id;
  final String name;
  final int value;
  final DateTime createdAt;

  BenchmarkItem({
    String? id,
    required this.name,
    required this.value,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'value': value,
        'createdAt': createdAt.toIso8601String(),
      };

  static BenchmarkItem fromMap(Map<String, dynamic> map) => BenchmarkItem(
        id: map['id'] as String?,
        name: map['name'] as String,
        value: map['value'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
