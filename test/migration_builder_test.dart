import 'package:quanta_db/quanta_db.dart';

import 'package:test/test.dart';

@QuantaEntity()
class TestUser {
  TestUser({
    required this.id,
    required this.name,
    required this.age,
    required this.email,
  });
  final String id;
  final String name;
  final int age;
  @QuantaIndex(unique: true)
  final String email;
}

@QuantaEntity()
class TestPost {
  TestPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
  });
  final String id;
  final String title;
  final String content;
  @QuantaIndex()
  final String authorId;
}

void main() {
  late SchemaStorage schemaStorage;
  late MigrationBuilder migrationBuilder;

  setUp(() {
    schemaStorage = MockSchemaStorage();
    migrationBuilder = MigrationBuilder(schemaStorage);
  });

  group('MigrationBuilder', () {
    test('should detect schema changes', () async {
      // Arrange
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
          'age': {'type': 'int', 'nullable': false},
        },
        'indexes': [],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
          'age': {'type': 'int', 'nullable': false},
          'email': {'type': 'String', 'nullable': false},
        },
        'indexes': [
          {
            'name': 'email_idx',
            'fields': ['email'],
            'unique': true,
          }
        ],
      };

      // Act
      final hasChanged =
          migrationBuilder.hasSchemaChanged(oldSchema, newSchema);

      // Assert
      expect(hasChanged, isTrue);
    });

    test('should not detect changes for identical schemas', () async {
      // Arrange
      final schema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'name': {'type': 'String', 'nullable': false},
        },
        'indexes': [],
      };

      // Act
      final hasChanged = migrationBuilder.hasSchemaChanged(schema, schema);

      // Assert
      expect(hasChanged, isFalse);
    });

    test('should detect field type changes', () async {
      // Arrange
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'age': {'type': 'int', 'nullable': false},
        },
        'indexes': [],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'age': {'type': 'double', 'nullable': false},
        },
        'indexes': [],
      };

      // Act
      final hasChanged =
          migrationBuilder.hasSchemaChanged(oldSchema, newSchema);

      // Assert
      expect(hasChanged, isTrue);
    });

    test('should detect nullable changes', () async {
      // Arrange
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
          'name': {'type': 'String', 'nullable': true},
        },
        'indexes': [],
      };

      // Act
      final hasChanged =
          migrationBuilder.hasSchemaChanged(oldSchema, newSchema);

      // Assert
      expect(hasChanged, isTrue);
    });

    test('should detect index changes', () async {
      // Arrange
      final oldSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'email': {'type': 'String', 'nullable': false},
        },
        'indexes': [
          {
            'name': 'email_idx',
            'fields': ['email'],
            'unique': false,
          }
        ],
      };

      final newSchema = {
        'fields': {
          'id': {'type': 'String', 'nullable': false},
          'email': {'type': 'String', 'nullable': false},
        },
        'indexes': [
          {
            'name': 'email_idx',
            'fields': ['email'],
            'unique': true,
          }
        ],
      };

      // Act
      final hasChanged =
          migrationBuilder.hasSchemaChanged(oldSchema, newSchema);

      // Assert
      expect(hasChanged, isTrue);
    });
  });
}

class MockLSMStorage extends LSMStorage {
  MockLSMStorage() : super('test_db');

  @override
  Future<T?> get<T>(String key) async {
    return null;
  }

  @override
  Future<void> put<T>(String key, T value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<List<T>> getAll<T>() async {
    return [];
  }
}

class MockSchemaStorage extends SchemaStorage {
  MockSchemaStorage()
      : _mockStorage = MockLSMStorage(),
        super(MockLSMStorage());
  final MockLSMStorage _mockStorage;

  final Map<String, dynamic> _mockData = {};

  @override
  LSMStorage get storage => _mockStorage;

  @override
  Future<Map<String, dynamic>> getSchema(String entityName) async {
    return _mockData[entityName] ?? {};
  }

  Future<void> putSchema(String entityName, Map<String, dynamic> schema) async {
    _mockData[entityName] = schema;
  }

  @override
  Future<int> getVersion(String entityName) async {
    return _mockData['version:$entityName'] ?? 1;
  }

  Future<void> putVersion(String entityName, int version) async {
    _mockData['version:$entityName'] = version;
  }
}
