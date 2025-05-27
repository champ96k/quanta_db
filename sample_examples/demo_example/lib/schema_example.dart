import 'package:quanta_db/quanta_db.dart';

// Example migration for creating a users table
class CreateUsersTable implements SchemaMigration {
  @override
  Future<void> up(LSMStorage storage) async {
    // Create users table schema
    await storage.put('users:schema', {
      'fields': ['id', 'name', 'email'],
      'indexes': ['email'],
    });

    // Add some initial data
    await storage.put('users:1', {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
    });
  }

  @override
  Future<void> down(LSMStorage storage) async {
    // Remove all user data
    final keys = await storage.getAll<String>();
    for (final key in keys) {
      if (key.startsWith('users:')) {
        await storage.delete(key);
      }
    }
  }
}

// Example migration for adding a new field
class AddUserAge implements SchemaMigration {
  @override
  Future<void> up(LSMStorage storage) async {
    // Update schema to include age field
    final schema = await storage.get<Map<String, dynamic>>('users:schema');
    if (schema != null) {
      schema['fields'].add('age');
      await storage.put('users:schema', schema);
    }

    // Update existing users with age
    final keys = await storage.getAll<String>();
    for (final key in keys) {
      if (key.startsWith('users:') && !key.endsWith(':schema')) {
        final user = await storage.get<Map<String, dynamic>>(key);
        if (user != null) {
          user['age'] = 25; // Default age
          await storage.put(key, user);
        }
      }
    }
  }

  @override
  Future<void> down(LSMStorage storage) async {
    // Remove age field from schema
    final schema = await storage.get<Map<String, dynamic>>('users:schema');
    if (schema != null) {
      schema['fields'].remove('age');
      await storage.put('users:schema', schema);
    }

    // Remove age from all users
    final keys = await storage.getAll<String>();
    for (final key in keys) {
      if (key.startsWith('users:') && !key.endsWith(':schema')) {
        final user = await storage.get<Map<String, dynamic>>(key);
        if (user != null) {
          user.remove('age');
          await storage.put(key, user);
        }
      }
    }
  }
}

void main() async {
  // Initialize storage
  final storage = LSMStorage('example.db');
  await storage.init();

  // Register migrations
  MigrationRegistry.register('CreateUsersTable', CreateUsersTable());
  MigrationRegistry.register('AddUserAge', AddUserAge());

  // Create schema version manager
  final schemaManager = SchemaVersionManager(storage);

  try {
    // Run initial migration
    print('Running initial migration...');
    final createUsersMigration =
        await schemaManager.loadMigrationClass('CreateUsersTable');
    if (createUsersMigration != null) {
      await createUsersMigration.up(storage);
      await schemaManager.recordMigration('users', 1, 2, 'CreateUsersTable');
      await schemaManager.setVersion('users', 2);
    }

    // Run second migration
    print('Running second migration...');
    final addAgeMigration =
        await schemaManager.loadMigrationClass('AddUserAge');
    if (addAgeMigration != null) {
      await addAgeMigration.up(storage);
      await schemaManager.recordMigration('users', 2, 3, 'AddUserAge');
      await schemaManager.setVersion('users', 3);
    }

    // Verify migrations
    final version = await schemaManager.getVersion('users');
    print('Current schema version: $version');

    final history = await schemaManager.getMigrationHistory('users');
    print('Migration history:');
    for (final migration in history) {
      print(
          '- ${migration['migrationName']}: ${migration['fromVersion']} -> ${migration['toVersion']}');
    }

    // Example of rollback
    print('\nRolling back to version 2...');
    await schemaManager.rollbackToVersion('users', 2);

    final newVersion = await schemaManager.getVersion('users');
    print('Schema version after rollback: $newVersion');
  } catch (e) {
    print('Error during migration: $e');
  } finally {
    await storage.close();
  }
}
