import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:quanta_db/src/migration/migration_generator.dart';
import 'package:quanta_db/src/storage/schema_storage.dart';
import 'package:quanta_db/src/schema/schema_version_manager.dart';

class MigrationBuilder implements Builder {
  MigrationBuilder(this._schemaStorage)
      : _versionManager = SchemaVersionManager(_schemaStorage.storage);
  final SchemaStorage _schemaStorage;
  final SchemaVersionManager _versionManager;

  @override
  final buildExtensions = const {
    '.dart': ['.migration.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Parse the file to find model classes
    final library = await buildStep.inputLibrary;
    final models = _findModelClasses(library);

    if (models.isEmpty) return;

    // For each model, generate migration if needed
    for (final model in models) {
      final currentSchema = await _getCurrentSchema(model);
      final newSchema = _generateSchemaFromModel(model);

      // Only generate migration if schema has changed
      if (hasSchemaChanged(currentSchema, newSchema)) {
        final generator = MigrationGenerator(_versionManager);
        await generator.generateMigration(
          model.name,
          currentSchema,
          newSchema,
        );
      }
    }
  }

  List<ClassElement> _findModelClasses(LibraryElement library) {
    return library.topLevelElements
        .whereType<ClassElement>()
        .where((c) => c.metadata.any((m) => m.element?.name == 'QuantaEntity'))
        .toList();
  }

  Future<Map<String, dynamic>> _getCurrentSchema(ClassElement model) async {
    return await _schemaStorage.getSchema(model.name);
  }

  Map<String, dynamic> _generateSchemaFromModel(ClassElement model) {
    final fields = <String, Map<String, dynamic>>{};
    final indexes = <Map<String, dynamic>>[];

    // Process all fields
    for (final field in model.fields) {
      if (field.isStatic) continue;

      final type = field.type;
      final typeName = _getTypeName(type);

      fields[field.name] = {
        'type': typeName,
        'nullable': type.toString().endsWith('?'),
      };

      // Check for index annotation
      final hasIndex =
          field.metadata.any((m) => m.element?.name == 'QuantaIndex');
      if (hasIndex) {
        final indexAnnotation =
            field.metadata.firstWhere((m) => m.element?.name == 'QuantaIndex');
        final constantValue = indexAnnotation.computeConstantValue();

        indexes.add({
          'name': '${field.name}_idx',
          'fields': [field.name],
          'unique': constantValue?.getField('unique')?.toBoolValue() ?? false,
        });
      }

      // Check for reactive annotation
      final isReactive =
          field.metadata.any((m) => m.element?.name == 'QuantaReactive');
      if (isReactive) {
        fields[field.name]!['reactive'] = true;
      }
    }

    return {
      'fields': fields,
      'indexes': indexes,
    };
  }

  String _getTypeName(DartType type) {
    if (type.isDartCoreString) return 'String';
    if (type.isDartCoreInt) return 'int';
    if (type.isDartCoreDouble) return 'double';
    if (type.isDartCoreBool) return 'bool';
    if (type.isDartCoreList) return 'List';
    if (type.isDartCoreMap) return 'Map';
    return type.toString();
  }

  bool hasSchemaChanged(
      Map<String, dynamic> oldSchema, Map<String, dynamic> newSchema) {
    if (oldSchema.isEmpty) return true;

    final oldFields = oldSchema['fields'] as Map<String, dynamic>;
    final newFields = newSchema['fields'] as Map<String, dynamic>;

    // Check for field changes
    if (oldFields.length != newFields.length) return true;

    for (final field in newFields.keys) {
      if (!oldFields.containsKey(field)) return true;
      if (oldFields[field]['type'] != newFields[field]['type']) return true;
      if (oldFields[field]['nullable'] != newFields[field]['nullable']) {
        return true;
      }
      if (oldFields[field]['reactive'] != newFields[field]['reactive']) {
        return true;
      }
    }

    // Check for index changes
    final oldIndexes = oldSchema['indexes'] as List<dynamic>;
    final newIndexes = newSchema['indexes'] as List<dynamic>;

    if (oldIndexes.length != newIndexes.length) return true;

    for (final newIndex in newIndexes) {
      final oldIndex = oldIndexes.firstWhere(
        (i) => i['name'] == newIndex['name'],
        orElse: () => <String, Object>{},
      );

      if (oldIndex.isEmpty) return true;
      if (oldIndex['unique'] != newIndex['unique']) return true;
      if (!_areListsEqual(oldIndex['fields'], newIndex['fields'])) return true;
    }

    return false;
  }

  bool _areListsEqual(List<dynamic> list1, List<dynamic> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
