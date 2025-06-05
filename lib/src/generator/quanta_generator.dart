// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:quanta_db/quanta_db.dart';
import 'package:source_gen/source_gen.dart';

/// A code generator that creates type adapters and data access objects (DAOs) for QuantaDB entities.
///
/// This generator is used to automatically generate code for classes annotated with [QuantaEntity].
/// It creates:
/// - Type adapters for serialization and validation
/// - Data access objects (DAOs) for database operations
/// - Support for indexing and reactive fields
///
/// The generated code handles:
/// - JSON serialization/deserialization
/// - Field validation
/// - Index management
/// - Reactive field updates
/// - Schema versioning
class QuantaGenerator extends GeneratorForAnnotation<QuantaEntity> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    final className = element.name;

    // Get all fields including inherited ones
    final fields =
        element.fields.where((f) => !f.isStatic && !f.isPrivate).toList();

    // Get schema version from annotation
    final schemaVersion = annotation.read('version').isNull
        ? 1
        : annotation.read('version').intValue;

    final buffer = StringBuffer();
    buffer.writeln(
        '// **************************************************************************');
    buffer.writeln('// QuantaGenerator');
    buffer.writeln(
        '// **************************************************************************');
    buffer.writeln();

    // Extension for JSON serialization/deserialization and toString
    buffer.writeln('extension ${className}JsonExtension on $className {');

    // fromJson static method
    buffer.writeln('  static $className fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    for (final field in fields) {
      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: false);
      final isEnum = field.type.element?.kind == ElementKind.ENUM;
      final isList = fieldType.startsWith('List<');

      if (isList) {
        final innerType = fieldType.substring(5, fieldType.length - 1);
        if (innerType == 'String') {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => e as String).toList(),");
        } else if (innerType == 'int') {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => e as int).toList(),");
        } else if (innerType == 'double') {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => (e as num).toDouble()).toList(),");
        } else if (innerType == 'bool') {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => e as bool).toList(),");
        } else if (innerType == 'DateTime') {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => DateTime.parse(e as String)).toList(),");
        } else if (innerType.endsWith('Enum')) {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => $innerType.values.firstWhere((v) => v.name == e)).toList(),");
        } else {
          buffer.writeln(
              "      $fieldName: (json['$fieldName'] as List).map((e) => ${innerType}JsonExtension.fromJson(e as Map<String, dynamic>)).toList(),");
        }
      } else if (fieldType == 'DateTime') {
        buffer.writeln(
            "      $fieldName: DateTime.parse(json['$fieldName'] as String),");
      } else if (fieldType == 'int') {
        buffer.writeln("      $fieldName: json['$fieldName'] as int,");
      } else if (fieldType == 'double') {
        buffer.writeln(
            "      $fieldName: (json['$fieldName'] as num).toDouble(),");
      } else if (fieldType == 'num') {
        buffer.writeln("      $fieldName: json['$fieldName'] as num,");
      } else if (fieldType == 'bool') {
        buffer.writeln("      $fieldName: json['$fieldName'] as bool,");
      } else if (fieldType == 'String') {
        buffer.writeln("      $fieldName: json['$fieldName'] as String,");
      } else if (isEnum) {
        buffer.writeln(
            "      $fieldName: $fieldType.values.firstWhere((e) => e.name == json['$fieldName']),");
      } else {
        // Assume custom type with fromJson
        buffer.writeln(
            "      $fieldName: ${fieldType}JsonExtension.fromJson(json['$fieldName'] as Map<String, dynamic>),");
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    // toJson instance method
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    for (final field in fields) {
      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: false);
      final isEnum = field.type.element?.kind == ElementKind.ENUM;
      final isList = fieldType.startsWith('List<');

      if (isList) {
        final innerType = fieldType.substring(5, fieldType.length - 1);
        if (innerType == 'DateTime') {
          buffer.writeln(
              "      '$fieldName': $fieldName.map((e) => e.toIso8601String()).toList(),");
        } else if (innerType.endsWith('Enum')) {
          buffer.writeln(
              "      '$fieldName': $fieldName.map((e) => e.name).toList(),");
        } else if (['String', 'int', 'double', 'num', 'bool']
            .contains(innerType)) {
          buffer.writeln("      '$fieldName': $fieldName,");
        } else {
          buffer.writeln(
              "      '$fieldName': $fieldName.map((e) => e.toJson()).toList(),");
        }
      } else if (fieldType == 'DateTime') {
        buffer.writeln("      '$fieldName': $fieldName.toIso8601String(),");
      } else if (isEnum) {
        buffer.writeln(
            "      '$fieldName': $fieldName${field.type.nullabilitySuffix == NullabilitySuffix.question ? '?.name' : '.name'},");
      } else if (['int', 'double', 'num', 'bool', 'String']
          .contains(fieldType)) {
        buffer.writeln("      '$fieldName': $fieldName,");
      } else {
        // Assume custom type with toJson
        buffer.writeln("      '$fieldName': $fieldName.toJson(),");
      }
    }
    buffer.writeln('    };');
    buffer.writeln('  }');

    // toDebugString method
    buffer.writeln('  String toDebugString() {');
    buffer.writeln('    final fields = [');
    for (final field in fields) {
      buffer.writeln("      '${field.name}: \$${field.name}',");
    }
    buffer.writeln('    ].join(", ");');
    buffer.writeln('    return "$className(\$fields)";');
    buffer.writeln('  }');

    buffer.writeln('}');

    // Type Adapter with encryption and ignore support
    final adapterBuffer = StringBuffer();
    adapterBuffer.writeln('');
    adapterBuffer.writeln(
        '// **************************************************************************');
    adapterBuffer.writeln('// QuantaGenerator');
    adapterBuffer.writeln(
        '// **************************************************************************');
    adapterBuffer.writeln('');
    adapterBuffer.writeln('class ${className}Adapter {');
    adapterBuffer.writeln('  static const int schemaVersion = $schemaVersion;');

    // Validation method
    adapterBuffer.writeln('''
  static String? validate($className instance) {
    final errors = <String, String>{};
''');

    for (final field in fields) {
      if (_hasAnnotation(field, 'QuantaIgnore')) continue;

      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: false);
      final annotations = _formatAnnotations(field.metadata);

      if (annotations.isEmpty) continue;

      if (fieldType == 'String') {
        adapterBuffer.writeln('''
    final ${fieldName}Error = FieldValidator.validateString(instance.$fieldName, $annotations);
    if (${fieldName}Error != null) {
      errors['$fieldName'] = ${fieldName}Error;
    }
''');
      } else if (fieldType == 'int' ||
          fieldType == 'double' ||
          fieldType == 'num') {
        adapterBuffer.writeln('''
    final ${fieldName}Error = FieldValidator.validateNumber(instance.$fieldName, $annotations);
    if (${fieldName}Error != null) {
      errors['$fieldName'] = ${fieldName}Error;
    }
''');
      } else if (fieldType == 'bool') {
        adapterBuffer.writeln('''
    final ${fieldName}Error = FieldValidator.validateBoolean(value: instance.$fieldName, annotations: $annotations);
    if (${fieldName}Error != null) {
      errors['$fieldName'] = ${fieldName}Error;
    }
''');
      } else {
        adapterBuffer.writeln('''
    final ${fieldName}Error = FieldValidator.validate(instance.$fieldName, $annotations);
    if (${fieldName}Error != null) {
      errors['$fieldName'] = ${fieldName}Error;
    }
''');
      }
    }

    adapterBuffer.writeln('''
    return errors.isEmpty ? null : errors.toString();
  }
''');

    // toJson method
    adapterBuffer.writeln('''
  static Future<Map<String, dynamic>> toJson($className instance) async {
    final validationError = validate(instance);
    if (validationError != null) {
      throw ValidationException(validationError);
    }
    return instance.toJson();
  }
''');

    // fromJson method
    adapterBuffer.writeln('''
  static Future<$className> fromJson(Map<String, dynamic> json) async {
    return ${className}JsonExtension.fromJson(json);
  }
''');

    adapterBuffer.writeln('}');

    // DAO with indexing and reactivity support
    final daoBuffer = StringBuffer();
    daoBuffer.writeln('class ${className}Dao {');
    daoBuffer.writeln('  final QuantaDB _db;');
    daoBuffer.writeln('  ${className}Dao(this._db);');
    daoBuffer.writeln('''
  int get schemaVersion => ${className}Adapter.schemaVersion;

  Future<void> insert($className instance) async {
    final json = await ${className}Adapter.toJson(instance);
    await _db.put(instance.id, json);
  }

  Future<$className?> getById(String id) async {
    final json = await _db.get<Map<String, dynamic>>(id);
    if (json == null) return null;
    return await ${className}Adapter.fromJson(json);
  }

  Future<List<$className>> getAll() async {
    final items = await _db.queryEngine.query<Map<String, dynamic>>(Query<Map<String, dynamic>>());
    final filtered = items.where((item) => item.keys.first.startsWith('${className.toLowerCase()}:')).toList();
    return Future.wait(filtered.map((item) => ${className}Adapter.fromJson(item.values.first)));
  }

  Future<void> update($className instance) async {
    final json = await ${className}Adapter.toJson(instance);
    await _db.put(instance.id, json);
  }

  Future<void> delete(String id) async {
    await _db.delete(id);
  }
''');

    // Index methods
    final indexedFields =
        fields.where((f) => _hasAnnotation(f, 'QuantaIndex')).toList();
    if (indexedFields.isNotEmpty) {
      daoBuffer.writeln('\n  // Index methods');
      for (final field in indexedFields) {
        final fieldName = field.name;
        final fieldType = field.type.getDisplayString(withNullability: false);
        daoBuffer.writeln('''
  Future<List<$className>> findBy${_capitalize(fieldName)}($fieldType value) async {
    final items = await getAll();
    return items.where((item) => item.$fieldName == value).toList();
  }
''');
      }
    }

    // Reactive methods
    final reactiveFields =
        fields.where((f) => _hasAnnotation(f, 'QuantaReactive')).toList();
    if (reactiveFields.isNotEmpty) {
      daoBuffer.writeln('\n  // Reactive methods');
      for (final field in reactiveFields) {
        final fieldName = field.name;
        final fieldType = field.type.getDisplayString(withNullability: false);
        daoBuffer.writeln('''
  Stream<$fieldType> watch${_capitalize(fieldName)}($className instance) async* {
    final stream = _db.onChange.where((event) => event.key == '\${instance.id}');
    await for (final event in stream) {
      if (event.value != null) {
        final updated = await ${className}Adapter.fromJson(event.value as Map<String, dynamic>);
        yield updated.$fieldName;
      }
    }
  }
''');
      }
    }

    daoBuffer.writeln('}');

    return [
      buffer.toString(),
      adapterBuffer.toString(),
      daoBuffer.toString(),
    ].join('\n\n');
  }

  String _formatAnnotations(List<ElementAnnotation> annotations) {
    final formattedAnnotations = annotations
        .map((annotation) {
          final reader = ConstantReader(annotation.computeConstantValue());
          final name = annotation.element?.name ?? '';

          if (name == 'QuantaField') {
            final required = reader.read('required').boolValue;
            final defaultValue = reader.read('defaultValue').isNull
                ? 'null'
                : reader.read('defaultValue').literalValue;
            final validator = reader.read('validator').isNull ? 'null' : 'null';
            return 'QuantaField(required: $required, defaultValue: $defaultValue, validator: $validator)';
          } else if (name == 'QuantaIndex') {
            return 'QuantaIndex()';
          } else if (name == 'QuantaReactive') {
            return 'QuantaReactive()';
          }
          return null;
        })
        .where((a) => a != null)
        .toList();

    if (formattedAnnotations.isEmpty) {
      return '[]';
    }
    return '[${formattedAnnotations.join(', ')}]';
  }

  bool _hasAnnotation(Element element, String annotationName) {
    return element.metadata.any((m) => m.element?.name == annotationName);
  }

  String _capitalize(String input) {
    return input[0].toUpperCase() + input.substring(1);
  }
}
