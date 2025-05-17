import 'dart:convert';
import 'dart:typed_data';

/// Interface for serializing and deserializing data
abstract class Serializer<T> {
  Uint8List serialize(T value);
  T deserialize(Uint8List bytes);
}

/// Serializer for String values
class StringSerializer implements Serializer<String> {
  @override
  Uint8List serialize(String value) {
    return Uint8List.fromList(utf8.encode(value));
  }

  @override
  String deserialize(Uint8List bytes) {
    return utf8.decode(bytes);
  }
}

/// Serializer for int values
class IntSerializer implements Serializer<int> {
  @override
  Uint8List serialize(int value) {
    final buffer = ByteData(8);
    buffer.setInt64(0, value, Endian.little);
    return buffer.buffer.asUint8List();
  }

  @override
  int deserialize(Uint8List bytes) {
    return ByteData.view(bytes.buffer).getInt64(0, Endian.little);
  }
}

/// Serializer for double values
class DoubleSerializer implements Serializer<double> {
  @override
  Uint8List serialize(double value) {
    final buffer = ByteData(8);
    buffer.setFloat64(0, value, Endian.little);
    return buffer.buffer.asUint8List();
  }

  @override
  double deserialize(Uint8List bytes) {
    return ByteData.view(bytes.buffer).getFloat64(0, Endian.little);
  }
}

/// Serializer for bool values
class BoolSerializer implements Serializer<bool> {
  @override
  Uint8List serialize(bool value) {
    return Uint8List.fromList([value ? 1 : 0]);
  }

  @override
  bool deserialize(Uint8List bytes) {
    return bytes[0] == 1;
  }
}

/// Serializer for Map values
class MapSerializer<K, V> implements Serializer<Map<K, V>> {
  MapSerializer(this.keySerializer, this.valueSerializer);
  final Serializer<K> keySerializer;
  final Serializer<V> valueSerializer;

  @override
  Uint8List serialize(Map<K, V> value) {
    final map = value.map((key, val) => MapEntry(
          keySerializer.serialize(key),
          valueSerializer.serialize(val),
        ));
    return Uint8List.fromList(json.encode(map).codeUnits);
  }

  @override
  Map<K, V> deserialize(Uint8List bytes) {
    final jsonStr = String.fromCharCodes(bytes);
    final map = json.decode(jsonStr) as Map;
    return map.map((key, value) => MapEntry(
          keySerializer.deserialize(Uint8List.fromList(key.codeUnits)),
          valueSerializer.deserialize(Uint8List.fromList(value.codeUnits)),
        ));
  }
}
