import 'dart:async';
import 'package:quanta_db/src/storage/lsm_storage.dart';
import 'package:quanta_db/src/schema/schema_migration.dart';
import 'dart:io';

/// Represents a schema version
class SchemaVersion {
  const SchemaVersion(this.version, this.migrations);
  final int version;
  final List<SchemaMigration> migrations;
}

/// Manages schema migrations
class SchemaManager {
  SchemaManager(this._storage);

  final LSMStorage _storage;
  final _versions = <SchemaVersion>[];

  /// Register a schema version with its migrations
  void registerVersion(SchemaVersion version) {
    _versions.add(version);
    _versions.sort((a, b) => a.version.compareTo(b.version));
  }

  /// Get the current schema version
  Future<int> getCurrentVersion() async {
    final version = await _storage.get<int>('__schema_version__');
    return version ?? 0;
  }

  /// Migrate to a specific version
  Future<void> migrateTo(int targetVersion) async {
    final currentVersion = await getCurrentVersion();
    if (currentVersion == targetVersion) return;

    if (targetVersion > currentVersion) {
      // Migrate up
      for (var version in _versions) {
        if (version.version > currentVersion &&
            version.version <= targetVersion) {
          for (final migration in version.migrations) {
            await migration.up(_storage);
          }
        }
      }
    } else {
      // Migrate down
      for (var version in _versions.reversed) {
        if (version.version <= currentVersion &&
            version.version > targetVersion) {
          for (final migration in version.migrations.reversed) {
            await migration.down(_storage);
          }
        }
      }
    }

    await _storage.put('__schema_version__', targetVersion);
  }

  /// Create a new migration
  Future<void> createMigration(String name, int version) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final migration = '''
import 'package:quanta_db/src/schema/schema_migration.dart';
import 'package:quanta_db/src/storage/lsm_storage.dart';

class ${_toPascalCase(name)}Migration implements SchemaMigration {
  @override
  Future<void> up(LSMStorage storage) async {
    // TODO: Implement up migration
  }

  @override
  Future<void> down(LSMStorage storage) async {
    // TODO: Implement down migration
  }
}
''';

    final fileName = '${timestamp}_${_toSnakeCase(name)}.dart';
    final file = File('lib/migrations/$fileName');
    await file.create(recursive: true);
    await file.writeAsString(migration);
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .toLowerCase()
        .replaceAll(RegExp(r'^_'), '');
  }
}
