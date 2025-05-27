/// Annotation to mark a class as a QuantaDB entity
class QuantaEntity {
  const QuantaEntity({this.version = 1});

  /// The schema version of this entity
  final int version;
}

/// Annotation to mark a field as the primary key
class QuantaId {
  const QuantaId();
}

/// Annotation to mark a field as indexed
class QuantaIndex {
  const QuantaIndex({
    this.name,
    this.unique = false,
    this.order = IndexOrder.ascending,
  });

  /// Optional name for the index
  final String? name;

  /// Whether this index should enforce uniqueness
  final bool unique;

  /// The sort order for this index
  final IndexOrder order;
}

/// Sort order for indexes
enum IndexOrder {
  /// Ascending order
  ascending,

  /// Descending order
  descending,
}

/// Annotation to mark a composite index
class QuantaCompositeIndex {
  const QuantaCompositeIndex({
    required this.fields,
    this.name,
    this.unique = false,
  });

  /// The fields that make up this composite index
  final List<String> fields;

  /// Optional name for the index
  final String? name;

  /// Whether this index should enforce uniqueness
  final bool unique;
}

/// Annotation to mark a one-to-many relationship
class QuantaHasMany {
  const QuantaHasMany({
    required this.targetEntity,
    this.foreignKey,
    this.cascade = false,
  });

  /// The target entity class
  final Type targetEntity;

  /// The foreign key field name in the target entity
  final String? foreignKey;

  /// Whether to cascade delete/update operations
  final bool cascade;
}

/// Annotation to mark a many-to-many relationship
class QuantaManyToMany {
  const QuantaManyToMany({
    required this.targetEntity,
    this.joinTable,
    this.cascade = false,
  });

  /// The target entity class
  final Type targetEntity;

  /// The name of the join table
  final String? joinTable;

  /// Whether to cascade delete/update operations
  final bool cascade;
}

/// Annotation to mark a field as encrypted
///
/// When applied to a field, this annotation indicates that the field's value
/// should be encrypted at rest. The encryption is handled automatically by
/// QuantaDB using the configured encryption algorithm.
///
/// Example:
/// ```dart
/// class User {
///   @QuantaEncrypted()
///   final String password;
///
///   User({required this.password});
/// }
/// ```
class QuantaEncrypted {
  const QuantaEncrypted();
}

/// Annotation to mark a field as reactive
class QuantaReactive {
  const QuantaReactive();
}

/// Annotation to mark a field as ignored in serialization
class QuantaIgnore {
  const QuantaIgnore();
}

/// Annotation to specify field options
class QuantaField {
  const QuantaField({
    this.required = false,
    this.defaultValue,
    this.validator,
    this.min,
    this.max,
    this.pattern,
    this.customValidator,
  });

  /// Whether this field is required
  final bool required;

  /// Default value for this field
  final dynamic defaultValue;

  /// Built-in validator type
  final String? validator;

  /// Minimum value for numeric fields
  final num? min;

  /// Maximum value for numeric fields
  final num? max;

  /// Regular expression pattern for string fields
  final String? pattern;

  /// Custom validation function
  final Function? customValidator;
}
