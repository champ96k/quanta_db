/// Exception thrown when validation fails
class ValidationException implements Exception {
  /// Creates a new validation exception
  const ValidationException(this.message);

  /// The validation error message
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}
