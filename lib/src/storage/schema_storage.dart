import 'dart:convert';
import 'package:quanta_db/src/storage/lsm_storage.dart';

/// Manages the storage and retrieval of schema information for QuantaDB entities.
///
/// This class handles:
/// - Schema version tracking
/// - Schema storage and retrieval
/// - Migration history management
/// - Schema rollback operations
///
/// It uses the underlying [LSMStorage] to persist schema information and provides
/// methods for managing schema versions and migrations.
class SchemaStorage {
  SchemaStorage(this._storage);
  final LSMStorage _storage;
  static const _schemaPrefix = 'schema:';
  static const _versionPrefix = 'version:';
  static const _migrationHistoryPrefix = 'migration:';

  LSMStorage get storage => _storage;

  /// Get the current version of a model
  Future<int> getVersion(String modelName) async {
    final versionKey = '$_versionPrefix$modelName';
    final versionStr = await _storage.get(versionKey);
    return versionStr != null ? int.parse(versionStr) : 1;
  }

  /// Set the version of a model
  Future<void> setVersion(String modelName, int version) async {
    final versionKey = '$_versionPrefix$modelName';
    await _storage.put(versionKey, version.toString());
  }

  /// Get the schema of a model
  Future<Map<String, dynamic>> getSchema(String modelName) async {
    final schemaKey = '$_schemaPrefix$modelName';
    final schemaStr = await _storage.get(schemaKey);
    return schemaStr != null ? json.decode(schemaStr) : {};
  }

  /// Set the schema of a model
  Future<void> setSchema(String modelName, Map<String, dynamic> schema) async {
    final schemaKey = '$_schemaPrefix$modelName';
    await _storage.put(schemaKey, json.encode(schema));
  }

  /// Record a migration in the history
  Future<void> recordMigration(
    String modelName,
    int fromVersion,
    int toVersion,
    Map<String, dynamic> changes,
  ) async {
    final historyKey = '$_migrationHistoryPrefix$modelName';
    final historyStr = await _storage.get(historyKey);
    final history = historyStr != null ? json.decode(historyStr) as List : [];

    history.add({
      'timestamp': DateTime.now().toIso8601String(),
      'fromVersion': fromVersion,
      'toVersion': toVersion,
      'changes': changes,
    });

    await _storage.put(historyKey, json.encode(history));
  }

  /// Get migration history for a model
  Future<List<Map<String, dynamic>>> getMigrationHistory(
      String modelName) async {
    final historyKey = '$_migrationHistoryPrefix$modelName';
    final historyStr = await _storage.get(historyKey);
    return historyStr != null
        ? List<Map<String, dynamic>>.from(json.decode(historyStr))
        : [];
  }

  /// Check if a migration is needed
  Future<bool> needsMigration(String modelName, int targetVersion) async {
    final currentVersion = await getVersion(modelName);
    return currentVersion != targetVersion;
  }

  /// Get the latest migration for a model
  Future<Map<String, dynamic>?> getLatestMigration(String modelName) async {
    final history = await getMigrationHistory(modelName);
    return history.isNotEmpty ? history.last : null;
  }

  /// Rollback to a specific version
  Future<void> rollbackToVersion(String modelName, int targetVersion) async {
    final currentVersion = await getVersion(modelName);
    if (currentVersion <= targetVersion) return;

    final history = await getMigrationHistory(modelName);
    final relevantMigrations = history
        .where((m) =>
            m['fromVersion'] >= targetVersion &&
            m['toVersion'] <= currentVersion)
        .toList();

    for (final migration in relevantMigrations.reversed) {
      // Apply rollback changes
      final changes = migration['changes'] as Map<String, dynamic>;
      final schema = await getSchema(modelName);

      // Revert field changes
      if (changes['added'] != null) {
        for (final field in changes['added']) {
          schema['fields'].remove(field['name']);
        }
      }

      if (changes['removed'] != null) {
        for (final field in changes['removed']) {
          schema['fields'][field['name']] = {
            'type': field['type'],
            'nullable': field['nullable'],
          };
        }
      }

      if (changes['modified'] != null) {
        for (final field in changes['modified']) {
          schema['fields'][field['name']] = {
            'type': field['oldType'],
            'nullable': field['oldNullable'],
          };
        }
      }

      // Revert index changes
      if (changes['indexChanges'] != null) {
        for (final change in changes['indexChanges']) {
          if (change['type'] == 'added') {
            schema['indexes']
                .removeWhere((i) => i['name'] == change['index']['name']);
          } else if (change['type'] == 'removed') {
            schema['indexes'].add(change['index']);
          }
        }
      }

      await setSchema(modelName, schema);
    }

    await setVersion(modelName, targetVersion);
  }

  /// Get all models and their versions
  Future<Map<String, int>> getAllModelVersions() async {
    final models = <String, int>{};
    final keys = await _storage.keys();

    for (final key in keys) {
      if (key.startsWith(_versionPrefix)) {
        final modelName = key.substring(_versionPrefix.length);
        final version = await getVersion(modelName);
        models[modelName] = version;
      }
    }

    return models;
  }
}
