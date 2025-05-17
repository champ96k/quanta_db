import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class RealmGenerator extends GeneratorForAnnotation<Object> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    final className = element.name;
    final fields = element.fields.where((f) => !f.isStatic).toList();

    // Type Adapter
    final adapterBuffer = StringBuffer();
    adapterBuffer.writeln('class ${className}Adapter {');
    adapterBuffer.writeln(
        '  static Map<String, dynamic> toJson($className instance) => {');
    for (final field in fields) {
      adapterBuffer.writeln("    '${field.name}': instance.${field.name},");
    }
    adapterBuffer.writeln('  };');
    adapterBuffer.writeln(
        '  static $className fromJson(Map<String, dynamic> json) => $className(');
    for (final field in fields) {
      adapterBuffer.writeln('    json[\'${field.name}\'] as ${field.type},');
    }
    adapterBuffer.writeln('  );');
    adapterBuffer.writeln('}');

    // DAO
    final daoBuffer = StringBuffer();
    daoBuffer.writeln('class ${className}Dao {');
    daoBuffer.writeln('  // TODO: Inject your database instance here');
    daoBuffer.writeln(
        '  Future<void> insert($className instance) async { /* ... */ }');
    daoBuffer.writeln(
        '  Future<$className?> getById(dynamic id) async { /* ... */ return null; }');
    daoBuffer.writeln(
        '  Future<List<$className>> getAll() async { /* ... */ return []; }');
    daoBuffer.writeln(
        '  Future<void> update($className instance) async { /* ... */ }');
    daoBuffer.writeln('  Future<void> delete(dynamic id) async { /* ... */ }');
    daoBuffer.writeln('}');

    return [
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      adapterBuffer.toString(),
      daoBuffer.toString(),
    ].join('\n\n');
  }
}
