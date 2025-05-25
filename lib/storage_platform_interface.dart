import 'package:flutter/foundation.dart' show kIsWeb;
import 'storage_web.dart';
import 'storage_io.dart';

/// Platform interface for storage operations
abstract class StoragePlatform {
  /// Factory constructor to create the appropriate storage implementation
  factory StoragePlatform() {
    if (kIsWeb) {
      return StorageWeb();
    }
    return StorageIO();
  }

  /// Get the storage path for the given database name
  Future<String> getStoragePath(String dbName);

  /// Create a directory at the given path
  Future<void> createDirectory(String path);
}
