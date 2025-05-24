import 'dart:typed_data';
import 'package:quanta_db/quanta_db.dart';
import 'package:quanta_db/annotations/quanta_annotations.dart';
import 'package:quanta_db/storage/storage_manager.dart';
import 'package:quanta_db/serialization/serializer.dart';

/// Manages indexes for entities
class IndexManager {
  IndexManager(this._storage, this._serializer);
  final StorageManager _storage;
  final Serializer _serializer;
  final Map<String, Map<String, Index>> indexes = {};

  /// Initialize indexes for an entity
  Future<void> initializeIndexes(
      String entityName, Map<String, dynamic> schema) async {
    indexes[entityName] = {};

    // Create primary key index
    final primaryKey = schema['primaryKey'] as String;
    indexes[entityName]!['primary'] = Index(
      name: 'primary',
      fields: [primaryKey],
      unique: true,
      order: IndexOrder.ascending,
    );

    // Create single field indexes
    for (final field in schema['fields'].keys) {
      final fieldSchema = schema['fields'][field];
      if (fieldSchema['indexed'] == true) {
        final indexName = fieldSchema['indexName'] ?? field;
        indexes[entityName]![indexName] = Index(
          name: indexName,
          fields: [field],
          unique: fieldSchema['unique'] ?? false,
          order: fieldSchema['order'] ?? IndexOrder.ascending,
        );
      }
    }

    // Create composite indexes
    if (schema['compositeIndexes'] != null) {
      for (final index in schema['compositeIndexes']) {
        final indexName = index['name'] ?? index['fields'].join('_');
        indexes[entityName]![indexName] = Index(
          name: indexName,
          fields: List<String>.from(index['fields']),
          unique: index['unique'] ?? false,
          order: index['order'] ?? IndexOrder.ascending,
        );
      }
    }
  }

  /// Add a document to all relevant indexes
  Future<void> addToIndexes(
      String entityName, String id, Map<String, dynamic> document) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return;

