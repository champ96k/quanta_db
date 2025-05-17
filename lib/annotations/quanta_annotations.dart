/// Marks a class as a database entity (table/collection)
class QuantaEntity {
  const QuantaEntity();
}

/// Customizes field behavior (e.g., index, encrypted, ignore)
class QuantaField {
  const QuantaField();
}

/// Marks the primary key field
class QuantaId {
  const QuantaId();
}

/// Creates a secondary index
class QuantaIndex {
  const QuantaIndex();
}

/// Enables encryption for sensitive fields
class QuantaEncrypted {
  const QuantaEncrypted();
}

/// Excludes a field from persistence
class QuantaIgnore {
  const QuantaIgnore();
}

/// Makes the entity/field observable for reactive updates
class QuantaReactive {
  const QuantaReactive();
}
