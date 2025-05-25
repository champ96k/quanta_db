import 'package:quanta_db/src/storage/storage_interface.dart';
import 'package:quanta_db/src/common/change_types.dart';

class WebStorage implements StorageInterface {
  WebStorage(String name) {
    throw UnsupportedError('Web storage is not supported in this environment');
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<T?> get<T>(String key) async => null;

  @override
  Future<List<T>> getAll<T>() async => [];

  @override
  Future<void> init() async {}

  @override
  Stream<ChangeEvent> get onChange => const Stream.empty();

  @override
  Future<void> put<T>(String key, T value) async {}

  @override
  Future<void> putAll<T>(Map<String, T> entries) async {}
}
