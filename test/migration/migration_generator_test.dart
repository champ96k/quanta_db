import 'dart:io';
import 'package:test/test.dart';
import 'package:quanta_db/src/migration/migration_generator.dart';
import 'package:quanta_db/src/storage/lsm_storage.dart';

void main() {
  group('MigrationGenerator', () {
    late MigrationGenerator generator;
    late LSMStorage storage;

    setUp(() async {
      storage = LSMStorage('test_data');
      await storage.init();
      generator = MigrationGenerator();
    });

    tearDown(() async {
      await storage.close();
    });

    test('detects added fields', () {
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
        },
        'indexes': [],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
          'email': {'type': 'String', 'nullable': true},
        },
        'indexes': [],
      };

      final changes = generator.detectSchemaChanges(oldSchema, newSchema);
      expect(changes['added']!, hasLength(1));
      expect(changes['added']![0]['name'], equals('email'));
    });

    test('detects removed fields', () {
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
          'email': {'type': 'String', 'nullable': true},
        },
        'indexes': [],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
        },
        'indexes': [],
      };

      final changes = generator.detectSchemaChanges(oldSchema, newSchema);
      expect(changes['removed']!, hasLength(1));
      expect(changes['removed']![0]['name'], equals('email'));
    });

    test('detects modified fields', () {
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'age': {'type': 'String', 'nullable': false},
        },
        'indexes': [],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'age': {'type': 'int', 'nullable': false},
        },
        'indexes': [],
      };

      final changes = generator.detectSchemaChanges(oldSchema, newSchema);
      expect(changes['modified']!, hasLength(1));
      expect(changes['modified']![0]['name'], equals('age'));
      expect(changes['modified']![0]['oldType'], equals('String'));
      expect(changes['modified']![0]['newType'], equals('int'));
    });

    test('detects index changes', () {
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
        },
        'indexes': [
          {
            'name': 'name_idx',
            'fields': ['name'],
            'unique': false
          },
        ],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
        },
        'indexes': [
          {
            'name': 'name_idx',
            'fields': ['name'],
            'unique': true
          },
          {
            'name': 'id_idx',
            'fields': ['id'],
            'unique': true
          },
        ],
      };

      final changes = generator.detectSchemaChanges(oldSchema, newSchema);
      final indexChanges = changes['indexChanges']!;
      expect(indexChanges[0]['type'], equals('modified'));
      expect(indexChanges[1]['type'], equals('added'));
      expect(indexChanges[0]['name'], equals('name_idx'));
      expect(indexChanges[1]['index']['name'], equals('id_idx'));
    });

    test('generates migration script', () async {
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
        },
        'indexes': [],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
          'email': {'type': 'String', 'nullable': true},
        },
        'indexes': [
          {
            'name': 'email_idx',
            'fields': ['email'],
            'unique': true
          },
        ],
      };

      // Create a temporary directory for test files
      final tempDir = await Directory.systemTemp.createTemp('migration_test_');
      final migrationDir = Directory('${tempDir.path}/migrations');
      await migrationDir.create();

      try {
        await generator.generateMigration(
          'User',
          1,
          2,
          oldSchema,
          newSchema,
          outputDirectory: migrationDir.path,
        );

        // Verify migration file was created
        final files = await migrationDir.list().toList();
        expect(files, hasLength(1));
        expect(files[0].path, contains('user_migration.dart'));
      } finally {
        // Clean up
        await tempDir.delete(recursive: true);
      }
    });
  });
}
