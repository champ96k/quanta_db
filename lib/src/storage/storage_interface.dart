import 'package:quanta_db/src/common/change_types.dart';

/// Common interface for storage implementations
abstract class StorageInterface {
  /// Initialize the storage
  Future<void> init();

  /// Put a key-value pair into the storage
  Future<void> put<T>(String key, T value);

  /// Put multiple key-value pairs into the storage in a single batch
  Future<void> putAll<T>(Map<String, T> entries);

  /// Get a value by key
  Future<T?> get<T>(String key);

  /// Delete a key
  Future<void> delete(String key);

  /// Get all items of a specific type
  Future<List<T>> getAll<T>();

  /// Close the storage
  Future<void> close();

  /// Stream of change events
  Stream<ChangeEvent> get onChange;
}
