import 'package:flutter_test/flutter_test.dart';
import 'package:quanta_db/index/index_manager.dart';
import 'package:quanta_db/storage/storage_manager.dart';
import 'package:quanta_db/serialization/serializer.dart';

void main() {
  //
  // Storage manager instance for handling data persistence
  late StorageManager storage;
  // Serializer instance for converting data to/from storage format
  late Serializer serializer;
  // Index manager instance for handling database indexes
  late IndexManager indexManager;

  setUp(() {
    storage = StorageManager('test_db');
    serializer = Serializer();
    indexManager = IndexManager(storage, serializer);
  });

  group('IndexManager', () {
    test('should initialize indexes correctly', () async {
      final schema = {
        'primaryKey': 'id',
        'fields': {
          'id': {'type': 'String'},
          'name': {'type': 'String', 'indexed': true},
          'age': {'type': 'int', 'indexed': true},
        },
        'compositeIndexes': [
          {
            'fields': ['name', 'age'],
            'name': 'name_age_idx',
            'unique': true,
          },
        ],
      };

      await indexManager.initializeIndexes('User', schema);

      // Verify primary key index
      final primaryIndex = indexManager.indexes['User']!['primary']!;
      expect(primaryIndex.name, equals('primary'));
      expect(primaryIndex.fields, equals(['id']));
      expect(primaryIndex.unique, isTrue);

      // Verify single field indexes
      final nameIndex = indexManager.indexes['User']!['name']!;
      expect(nameIndex.name, equals('name'));
      expect(nameIndex.fields, equals(['name']));
      expect(nameIndex.unique, isFalse);

      final ageIndex = indexManager.indexes['User']!['age']!;
      expect(ageIndex.name, equals('age'));
      expect(ageIndex.fields, equals(['age']));
      expect(ageIndex.unique, isFalse);

      // Verify composite index
      final compositeIndex = indexManager.indexes['User']!['name_age_idx']!;
      expect(compositeIndex.name, equals('name_age_idx'));
      expect(compositeIndex.fields, equals(['name', 'age']));
      expect(compositeIndex.unique, isTrue);
    });

    test('should add and find documents by composite index', () async {
      final schema = {
        'primaryKey': 'id',
        'fields': {
          'id': {'type': 'String'},
          'name': {'type': 'String'},
          'age': {'type': 'int'},
        },
        'compositeIndexes': [
          {
            'fields': ['name', 'age'],
            'name': 'name_age_idx',
            'unique': true,
          },
        ],
      };

      await indexManager.initializeIndexes('User', schema);

      // Add a document
      final document = {
        'id': '1',
        'name': 'John',
        'age': 30,
      };
      await indexManager.addToIndexes('User', '1', document);

      // Find by composite index
      final ids = await indexManager.findByCompositeIndex(
        'User',
        'name_age_idx',
        {'name': 'John', 'age': 30},
      );
      expect(ids, equals(['1']));

      // Find with non-matching values
      final nonMatchingIds = await indexManager.findByCompositeIndex(
        'User',
        'name_age_idx',
        {'name': 'John', 'age': 31},
      );
      expect(nonMatchingIds, isEmpty);
    });

    test('should remove documents from indexes', () async {
      final schema = {
        'primaryKey': 'id',
        'fields': {
          'id': {'type': 'String'},
          'name': {'type': 'String'},
          'age': {'type': 'int'},
        },
        'compositeIndexes': [
          {
            'fields': ['name', 'age'],
            'name': 'name_age_idx',
            'unique': true,
          },
        ],
      };

      await indexManager.initializeIndexes('User', schema);

      // Add a document
      final document = {
        'id': '1',
        'name': 'John',
        'age': 30,
      };
      await indexManager.addToIndexes('User', '1', document);

      // Verify document exists in index
      var ids = await indexManager.findByCompositeIndex(
        'User',
        'name_age_idx',
        {'name': 'John', 'age': 30},
      );
      expect(ids, equals(['1']));

      // Remove document from indexes
      await indexManager.removeFromIndexes('User', '1', document);

      // Verify document is removed from index
      ids = await indexManager.findByCompositeIndex(
        'User',
        'name_age_idx',
        {'name': 'John', 'age': 30},
      );
      expect(ids, isEmpty);
    });
  });
}
