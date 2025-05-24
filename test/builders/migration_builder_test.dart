import 'package:test/test.dart';
import 'package:quanta_db/src/builders/migration_builder.dart';
import 'package:quanta_db/src/storage/schema_storage.dart';
import 'package:quanta_db/src/storage/lsm_storage.dart';

void main() {
  late LSMStorage storage;
  late SchemaStorage schemaStorage;
  late MigrationBuilder builder;

  setUp(() async {
    storage = LSMStorage('test_db');
    await storage.init();
    schemaStorage = SchemaStorage(storage);
    builder = MigrationBuilder(schemaStorage);
  });

  tearDown(() async {
    await storage.close();
  });

  test('detects schema changes correctly', () async {
    // Initial schema
    final initialSchema = {
      'fields': {
        'id': {'type': 'String', 'nullable': false, 'reactive': false},
        'name': {'type': 'String', 'nullable': false, 'reactive': false},
        'email': {'type': 'String', 'nullable': false, 'reactive': false},
      },
      'indexes': [
        {
          'name': 'email_idx',
          'fields': ['email'],
          'unique': true,
        }
      ]
    };

    // Store initial schema
    await schemaStorage.setSchema('User', initialSchema);
    await schemaStorage.setVersion('User', 1);

    // New schema with added field
    final newSchema = {
      'fields': {
        'id': {'type': 'String', 'nullable': false, 'reactive': false},
        'name': {'type': 'String', 'nullable': false, 'reactive': false},
        'email': {'type': 'String', 'nullable': false, 'reactive': false},
        'age': {'type': 'int', 'nullable': true, 'reactive': false},
      },
      'indexes': [
        {
          'name': 'email_idx',
          'fields': ['email'],
          'unique': true,
        }
      ]
    };

    // Verify schema changes
    expect(builder.hasSchemaChanged(initialSchema, newSchema), isTrue);

    // Verify field changes
    final oldFields = initialSchema['fields'] as Map<String, dynamic>;
    final newFields = newSchema['fields'] as Map<String, dynamic>;
    expect(newFields.length, greaterThan(oldFields.length));
    expect(newFields.containsKey('age'), isTrue);
    expect(newFields['age']['type'], equals('int'));
    expect(newFields['age']['nullable'], isTrue);
  });
}
