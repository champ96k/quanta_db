/// Common types for change events across the database
enum ChangeType {
  insert,
  update,
  delete,
  batch,
}

/// Represents a change event in the database
class ChangeEvent {
  ChangeEvent({
    required this.key,
    required this.value,
    required this.type,
    required this.changeType,
  });
  final String key;
  final dynamic value;
  final Type type;
  final ChangeType changeType;
}
