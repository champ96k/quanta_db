/// Annotation to mark a field as encrypted with a specific encryption algorithm
class Encrypted {
  /// Creates a new [Encrypted] annotation with the specified encryption algorithm
  ///
  /// The [algorithm] parameter specifies which encryption algorithm to use
  /// for encrypting the annotated field. Currently supported algorithms:
  /// - "aes-256-gcm": AES-256 encryption in GCM mode
  const Encrypted({required this.algorithm});

  /// The encryption algorithm to use for this field
  final String algorithm;
}
