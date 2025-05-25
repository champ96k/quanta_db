import 'storage_platform_interface.dart';

class StorageWeb implements StoragePlatform {
  @override
  Future<String> getStoragePath(String dbName) async {
    // For web, we'll use IndexedDB with a prefixed database name
    return 'quanta_db_$dbName';
  }

  @override
  Future<void> createDirectory(String path) async {
    // No-op for web as we use IndexedDB
  }
}
