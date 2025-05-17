import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:quanta_db/annotations/quanta_annotations.dart';
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
      final annotations =
          field.metadata.map((m) => m.computeConstantValue()).toList();

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
    final ${fieldName}Error = FieldValidator.validateBoolean(instance.$fieldName, $annotations);
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
      if (_hasAnnotation(field, 'QuantaEncrypted')) {
        adapterBuffer.writeln(
            '      \'$fieldName\': AESEncryption.encrypt(instance.$fieldName.toString(), await KeyManager.getEncryptionKey()),');
      } else {
        adapterBuffer.writeln('      \'$fieldName\': instance.$fieldName,');
      }
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

      if (_hasAnnotation(field, 'QuantaEncrypted')) {
        adapterBuffer.writeln(
            '    $fieldName: ${fieldType == 'String' ? '' : '$fieldType.parse('}AESEncryption.decrypt(json[\'$fieldName\'] as String, await KeyManager.getEncryptionKey())${fieldType == 'String' ? '' : ')'},');
      } else {
        adapterBuffer
            .writeln('    $fieldName: json[\'$fieldName\'] as $fieldType,');
      }
    }
    adapterBuffer.writeln('  );');

    adapterBuffer.writeln('}');

    // DAO with indexing and reactivity support
    final daoBuffer = StringBuffer();
    daoBuffer.writeln('class ${className}Dao {');
    daoBuffer.writeln('  final _db; // TODO: Inject your database instance');
    daoBuffer.writeln('  ${className}Dao(this._db);');

    // Schema version getter
    daoBuffer.writeln('''
  int get schemaVersion => ${className}Adapter.schemaVersion;
''');

    // CRUD methods
    daoBuffer.writeln('''
  Future<void> insert($className instance) async {
    final json = await ${className}Adapter.toJson(instance);
    await _db.put('\${instance.id}', json);
  }

  Future<$className?> getById(String id) async {
    final json = await _db.get<Map<String, dynamic>>(id);
    if (json == null) return null;
    return await ${className}Adapter.fromJson(json);
  }

  Future<List<$className>> getAll() async {
    final items = await _db.getAll<Map<String, dynamic>>();
    return items
        .where((item) => item.keys.first.startsWith('${className.toLowerCase()}:'))
        .map((item) => await ${className}Adapter.fromJson(item.values.first))
        .toList();
  }

  Future<void> update($className instance) async {
    final json = await ${className}Adapter.toJson(instance);
    await _db.put('\${instance.id}', json);
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
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      'import \'package:quanta_db/src/encryption/aes_encryption.dart\';',
      adapterBuffer.toString(),
      daoBuffer.toString(),
    ].join('\n\n');
  }

  bool _hasAnnotation(Element element, String annotationName) {
    return element.metadata.any((m) => m.element?.name == annotationName);
  }

  String _capitalize(String input) {
    return input[0].toUpperCase() + input.substring(1);
  }
}
