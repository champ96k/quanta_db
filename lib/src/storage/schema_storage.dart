import 'dart:convert';
import 'package:quanta_db/src/storage/lsm_storage.dart';

class SchemaStorage {
  SchemaStorage(this._storage);
  final LSMStorage _storage;
  static const _schemaPrefix = 'schema:';
  static const _versionPrefix = 'version:';

  Future<int> getVersion(String modelName) async {
    final versionKey = '$_versionPrefix$modelName';
    final versionStr = await _storage.get(versionKey);
    return versionStr != null ? int.parse(versionStr) : 1;
  }

  Future<void> setVersion(String modelName, int version) async {
    final versionKey = '$_versionPrefix$modelName';
    await _storage.put(versionKey, version.toString());
  }

  Future<Map<String, dynamic>> getSchema(String modelName) async {
    final schemaKey = '$_schemaPrefix$modelName';
    final schemaStr = await _storage.get(schemaKey);
    return schemaStr != null ? json.decode(schemaStr) : {};
  }

  Future<void> setSchema(String modelName, Map<String, dynamic> schema) async {
    final schemaKey = '$_schemaPrefix$modelName';
    await _storage.put(schemaKey, json.encode(schema));
  }
}
