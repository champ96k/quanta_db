import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:quanta_db/annotations/quanta_annotations.dart';

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

    // Type Adapter with encryption and ignore support
    final adapterBuffer = StringBuffer();
    adapterBuffer.writeln('class ${className}Adapter {');

    // toJson method
    adapterBuffer.writeln(
        '  static Map<String, dynamic> toJson($className instance) => {');
    for (final field in fields) {
      if (_hasAnnotation(field, 'QuantaIgnore')) continue;

      final fieldName = field.name;
      if (_hasAnnotation(field, 'QuantaEncrypted')) {
        adapterBuffer
            .writeln('    \'$fieldName\': _encrypt(instance.$fieldName),');
      } else {
        adapterBuffer.writeln('    \'$fieldName\': instance.$fieldName,');
      }
    }
    adapterBuffer.writeln('  };');

    // fromJson method
    adapterBuffer.writeln(
        '  static $className fromJson(Map<String, dynamic> json) => $className(');
    for (final field in fields) {
      if (_hasAnnotation(field, 'QuantaIgnore')) continue;

      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: true);

      if (_hasAnnotation(field, 'QuantaEncrypted')) {
        adapterBuffer.writeln(
            '    $fieldName: _decrypt(json[\'$fieldName\'] as String),');
      } else {
        adapterBuffer
            .writeln('    $fieldName: json[\'$fieldName\'] as $fieldType,');
      }
    }
    adapterBuffer.writeln('  );');

    // Encryption helpers
    adapterBuffer.writeln('''
  static String _encrypt(String value) {
    // TODO: Implement encryption
    return value;
  }

  static String _decrypt(String value) {
    // TODO: Implement decryption
    return value;
  }
''');
    adapterBuffer.writeln('}');

    // DAO with indexing and reactivity support
    final daoBuffer = StringBuffer();
    daoBuffer.writeln('class ${className}Dao {');
    daoBuffer.writeln('  final _db; // TODO: Inject your database instance');
    daoBuffer.writeln('  ${className}Dao(this._db);');

    // CRUD methods
    daoBuffer.writeln('''
  Future<void> insert($className instance) async {
    final json = ${className}Adapter.toJson(instance);
    // TODO: Implement insert with index updates
  }

  Future<$className?> getById(String id) async {
    // TODO: Implement getById
    return null;
  }

  Future<List<$className>> getAll() async {
    // TODO: Implement getAll
    return [];
  }

  Future<void> update($className instance) async {
    final json = ${className}Adapter.toJson(instance);
    // TODO: Implement update with index updates
  }

  Future<void> delete(String id) async {
    // TODO: Implement delete with index cleanup
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
    // TODO: Implement index lookup
    return [];
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
    // TODO: Implement reactive field watching
    yield instance.$fieldName;
  }
''');
      }
    }

    daoBuffer.writeln('}');

    return [
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
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
