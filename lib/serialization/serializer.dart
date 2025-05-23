import 'dart:typed_data';
import 'dart:convert';

/// Handles serialization and deserialization of data
class Serializer {
  /// Serialize a value to bytes
  Uint8List serialize(dynamic value) {
    if (value is List) {
      return _serializeList(value);
    } else if (value is Map) {
      return _serializeMap(value);
    } else if (value is String) {
      return _serializeString(value);
    } else if (value is num) {
      return _serializeNumber(value);
    } else if (value is bool) {
      return _serializeBoolean(value);
    } else if (value == null) {
      return _serializeNull();
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  /// Deserialize bytes to a value
  dynamic deserialize(Uint8List bytes) {
    final type = bytes[0];
    final data = bytes.sublist(1);

    switch (type) {
      case 0: // List
        return _deserializeList(data);
      case 1: // Map
        return _deserializeMap(data);
      case 2: // String
        return _deserializeString(data);
      case 3: // Number
        return _deserializeNumber(data);
      case 4: // Boolean
        return _deserializeBoolean(data);
      case 5: // Null
        return null;
      default:
        throw ArgumentError('Unknown type: $type');
    }
  }

  Uint8List _serializeList(List value) {
    final items = value.map(serialize).toList();
    final totalLength = items.fold<int>(0, (sum, item) => sum + item.length);
    final result = Uint8List(totalLength + 1);
    result[0] = 0; // List type
    var offset = 1;
    for (final item in items) {
      result.setAll(offset, item);
      offset += item.length;
    }
    return result;
  }

  Uint8List _serializeMap(Map value) {
    final entries = value.entries.map((e) {
      final keyBytes = serialize(e.key);
      final valueBytes = serialize(e.value);
      final entryBytes = Uint8List(keyBytes.length + valueBytes.length);
      entryBytes.setAll(0, keyBytes);
      entryBytes.setAll(keyBytes.length, valueBytes);
      return entryBytes;
    }).toList();
    final totalLength =
        entries.fold<int>(0, (sum, entry) => sum + entry.length);
    final result = Uint8List(totalLength + 1);
    result[0] = 1; // Map type
    var offset = 1;
    for (final entry in entries) {
      result.setAll(offset, entry);
      offset += entry.length;
    }
    return result;
  }

  Uint8List _serializeString(String value) {
    final bytes = utf8.encode(value);
    final result = Uint8List(bytes.length + 1);
    result[0] = 2; // String type
    result.setAll(1, bytes);
    return result;
  }

  Uint8List _serializeNumber(num value) {
    final bytes = Float64List.fromList([value.toDouble()]).buffer.asUint8List();
    final result = Uint8List(bytes.length + 1);
    result[0] = 3; // Number type
    result.setAll(1, bytes);
    return result;
  }

  Uint8List _serializeBoolean(bool value) {
    final result = Uint8List(2);
    result[0] = 4; // Boolean type
    result[1] = value ? 1 : 0;
    return result;
  }

  Uint8List _serializeNull() {
    return Uint8List.fromList([5]); // Null type
  }

  List _deserializeList(Uint8List data) {
    final result = <dynamic>[];
    var offset = 0;
    while (offset < data.length) {
      final item = deserialize(data.sublist(offset));
      result.add(item);
      offset += (item as Uint8List).length + 1;
    }
    return result;
  }

  Map _deserializeMap(Uint8List data) {
    final result = <dynamic, dynamic>{};
    var offset = 0;
    while (offset < data.length) {
      final key = deserialize(data.sublist(offset));
      offset += (key as Uint8List).length + 1;
      final value = deserialize(data.sublist(offset));
      offset += (value as Uint8List).length + 1;
      result[key] = value;
    }
    return result;
  }

  String _deserializeString(Uint8List data) {
    return utf8.decode(data);
  }

  num _deserializeNumber(Uint8List data) {
    return Float64List.fromList([data.buffer.asFloat64List()[0]])[0];
  }

  bool _deserializeBoolean(Uint8List data) {
    return data[0] == 1;
  }
}
