import 'dart:convert';
import 'dart:typed_data';
import 'serializer.dart';

/// Mixin for model classes that can be serialized
mixin Serializable {
  Map<String, dynamic> toJson();
}

/// Serializer for model classes
class ModelSerializer<T extends Serializable> implements Serializer<T> {
  ModelSerializer(this.fromJson);
  final T Function(Map<String, dynamic> json) fromJson;

  @override
  Uint8List serialize(T value) {
    final json = value.toJson();
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  @override
  T deserialize(Uint8List bytes) {
    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return fromJson(json);
  }
}
