import 'dart:io';

import 'package:quanta_db/src/schema/schema_version_manager.dart';

/// Generates migration scripts based on schema changes
class MigrationGenerator {
  MigrationGenerator(this._versionManager);
  final SchemaVersionManager _versionManager;

  String _timestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .toLowerCase()
        .replaceAll(RegExp(r'^_'), '');
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  /// Generate migration script for schema changes
  Future<void> generateMigration(
    String entityName,
    Map<String, dynamic> oldSchema,
    Map<String, dynamic> newSchema, {
    String? outputDirectory,
  }) async {
    final changes = detectSchemaChanges(oldSchema, newSchema);
    if (changes.isEmpty) return;

    // Get current and next version
    final currentVersion = await _versionManager.getVersion(entityName);
    final nextVersion = await _versionManager.getNextVersion(entityName);

    final migration = _generateMigrationScript(
      entityName,
      currentVersion,
      nextVersion,
      changes,
    );

    final fileName =
        '${_timestamp()}_${_toSnakeCase(entityName)}_migration.dart';
    final dir = outputDirectory ?? 'migrations';
    final file = File('$dir/$fileName');
    await file.parent.create(recursive: true);
    await file.writeAsString(migration);

    // Record the migration
    await _versionManager.recordMigration(
      entityName,
      currentVersion,
      nextVersion,
      fileName,
    );
  }

  /// Detect changes between old and new schema
  Map<String, List<Map<String, dynamic>>> detectSchemaChanges(
    Map<String, dynamic> oldSchema,
    Map<String, dynamic> newSchema,
  ) {
    final changes = <String, List<Map<String, dynamic>>>{
      'added': [],
      'modified': [],
      'removed': [],
      'indexChanges': [],
    };

    // Compare fields
    final oldFields = oldSchema['fields'] as Map<String, dynamic>;
    final newFields = newSchema['fields'] as Map<String, dynamic>;

    // Find added and modified fields
    for (final field in newFields.entries) {
      if (!oldFields.containsKey(field.key)) {
        changes['added']!.add({
          'name': field.key,
          'type': field.value['type'],
          'nullable': field.value['nullable'],
        });
      } else if (oldFields[field.key] != field.value) {
        changes['modified']!.add({
          'name': field.key,
          'oldType': oldFields[field.key]['type'],
          'newType': field.value['type'],
          'oldNullable': oldFields[field.key]['nullable'],
          'newNullable': field.value['nullable'],
        });
      }
    }

    // Find removed fields
    for (final field in oldFields.entries) {
      if (!newFields.containsKey(field.key)) {
        changes['removed']!.add({
          'name': field.key,
          'type': field.value['type'],
          'nullable': field.value['nullable'],
        });
      }
    }

    // Compare indexes
    final oldIndexes = oldSchema['indexes'] as List<dynamic>;
    final newIndexes = newSchema['indexes'] as List<dynamic>;

    // Find added and modified indexes
    for (final newIndex in newIndexes) {
      final oldIndex = oldIndexes.firstWhere(
        (idx) => idx['name'] == newIndex['name'],
        orElse: () => <String, Object>{},
      );

      if (oldIndex.isEmpty) {
        changes['indexChanges']!.add({
          'type': 'added',
          'index': newIndex,
        });
      } else if (oldIndex['fields'] != newIndex['fields'] ||
          oldIndex['unique'] != newIndex['unique']) {
        changes['indexChanges']!.add({
          'type': 'modified',
          'name': newIndex['name'],
          'oldFields': oldIndex['fields'],
          'newFields': newIndex['fields'],
          'oldUnique': oldIndex['unique'],
          'newUnique': newIndex['unique'],
        });
      }
    }

    // Find removed indexes
    for (final oldIndex in oldIndexes) {
      if (!newIndexes.any((idx) => idx['name'] == oldIndex['name'])) {
        changes['indexChanges']!.add({
          'type': 'removed',
          'index': oldIndex,
        });
      }
    }

    return changes;
  }

