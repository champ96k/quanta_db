import 'package:quanta_db/src/storage/lsm_storage.dart';

/// Interface for schema migrations
abstract class SchemaMigration {
  /// Apply the migration
  Future<void> up(LSMStorage storage);

  /// Rollback the migration
  Future<void> down(LSMStorage storage);
}
