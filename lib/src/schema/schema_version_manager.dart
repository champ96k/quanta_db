import 'dart:async';
import 'package:quanta_db/src/schema/schema_migration.dart';
import 'package:quanta_db/src/storage/lsm_storage.dart';

/// Registry to store and manage migrations
class MigrationRegistry {
  MigrationRegistry._();

  static final Map<String, SchemaMigration> _migrations = {};

  /// Register a migration class
  static void register(String name, SchemaMigration migration) {
    _migrations[name] = migration;
  }

  /// Get a registered migration
  static SchemaMigration? get(String name) {
    return _migrations[name];
  }

  /// Check if a migration is registered
  static bool has(String name) {
    return _migrations.containsKey(name);
  }

  /// Get all registered migrations
  static Map<String, SchemaMigration> getAll() {
    return Map.unmodifiable(_migrations);
  }

  /// Clear all registered migrations
  static void clear() {
    _migrations.clear();
  }
}

/// Manages schema versions and migrations for QuantaDB entities.
///
/// This class handles:
/// - Tracking and updating schema versions for each entity
/// - Recording and retrieving migration history
/// - Rolling back to previous schema versions
/// - Loading and executing migration classes
/// - Importing and exporting schema version information
///
/// It uses the underlying [LSMStorage] to persist version and migration data.
class SchemaVersionManager {
  SchemaVersionManager(this._storage) : _versionCache = {};

  final LSMStorage _storage;
  final Map<String, int> _versionCache;
  static const String _versionPrefix = 'schema:version:';
  static const String _migrationHistoryPrefix = 'schema:migration:';

  /// Get the current version of an entity
  Future<int> getVersion(String entityName) async {
    // Check cache first
    if (_versionCache.containsKey(entityName)) {
      return _versionCache[entityName]!;
    }

    // Get from storage
    final version = await _storage.get<int>('$_versionPrefix$entityName') ?? 1;
    _versionCache[entityName] = version;
    return version;
  }

  /// Set the version of an entity
  Future<void> setVersion(String entityName, int version) async {
    await _storage.put('$_versionPrefix$entityName', version);
    _versionCache[entityName] = version;
  }

  /// Record a migration in history
  Future<void> recordMigration(
    String entityName,
    int fromVersion,
    int toVersion,
    String migrationName,
  ) async {
    final history = await getMigrationHistory(entityName);
    history.add({
      'timestamp': DateTime.now().toIso8601String(),
      'fromVersion': fromVersion,
      'toVersion': toVersion,
      'migrationName': migrationName,
    });
    await _storage.put('$_migrationHistoryPrefix$entityName', history);
  }

  /// Get migration history for an entity
  Future<List<Map<String, dynamic>>> getMigrationHistory(
      String entityName) async {
    final history = await _storage
        .get<List<dynamic>>('$_migrationHistoryPrefix$entityName');
    if (history == null) return [];
    return history.cast<Map<String, dynamic>>();
  }

  /// Check if a migration is needed
  Future<bool> needsMigration(String entityName, int targetVersion) async {
    final currentVersion = await getVersion(entityName);
    return currentVersion < targetVersion;
  }

  /// Get the next version number for an entity
  Future<int> getNextVersion(String entityName) async {
    final currentVersion = await getVersion(entityName);
    return currentVersion + 1;
  }

  /// Validate schema version
  Future<bool> validateSchemaVersion(
      String entityName, int expectedVersion) async {
    final currentVersion = await getVersion(entityName);
    return currentVersion == expectedVersion;
  }

  /// Rollback to a specific version
  Future<void> rollbackToVersion(String entityName, int targetVersion) async {
    final currentVersion = await getVersion(entityName);
    if (currentVersion <= targetVersion) {
      throw Exception(
          'Cannot rollback to a version that is not lower than current version');
    }

    final history = await getMigrationHistory(entityName);
    final rollbackHistory =
        history.where((m) => m['toVersion'] > targetVersion).toList();

    for (final migration in rollbackHistory.reversed) {
      final migrationName = migration['migrationName'] as String;
      final fromVersion = migration['fromVersion'] as int;

      // Load the migration class
      final migrationClass = await loadMigrationClass(migrationName);
      if (migrationClass != null) {
        // Execute the down migration
        await migrationClass.down(_storage);
      }

      // Update version
      await setVersion(entityName, fromVersion);
    }
  }

  /// Load a migration class by name
  Future<SchemaMigration?> loadMigrationClass(String migrationName) async {
    try {
      // Check if the migration is registered
      if (MigrationRegistry.has(migrationName)) {
        return MigrationRegistry.get(migrationName);
      }

      // If not found in registry, throw an error
      throw Exception(
          'Migration not found: $migrationName. Make sure to register it using MigrationRegistry.register()');
    } catch (e) {
      // ignore: avoid_print
      print('Error loading migration $migrationName: $e');
      return null;
    }
  }

  /// Export schema version information
  Future<Map<String, dynamic>> exportSchemaInfo() async {
    final entities = await _storage.getAll<String>();
    final schemaInfo = <String, dynamic>{};

    for (final entity in entities) {
      if (entity.startsWith(_versionPrefix)) {
        final entityName = entity.substring(_versionPrefix.length);
        final version = await getVersion(entityName);
        final history = await getMigrationHistory(entityName);

        schemaInfo[entityName] = {
          'currentVersion': version,
          'migrationHistory': history,
        };
      }
    }

    return schemaInfo;
  }

  /// Import schema version information
  Future<void> importSchemaInfo(Map<String, dynamic> schemaInfo) async {
    for (final entry in schemaInfo.entries) {
      final entityName = entry.key;
      final info = entry.value as Map<String, dynamic>;

      await setVersion(entityName, info['currentVersion'] as int);
      await _storage.put(
          '$_migrationHistoryPrefix$entityName', info['migrationHistory']);
    }
  }
}
