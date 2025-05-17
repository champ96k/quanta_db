import 'dart:convert';
import 'dart:typed_data';

/// Binary format types
enum BsonType {
  null_(0x00),
  int32(0x01),
  int64(0x02),
  double_(0x03),
  string(0x04),
  boolean(0x05),
  dateTime(0x06),
  map(0x07),
  list(0x08),
  binary(0x09);

  const BsonType(this.value);
  final int value;
}

/// DartBson - A binary serialization format optimized for Dart
class DartBson {
  DartBson();
  static const int typeNull = 0x00;
  static const int typeBool = 0x01;
  static const int typeInt = 0x02;
  static const int typeDouble = 0x03;
  static const int typeString = 0x04;
  static const int typeList = 0x05;
  static const int typeMap = 0x06;
  static const int typeDateTime = 0x07;

  /// Encode a value to DartBson format
  static Uint8List encode(dynamic value) {
    final writer = _BsonWriter();
    writer.writeValue(value);
    return writer.takeBytes();
  }

  /// Decode a value from DartBson format
  static dynamic decode(Uint8List bytes) {
    final reader = _BsonReader(bytes);
    return reader.readValue();
  }
}

class _BsonWriter {
  final _buffer = <int>[];

  void writeValue(dynamic value) {
    if (value == null) {
      _writeByte(DartBson.typeNull);
      return;
    }

    if (value is bool) {
      _writeByte(DartBson.typeBool);
      _writeByte(value ? 1 : 0);
      return;
    }

    if (value is int) {
      _writeByte(DartBson.typeInt);
      _writeInt64(value);
      return;
    }

    if (value is double) {
      _writeByte(DartBson.typeDouble);
      _writeDouble(value);
      return;
    }

    if (value is String) {
      _writeByte(DartBson.typeString);
      _writeString(value);
      return;
    }

    if (value is List) {
      _writeByte(DartBson.typeList);
      _writeInt32(value.length);
      for (final item in value) {
        writeValue(item);
      }
      return;
    }

    if (value is Map) {
      _writeByte(DartBson.typeMap);
      _writeInt32(value.length);
      value.forEach((key, val) {
        _writeString(key.toString());
        writeValue(val);
      });
      return;
    }

    if (value is DateTime) {
      _writeByte(DartBson.typeDateTime);
      _writeInt64(value.millisecondsSinceEpoch);
      return;
    }

    // For objects without toJson, use toString
    _writeByte(DartBson.typeString);
    _writeString(value.toString());
  }

  void _writeByte(int byte) {
    _buffer.add(byte);
  }

  void _writeInt32(int value) {
    _buffer.addAll([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }

  void _writeInt64(int value) {
    _buffer.addAll([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
      (value >> 32) & 0xFF,
      (value >> 40) & 0xFF,
      (value >> 48) & 0xFF,
      (value >> 56) & 0xFF,
    ]);
  }

  void _writeDouble(double value) {
    final bytes = ByteData(8);
    bytes.setFloat64(0, value, Endian.little);
    _buffer.addAll(bytes.buffer.asUint8List());
  }

  void _writeString(String value) {
    final bytes = utf8.encode(value);
    _writeInt32(bytes.length);
    _buffer.addAll(bytes);
  }

  Uint8List takeBytes() {
    return Uint8List.fromList(_buffer);
  }
}

class _BsonReader {
  _BsonReader(this._bytes);
  final Uint8List _bytes;
  int _offset = 0;

  dynamic readValue() {
    final type = _readByte();
    switch (type) {
      case DartBson.typeNull:
        return null;
      case DartBson.typeBool:
        return _readByte() == 1;
      case DartBson.typeInt:
        return _readInt64();
      case DartBson.typeDouble:
        return _readDouble();
      case DartBson.typeString:
        return _readString();
      case DartBson.typeList:
        final length = _readInt32();
        return List.generate(length, (_) => readValue());
      case DartBson.typeMap:
        final length = _readInt32();
        final map = <String, dynamic>{};
        for (var i = 0; i < length; i++) {
          final key = _readString();
          map[key] = readValue();
        }
        return map;
      case DartBson.typeDateTime:
        return DateTime.fromMillisecondsSinceEpoch(_readInt64());
      default:
        throw FormatException('Unknown type: $type');
    }
  }

  int _readByte() {
    return _bytes[_offset++];
  }

  int _readInt32() {
    final value = _bytes[_offset] |
        (_bytes[_offset + 1] << 8) |
        (_bytes[_offset + 2] << 16) |
        (_bytes[_offset + 3] << 24);
    _offset += 4;
    return value;
  }

  int _readInt64() {
    final value = _bytes[_offset] |
        (_bytes[_offset + 1] << 8) |
        (_bytes[_offset + 2] << 16) |
        (_bytes[_offset + 3] << 24) |
        (_bytes[_offset + 4] << 32) |
        (_bytes[_offset + 5] << 40) |
        (_bytes[_offset + 6] << 48) |
        (_bytes[_offset + 7] << 56);
    _offset += 8;
    return value;
  }

  double _readDouble() {
    final bytes = ByteData.view(_bytes.buffer, _offset);
    _offset += 8;
    return bytes.getFloat64(0, Endian.little);
  }

  String _readString() {
    final length = _readInt32();
    final value = utf8.decode(_bytes.sublist(_offset, _offset + length));
    _offset += length;
    return value;
  }
}
