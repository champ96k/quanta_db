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
      // Only use the indexed fields for the key
      final indexFieldsMap = {
        for (final field in index.fields) field: document[field]
      };
      final key = _buildIndexKey(index, indexFieldsMap);
      if (key != null) {
        final storageKey = _getIndexKey(entityName, index.name, key);
        await _storage.put(storageKey, Uint8List.fromList(id.codeUnits));
      }
    }
  }

  /// Remove a document from all indexes
  Future<void> removeFromIndexes(
      String entityName, String id, Map<String, dynamic> document) async {
    final entityIndexes = indexes[entityName];
    if (entityIndexes == null) return;

    for (final index in entityIndexes.values) {
      // Only use the indexed fields for the key, matching addToIndexes
      final indexFieldsMap = {
        for (final field in index.fields) field: document[field]
      };
      final key = _buildIndexKey(index, indexFieldsMap);
      if (key != null) {
        await _storage.delete(_getIndexKey(entityName, index.name, key));
      }
    }
  }

  /// Find documents by index
  Future<List<String>> findByIndex(
      String entityName, String indexName, dynamic value) async {
    final index = indexes[entityName]?[indexName];
    if (index == null) return [];

    final key = _buildIndexKey(index, {index.fields.first: value});
    if (key == null) return [];

    final idBytes =
        await _storage.get(_getIndexKey(entityName, indexName, key));
    return idBytes != null ? [String.fromCharCodes(idBytes)] : [];
  }

  /// Find documents by composite index
  Future<List<String>> findByCompositeIndex(
    String entityName,
    String indexName,
    Map<String, dynamic> values,
  ) async {
    final index = indexes[entityName]?[indexName];
    if (index == null) return [];

    final key = _buildIndexKey(index, values);
    if (key == null) return [];

    final storageKey = _getIndexKey(entityName, indexName, key);

    final idBytes = await _storage.get(storageKey);
    if (idBytes == null) {
      return [];
    }
    return [String.fromCharCodes(idBytes)];
  }

  /// Build index key from document values
  Uint8List? _buildIndexKey(Index index, Map<String, dynamic> document) {
    try {
      // Ensure values are in the correct order and type
      final values = index.fields.map((field) {
        final value = document[field];
        if (value == null) return null;
        // Convert numbers to double for consistency
        if (value is num) return value.toDouble();
        return value;
      }).toList();

      if (values.any((v) => v == null)) return null;

      // Serialize the list of values
      return _serializer.serialize(values);
    } catch (e) {
      return null;
    }
  }

  /// Get storage key for index
  Uint8List _getIndexKey(String entityName, String indexName, Uint8List key) {
    final prefix = 'index:$entityName:$indexName:';
    final result = Uint8List(prefix.codeUnits.length + key.length);
    result.setAll(0, prefix.codeUnits);
    result.setAll(prefix.codeUnits.length, key);
    return result;
  }
}

/// Represents an index configuration
class Index {
  Index({
    required this.name,
    required this.fields,
    required this.unique,
    required this.order,
  });
  final String name;
  final List<String> fields;
  final bool unique;
  final IndexOrder order;
}
