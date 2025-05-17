import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A three-layer Bloom Filter implementation for fast key existence checks
class BloomFilter {
  final List<Uint8List> _layers;
  final List<int> _layerSizes;
  final List<int> _hashCounts;
  static const int _numLayers = 3;

  BloomFilter({
    int bits8 = 1024, // 128 bytes
    int bits16 = 2048, // 256 bytes
    int bits32 = 4096, // 512 bytes
  })  : _layers = List.generate(_numLayers, (_) => Uint8List(0)),
        _layerSizes = [bits8, bits16, bits32],
        _hashCounts = [4, 6, 8] {
    _initializeLayers();
  }

  void _initializeLayers() {
    for (int i = 0; i < _numLayers; i++) {
      final sizeInBytes = (_layerSizes[i] / 8).ceil();
      _layers[i] = Uint8List(sizeInBytes);
    }
  }

  /// Add a key to the bloom filter
  void add(Uint8List key) {
    for (int layer = 0; layer < _numLayers; layer++) {
      final hashes = _generateHashes(key, _hashCounts[layer]);
      for (final hash in hashes) {
        final index = hash % _layerSizes[layer];
        final byteIndex = index ~/ 8;
        final bitIndex = index % 8;
        _layers[layer][byteIndex] |= (1 << bitIndex);
      }
    }
  }

  /// Check if a key might exist in the filter
  bool mightContain(Uint8List key) {
    for (int layer = 0; layer < _numLayers; layer++) {
      final hashes = _generateHashes(key, _hashCounts[layer]);
      for (final hash in hashes) {
        final index = hash % _layerSizes[layer];
        final byteIndex = index ~/ 8;
        final bitIndex = index % 8;
        if ((_layers[layer][byteIndex] & (1 << bitIndex)) == 0) {
          return false;
        }
      }
    }
    return true;
  }

  /// Clear all layers of the bloom filter
  void clear() {
    for (final layer in _layers) {
      layer.fillRange(0, layer.length, 0);
    }
  }

  /// Get the current size of the bloom filter in bytes
  int get size {
    return _layers.fold(0, (sum, layer) => sum + layer.length);
  }

  /// Get all layers of the bloom filter
  List<Uint8List> get layers => _layers;

  /// Generate multiple hash values for a key
  List<int> _generateHashes(Uint8List key, int count) {
    final hashes = <int>[];
    final hash = sha256.convert(key).bytes;

    for (int i = 0; i < count; i++) {
      int value = 0;
      for (int j = 0; j < 4; j++) {
        value = (value << 8) | hash[(i * 4 + j) % hash.length];
      }
      hashes.add(value.abs());
    }

    return hashes;
  }

  /// Merge another bloom filter into this one
  void merge(BloomFilter other) {
    for (int i = 0; i < _numLayers; i++) {
      for (int j = 0; j < _layers[i].length; j++) {
        _layers[i][j] |= other._layers[i][j];
      }
    }
  }
}
