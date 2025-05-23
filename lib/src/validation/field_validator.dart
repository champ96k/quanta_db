import 'package:quanta_db/annotations/quanta_annotations.dart';

/// Validates field values based on annotations
class FieldValidator {
  FieldValidator();

  /// Validates a field value against its annotations
  static String? validate(dynamic value, List<dynamic> annotations) {
    for (final annotation in annotations) {
      if (annotation is QuantaField) {
        // Check required field
        if (annotation.required && value == null) {
          return 'Field is required';
        }

        // Check custom validator
        if (annotation.validator != null) {
          final result =
              (annotation.validator as String? Function(dynamic))(value);
          if (result != null) {
            return result;
          }
        }

        // Apply default value if needed
        if (value == null && annotation.defaultValue != null) {
          value = annotation.defaultValue;
        }
      }
    }
    return null;
  }

  /// Validates a string field
  static String? validateString(String? value, List<dynamic> annotations) {
    for (final annotation in annotations) {
      if (annotation is QuantaField) {
        // Check required field
        if (annotation.required && (value == null || value.isEmpty)) {
          return 'Field is required';
        }

        // Check custom validator
        if (annotation.validator != null) {
          final result =
              (annotation.validator as String? Function(dynamic))(value);
          if (result != null) {
            return result;
          }
        }

        // Apply default value if needed
        if ((value == null || value.isEmpty) &&
            annotation.defaultValue != null) {
          value = annotation.defaultValue as String;
        }
      }
    }
    return null;
  }

  /// Validates a numeric field
  static String? validateNumber(num? value, List<dynamic> annotations) {
    for (final annotation in annotations) {
      if (annotation is QuantaField) {
        // Check required field
        if (annotation.required && value == null) {
          return 'Field is required';
        }

        // Check custom validator
        if (annotation.validator != null) {
          final result =
              (annotation.validator as String? Function(dynamic))(value);
          if (result != null) {
            return result;
          }
        }

        // Apply default value if needed
        if (value == null && annotation.defaultValue != null) {
          value = annotation.defaultValue as num;
        }
      }
    }
    return null;
  }

  /// Validates a boolean field
  static String? validateBoolean(
      {bool? value, required List<dynamic> annotations}) {
    for (final annotation in annotations) {
      if (annotation is QuantaField) {
        // Check required field
        if (annotation.required && value == null) {
          return 'Field is required';
        }

        // Check custom validator
        if (annotation.validator != null) {
          final result =
              (annotation.validator as String? Function(dynamic))(value);
          if (result != null) {
            return result;
          }
        }

        // Apply default value if needed
        if (value == null && annotation.defaultValue != null) {
          value = annotation.defaultValue as bool;
        }
      }
    }
    return null;
  }
}
