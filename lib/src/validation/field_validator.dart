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

        // Check min/max for numeric values
        if (value is num) {
          if (annotation.min != null && value < annotation.min!) {
            return 'Value must be greater than or equal to ${annotation.min}';
          }
          if (annotation.max != null && value > annotation.max!) {
            return 'Value must be less than or equal to ${annotation.max}';
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

        // Check pattern if provided
        if (value != null && annotation.pattern != null) {
          final regex = RegExp(annotation.pattern!);
          if (!regex.hasMatch(value)) {
            return 'Value does not match required pattern';
          }
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

        // Check min/max constraints
        if (value != null) {
          if (annotation.min != null && value < annotation.min!) {
            return 'Value must be greater than or equal to ${annotation.min}';
          }
          if (annotation.max != null && value > annotation.max!) {
            return 'Value must be less than or equal to ${annotation.max}';
          }
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

  /// Validates a list field
  static String? validateList(List? value, List<dynamic> annotations) {
    for (final annotation in annotations) {
      if (annotation is QuantaField) {
        // Check required field
        if (annotation.required && (value == null || value.isEmpty)) {
          return 'Field is required';
        }

        // Check min/max length if provided
        if (value != null) {
          if (annotation.min != null && value.length < annotation.min!) {
            return 'List must have at least ${annotation.min} items';
          }
          if (annotation.max != null && value.length > annotation.max!) {
            return 'List must have at most ${annotation.max} items';
          }
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
          value = annotation.defaultValue as List;
        }
      }
    }
    return null;
  }

  /// Validates a map field
  static String? validateMap(Map? value, List<dynamic> annotations) {
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
          value = annotation.defaultValue as Map;
        }
      }
    }
    return null;
  }
}