  /// Generate migration script
  String _generateMigrationScript(
    String entityName,
    int oldVersion,
    int newVersion,
    Map<String, List<Map<String, dynamic>>> changes,
  ) {
    if (changes.isEmpty) {
      return '// No changes detected';
    }

    final buffer = StringBuffer();
    buffer.writeln('''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Migration script for $entityName from version $oldVersion to $newVersion

import 'package:quanta_db/quanta_db.dart';

class ${_toPascalCase(entityName)}Migration extends SchemaMigration {
  @override
  Future<void> up(LSMStorage storage) async {
''');

    // Generate code for added fields
    if ((changes['added'] ?? []).isNotEmpty) {
      buffer.writeln('    // Handle field additions');
      for (final field in changes['added']!) {
        buffer.writeln('''
    // Add field: ${field['name']}
    await _addField(
      storage,
      '${field['name']}',
      ${field['nullable'] ? 'null' : _getDefaultValue(field['type'])},
    );
''');
      }
    }

    // Generate code for modified fields
    if ((changes['modified'] ?? []).isNotEmpty) {
      buffer.writeln('\n    // Handle field modifications');
      for (final field in changes['modified']!) {
        buffer.writeln('''
    // Modify field: ${field['name']}
    await _modifyField(
      storage,
      '${field['name']}',
      '${field['oldType']}',
      '${field['newType']}',
    );
''');
      }
    }

    // Generate code for index changes
    final indexChanges = changes['indexChanges'] ?? [];
    if (indexChanges.isNotEmpty) {
      buffer.writeln('\n    // Handle index changes');
      for (final change in indexChanges) {
        if (change['type'] == 'added') {
          final fields =
              (change['index']['fields'] as List).map((f) => "'$f'").join(', ');
          buffer.writeln('''
    // Add index: ${change['index']['name']}
    await _addIndex(
      storage,
      '${change['index']['name']}',
      [$fields],
      ${change['index']['unique']},
    );
''');
        } else if (change['type'] == 'removed') {
          buffer.writeln('''
    // Remove index: ${change['index']['name']}
    await _removeIndex(
      storage,
      '${change['index']['name']}',
    );
''');
        }
      }
    }

    buffer.writeln('''
  }

  @override
  Future<void> down(LSMStorage storage) async {
''');

    // Generate rollback code for removed fields
    if ((changes['removed'] ?? []).isNotEmpty) {
      buffer.writeln('    // Handle field removals');
      for (final field in changes['removed']!) {
        buffer.writeln('''
    // Remove field: ${field['name']}
    await _removeField(
      storage,
      '${field['name']}',
    );
''');
      }
    }

    // Generate rollback code for index changes
    if (indexChanges.isNotEmpty) {
      buffer.writeln('\n    // Handle index rollbacks');
      for (final change in indexChanges) {
        if (change['type'] == 'added') {
          buffer.writeln('''
    // Remove added index: ${change['index']['name']}
    await _removeIndex(
      storage,
      '${change['index']['name']}',
    );
''');
        } else if (change['type'] == 'removed') {
          final fields =
              (change['index']['fields'] as List).map((f) => "'$f'").join(', ');
          buffer.writeln('''
    // Restore removed index: ${change['index']['name']}
    await _addIndex(
      storage,
      '${change['index']['name']}',
      [$fields],
      ${change['index']['unique']},
    );
''');
        }
      }
    }

    buffer.writeln('''
  }

  // Helper methods for field operations
''');

    // Only include methods that are actually used
    if ((changes['added'] ?? []).isNotEmpty) {
      buffer.writeln('''
  Future<void> _addField(
    LSMStorage storage,
    String fieldName,
    dynamic defaultValue,
  ) async {
    // Get all existing documents
    final documents = await storage.getAll<Map<String, dynamic>>();
    
    // Add the new field to each document
    for (final doc in documents) {
      doc[fieldName] = defaultValue;
      await storage.put(doc['id'], doc);
    }
  }
''');
    }

    if ((changes['modified'] ?? []).isNotEmpty) {
      buffer.writeln('''
  Future<void> _modifyField(
    LSMStorage storage,
    String fieldName,
    String oldType,
    String newType,
  ) async {
    // Get all existing documents
    final documents = await storage.getAll<Map<String, dynamic>>();
    
    // Convert field type for each document
    for (final doc in documents) {
      if (doc.containsKey(fieldName)) {
        final value = doc[fieldName];
        doc[fieldName] = _convertType(value, oldType, newType);
        await storage.put(doc['id'], doc);
      }
    }
  }

  dynamic _convertType(dynamic value, String oldType, String newType) {
    if (value == null) return null;

    try {
      switch (newType) {
        case 'String':
          return value.toString();
        case 'int':
          return int.parse(value.toString());
        case 'double':
          return double.parse(value.toString());
        case 'bool':
          return value.toString().toLowerCase() == 'true';
        case 'DateTime':
          return DateTime.parse(value.toString());
        default:
          return value;
      }
    } catch (e) {
      // If conversion fails, return null
      return null;
    }
  }
''');
    }

    if ((changes['removed'] ?? []).isNotEmpty) {
      buffer.writeln('''
  Future<void> _removeField(
    LSMStorage storage,
    String fieldName,
  ) async {
    // Get all existing documents
    final documents = await storage.getAll<Map<String, dynamic>>();
    
    // Remove the field from each document
    for (final doc in documents) {
      doc.remove(fieldName);
      await storage.put(doc['id'], doc);
    }
  }
''');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _getDefaultValue(String type) {
    switch (type) {
      case 'String':
        return "''";
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'DateTime':
        return 'DateTime.now()';
      default:
        return 'null';
    }
  }
}