    for (final index in entityIndexes.values) {
      await _addToIndex(entityName, index, id, document);
    }
  }

  /// Remove a document from all indexes
  Future<void> removeFromIndexes(
      String entityName, String id, Map<String, dynamic> document) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return;

    for (final index in entityIndexes.values) {
      await _removeFromIndex(entityName, index, id, document);
    }
  }

  /// Update a document in all indexes
  Future<void> updateIndexes(
      String entityName,
      String id,
      Map<String, dynamic> oldDocument,
      Map<String, dynamic> newDocument) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return;

    for (final index in entityIndexes.values) {
      await _updateIndex(entityName, index, id, oldDocument, newDocument);
    }
  }

  /// Get all documents matching an index query
  Future<List<String>> queryIndex(
      String entityName, String indexName, dynamic value) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return [];

    final index = entityIndexes[indexName];
    if (index == null) return [];

    final key = _getIndexKey(entityName, index, value);
    final result = await _storage.get(Uint8List.fromList(key.codeUnits));
    if (result == null) return [];

    return _deserializeIds(result);
  }

  /// Get all documents matching a range query on an index
  Future<List<String>> queryIndexRange(String entityName, String indexName,
      dynamic startValue, dynamic endValue) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return [];

    final index = entityIndexes[indexName];
    if (index == null) return [];

    final startKey = _getIndexKey(entityName, index, startValue);
    final endKey = _getIndexKey(entityName, index, endValue);

    // Get all keys in range
    final allKeys = await _storage.keys();
    final rangeKeys = allKeys.where((key) {
      final keyStr = String.fromCharCodes(key);
      return keyStr.compareTo(startKey) >= 0 && keyStr.compareTo(endKey) <= 0;
    }).toList();

    final ids = <String>{};
    for (final key in rangeKeys) {
      final result = await _storage.get(key);
      if (result != null) {
        ids.addAll(_deserializeIds(result));
      }
    }
    return ids.toList();
  }

  /// Check if an index exists
  bool hasIndex(String entityName, String indexName) {
    return indexes[entityName]?.containsKey(indexName) ?? false;
  }

  /// Get all indexes for an entity
  List<Index> getEntityIndexes(String entityName) {
    return indexes[entityName]?.values.toList() ?? [];
  }

  /// Add a new index
  Future<void> addIndex(
      String entityName, String indexName, List<String> fields,
      {bool unique = false, IndexOrder order = IndexOrder.ascending}) async {
    if (!indexes.containsKey(entityName)) {
      indexes[entityName] = {};
    }

    indexes[entityName]![indexName] = Index(
      name: indexName,
      fields: fields,
      unique: unique,
      order: order,
    );

    // Reindex all documents
    final allKeys = await _storage.keys();
    final entityKeys = allKeys.where((key) {
      final keyStr = String.fromCharCodes(key);
      return keyStr.startsWith('$entityName:');
    }).toList();

    for (final key in entityKeys) {
      final result = await _storage.get(key);
      if (result != null) {
        final id = String.fromCharCodes(key).split(':').last;
        final document = _serializer.deserialize(result);
        await _addToIndex(
            entityName, indexes[entityName]![indexName]!, id, document);
      }
    }
  }

  /// Remove an index
  Future<void> removeIndex(String entityName, String indexName) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return;

    final index = entityIndexes.remove(indexName);
    if (index == null) return;

    // Remove all index entries
    final allKeys = await _storage.keys();
    final indexKeys = allKeys.where((key) {
      final keyStr = String.fromCharCodes(key);
      return keyStr.startsWith('${entityName}_${indexName}_');
    }).toList();

    for (final key in indexKeys) {
      await _storage.delete(key);
    }
  }

  /// Rebuild all indexes for an entity
  Future<void> rebuildIndexes(String entityName) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return;

    // Clear all existing indexes
    for (final index in entityIndexes.values) {
      final allKeys = await _storage.keys();
      final indexKeys = allKeys.where((key) {
        final keyStr = String.fromCharCodes(key);
        return keyStr.startsWith('${entityName}_${index.name}_');
      }).toList();

      for (final key in indexKeys) {
        await _storage.delete(key);
      }
    }

    // Rebuild indexes
    final allKeys = await _storage.keys();
    final entityKeys = allKeys.where((key) {
      final keyStr = String.fromCharCodes(key);
      return keyStr.startsWith('$entityName:');
    }).toList();

    for (final key in entityKeys) {
      final result = await _storage.get(key);
      if (result != null) {
        final id = String.fromCharCodes(key).split(':').last;
        final document = _serializer.deserialize(result);
        await addToIndexes(entityName, id, document);
      }
    }
  }

  /// Get index statistics
  Future<Map<String, dynamic>> getIndexStats(String entityName) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return {};

    final stats = <String, dynamic>{};
    for (final index in entityIndexes.values) {
      final allKeys = await _storage.keys();
      final indexKeys = allKeys.where((key) {
        final keyStr = String.fromCharCodes(key);
        return keyStr.startsWith('${entityName}_${index.name}_');
      }).toList();

      stats[index.name] = {
        'entries': indexKeys.length,
        'fields': index.fields,
        'unique': index.unique,
        'order': index.order.toString(),
      };
    }
    return stats;
  }

  /// Find documents by composite index
  Future<List<String>> findByCompositeIndex(
      String entityName, String indexName, Map<String, dynamic> values) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return [];

    final index = entityIndexes[indexName];
    if (index == null) return [];

    final key = _getIndexKey(entityName, index, values);
    final result = await _storage.get(Uint8List.fromList(key.codeUnits));
    return result != null ? _deserializeIds(result) : [];
  }

  String _getIndexKey(String entityName, Index index, dynamic value) {
    final values = index.fields.map((field) => value[field]).toList();
    return '${entityName}_${index.name}_${values.join('_')}';
  }

  Future<void> _addToIndex(String entityName, Index index, String id,
      Map<String, dynamic> document) async {
    final key = _getIndexKey(entityName, index, document);
    final existingIds = await _getIndexedIds(Uint8List.fromList(key.codeUnits));

    if (index.unique && existingIds.isNotEmpty) {
      throw Exception('Unique index violation for ${index.name}');
    }

    existingIds.add(id);
    await _storage.put(
        Uint8List.fromList(key.codeUnits), _serializeIds(existingIds));
  }

  Future<void> _removeFromIndex(String entityName, Index index, String id,
      Map<String, dynamic> document) async {
    final key = _getIndexKey(entityName, index, document);
    final existingIds = await _getIndexedIds(Uint8List.fromList(key.codeUnits));

    existingIds.remove(id);
    if (existingIds.isEmpty) {
      await _storage.delete(Uint8List.fromList(key.codeUnits));
    } else {
      await _storage.put(
          Uint8List.fromList(key.codeUnits), _serializeIds(existingIds));
    }
  }

  Future<void> _updateIndex(
      String entityName,
      Index index,
      String id,
      Map<String, dynamic> oldDocument,
      Map<String, dynamic> newDocument) async {
    await _removeFromIndex(entityName, index, id, oldDocument);
    await _addToIndex(entityName, index, id, newDocument);
  }

  Future<List<String>> _getIndexedIds(Uint8List key) async {
    final result = await _storage.get(key);
    return result != null ? _deserializeIds(result) : [];
  }

  Uint8List _serializeIds(List<String> ids) {
    return Uint8List.fromList(ids.join(',').codeUnits);
  }

  List<String> _deserializeIds(Uint8List data) {
    return String.fromCharCodes(data).split(',');
  }
}

/// Represents an index
class Index {
  const Index({
    required this.name,
    required this.fields,
    this.unique = false,
    this.order = IndexOrder.ascending,
  });

  final String name;
  final List<String> fields;
  final bool unique;
  final IndexOrder order;
}
