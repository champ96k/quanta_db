import 'dart:typed_data';
import 'package:quanta_db/src/utils/xxhash.dart';

/// A 3-layer Bloom Filter implementation with different bit sizes
/// for optimized memory usage and false positive rates
class BloomFilter {
  BloomFilter(this.expectedElements) {
    _initializeLayers();
  }

  BloomFilter.fromBytes(Uint8List bytes, this.expectedElements) {
    _initializeLayers();
    var offset = 0;

    for (var i = 0; i < _layers.length; i++) {
      final layerSize = _layers[i].length;
      _layers[i].setAll(0, bytes.sublist(offset, offset + layerSize));
      offset += layerSize;
    }
  }

  final int expectedElements;
  late final List<Uint8List> _layers;
  static const _bitsPerByte = 8;

  void _initializeLayers() {
    // Layer 1: 8-bit (1 byte) - Fastest, highest false positive rate
    final layer1Size = (expectedElements * 8) ~/ _bitsPerByte;
    // Layer 2: 16-bit (2 bytes) - Medium speed, medium false positive rate
    final layer2Size = (expectedElements * 16) ~/ _bitsPerByte;
    // Layer 3: 32-bit (4 bytes) - Slowest, lowest false positive rate
    final layer3Size = (expectedElements * 32) ~/ _bitsPerByte;

    _layers = [
      Uint8List(layer1Size),
      Uint8List(layer2Size),
      Uint8List(layer3Size),
    ];
  }

  void add(String key) {
    final hash = XXHash.hash64(key.codeUnits);
    _setBit(_layers[0], hash, 8); // 8-bit layer
    _setBit(_layers[1], hash, 16); // 16-bit layer
    _setBit(_layers[2], hash, 32); // 32-bit layer
  }

  bool mightContain(String key) {
    final hash = XXHash.hash64(key.codeUnits);
    return _checkBit(_layers[0], hash, 8) && // Check 8-bit layer
        _checkBit(_layers[1], hash, 16) && // Check 16-bit layer
        _checkBit(_layers[2], hash, 32); // Check 32-bit layer
  }

  void _setBit(Uint8List layer, int hash, int bits) {
    final index = (hash % (layer.length * _bitsPerByte)) ~/ _bitsPerByte;
    final bitOffset = hash % _bitsPerByte;
    layer[index] |= (1 << bitOffset);
  }

  bool _checkBit(Uint8List layer, int hash, int bits) {
    final index = (hash % (layer.length * _bitsPerByte)) ~/ _bitsPerByte;
    final bitOffset = hash % _bitsPerByte;
    return (layer[index] & (1 << bitOffset)) != 0;
  }

  /// Serialize the Bloom Filter to bytes
  Uint8List toBytes() {
    final totalSize = _layers.fold<int>(0, (sum, layer) => sum + layer.length);
    final result = Uint8List(totalSize);
    var offset = 0;

    for (final layer in _layers) {
      result.setAll(offset, layer);
      offset += layer.length;
    }

    return result;
  }
}
