import 'dart:typed_data';
import 'package:quanta_db/storage/storage_manager.dart';

/// Manages relationships between entities
class RelationshipManager {
  RelationshipManager(this._storage);
  final StorageManager _storage;
  final Map<String, Map<String, Relationship>> relationships = {};

  /// Initialize relationships for an entity
  Future<void> initializeRelationships(
      String entityName, Map<String, dynamic> schema) async {
    relationships[entityName] = {};

    if (schema['relationships'] != null) {
      for (final rel in schema['relationships']) {
        final relName = rel['name'];
        relationships[entityName]![relName] = Relationship(
          name: relName,
          type: rel['type'],
          targetEntity: rel['targetEntity'],
          foreignKey: rel['foreignKey'],
          joinTable: rel['joinTable'],
          cascade: rel['cascade'] ?? false,
        );
      }
    }
  }

  /// Add a one-to-many relationship
  Future<void> addOneToMany(
    String entityName,
    String relationshipName,
    String sourceId,
    String targetId,
  ) async {
    final relationship = relationships[entityName]?[relationshipName];
    if (relationship == null || relationship.type != 'hasMany') return;

    final key =
        _getRelationshipKey(entityName, relationshipName, sourceId, targetId);
    await _storage.put(
        key, Uint8List.fromList([1])); // 1 indicates active relationship
  }

  /// Add a many-to-many relationship
  Future<void> addManyToMany(
    String entityName,
    String relationshipName,
    String sourceId,
    String targetId,
  ) async {
    final relationship = relationships[entityName]?[relationshipName];
    if (relationship == null || relationship.type != 'manyToMany') return;

    final key =
        _getRelationshipKey(entityName, relationshipName, sourceId, targetId);
    await _storage.put(
        key, Uint8List.fromList([1])); // 1 indicates active relationship
  }

  /// Remove a relationship
  Future<void> removeRelationship(
    String entityName,
    String relationshipName,
    String sourceId,
    String targetId,
  ) async {
    final relationship = relationships[entityName]?[relationshipName];
    if (relationship == null) return;

    final key =
        _getRelationshipKey(entityName, relationshipName, sourceId, targetId);
    await _storage.delete(key);

    // For many-to-many relationships, also remove the reverse relationship
    if (relationship.type == 'manyToMany') {
      final reverseKey = _getRelationshipKey(
        relationship.targetEntity,
        relationshipName,
        targetId,
        sourceId,
      );
      await _storage.delete(reverseKey);
    }
  }

  /// Get all related entities
  Future<List<String>> getRelatedIds(
    String entityName,
    String relationshipName,
    String sourceId,
  ) async {
    final relationship = relationships[entityName]?[relationshipName];
    if (relationship == null) return [];

    final prefix =
        _getRelationshipPrefix(entityName, relationshipName, sourceId);
    final keys = await _storage.getKeysWithPrefix(prefix);
    return keys.map((key) => _extractTargetId(key)).toList();
  }

  /// Handle cascade delete
  Future<void> handleCascadeDelete(
    String entityName,
    String relationshipName,
    String sourceId,
  ) async {
    final relationship = relationships[entityName]?[relationshipName];
    if (relationship == null || !relationship.cascade) return;

    final relatedIds =
        await getRelatedIds(entityName, relationshipName, sourceId);

    // Delete all relationships first
    for (final targetId in relatedIds) {
      await removeRelationship(
          entityName, relationshipName, sourceId, targetId);
    }

    // Then delete the related entities
    for (final targetId in relatedIds) {
      final targetKey = _getEntityKey(relationship.targetEntity, targetId);
      await _storage.delete(targetKey);
    }
  }

  /// Get relationship key
  Uint8List _getRelationshipKey(
    String entityName,
    String relationshipName,
    String sourceId,
    String targetId,
  ) {
    // Use a clear separator to avoid accidental prefix matches
    return Uint8List.fromList(
      'rel|$entityName|$relationshipName|$sourceId|$targetId'.codeUnits,
    );
  }

  /// Get relationship prefix for querying
  Uint8List _getRelationshipPrefix(
    String entityName,
    String relationshipName,
    String sourceId,
  ) {
    // Prefix must match the key up to the separator before targetId
    return Uint8List.fromList(
      'rel|$entityName|$relationshipName|$sourceId|'.codeUnits,
    );
  }

  /// Get entity key
  Uint8List _getEntityKey(String entityName, String id) {
    return Uint8List.fromList([
      ...'entity:$entityName:$id'.codeUnits,
    ]);
  }

  /// Extract target ID from relationship key
  String _extractTargetId(Uint8List key) {
    final keyStr = String.fromCharCodes(key);
    // Split by '|' and get the last part
    return keyStr.split('|').last;
  }
}

/// Represents a relationship configuration
class Relationship {
  Relationship({
    required this.name,
    required this.type,
    required this.targetEntity,
    this.foreignKey,
    this.joinTable,
    required this.cascade,
  });
  final String name;
  final String type;
  final String targetEntity;
  final String? foreignKey;
  final String? joinTable;
  final bool cascade;
}
