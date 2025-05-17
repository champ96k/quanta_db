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
  const QuantaIndex();
}

/// Annotation to mark a field as encrypted
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
  });

  /// Whether this field is required
  final bool required;

  /// Default value for this field
  final dynamic defaultValue;

  /// Custom validation function
  final Function? validator;
}
