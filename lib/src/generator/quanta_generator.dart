import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:quanta_db/quanta_db.dart';
import 'package:source_gen/source_gen.dart';

class QuantaGenerator extends GeneratorForAnnotation<QuantaEntity> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    final className = element.name;
    final fields = element.fields.where((f) => !f.isStatic).toList();

    // Get schema version from annotation
    final schemaVersion = annotation.read('version').intValue;

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

    // Schema version
    adapterBuffer.writeln('  static const int schemaVersion = $schemaVersion;');

    // Validation method
    adapterBuffer.writeln('''
  static String? validate($className instance) {
    final errors = <String, String>{};
''');

    for (final field in fields) {
      if (_hasAnnotation(field, 'QuantaIgnore')) continue;

      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: true);
      final annotations = _formatAnnotations(field.metadata);

      if (annotations.isEmpty) {
        continue;
      }

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
    adapterBuffer.writeln(
        '  static Future<Map<String, dynamic>> toJson($className instance) async {');
    adapterBuffer.writeln('''
    final validationError = validate(instance);
    if (validationError != null) {
      throw ValidationException(validationError);
    }
''');
    adapterBuffer.writeln('    return {');
    for (final field in fields) {
      if (_hasAnnotation(field, 'QuantaIgnore')) continue;

      final fieldName = field.name;
      adapterBuffer.writeln('      \'$fieldName\': instance.$fieldName,');
    }
    adapterBuffer.writeln('    };');
    adapterBuffer.writeln('  }');

    // fromJson method
    adapterBuffer.writeln(
        '  static Future<$className> fromJson(Map<String, dynamic> json) async => $className(');
    for (final field in fields) {
      if (_hasAnnotation(field, 'QuantaIgnore')) continue;

      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: true);
      adapterBuffer
          .writeln('    $fieldName: json[\'$fieldName\'] as $fieldType,');
    }
    adapterBuffer.writeln('  );');

    adapterBuffer.writeln('}');

    // DAO with indexing and reactivity support
    final daoBuffer = StringBuffer();
    daoBuffer.writeln('class ${className}Dao {');
    daoBuffer.writeln('  final QuantaDB _db;');
    daoBuffer.writeln('  ${className}Dao(this._db);');

    // Schema version getter
    daoBuffer.writeln('''
  int get schemaVersion => ${className}Adapter.schemaVersion;
''');

    // CRUD methods
    daoBuffer.writeln('''
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
        final fieldType = field.type.getDisplayString(withNullability: true);
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
        final fieldType = field.type.getDisplayString(withNullability: true);
        daoBuffer.writeln('''
  Stream<$fieldType> watch${_capitalize(fieldName)}($className instance) async* {
    final stream = _db.onChange.where((event) => 
      event.key == '\${instance.id}');
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
