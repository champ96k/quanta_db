// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'dart:typed_data';
import 'bloom_filter.dart';

/// A block size of 4KB for efficient I/O operations
const int BLOCK_SIZE = 4096;

/// Represents a Sorted String Table (SSTable) file
class SSTable {
  final String filePath;
  final File file;
  final int level;
  final int id;
  final BloomFilter _bloomFilter;

  SSTable({
    required this.filePath,
    required this.level,
    required this.id,
  })  : file = File(filePath),
        _bloomFilter = BloomFilter();

  /// Write a sorted map of key-value pairs to the SSTable file
  Future<void> write(Map<Uint8List, Uint8List> entries) async {
    final raf = await file.open(mode: FileMode.write);
    try {
      // Write header
      await raf.writeByte(0x01); // Version
      await raf.writeByte(level); // Level
      await _writeInt64(raf, id); // Table ID
      await _writeInt64(raf, entries.length); // Number of entries

      // Write entries and build bloom filter
      for (final entry in entries.entries) {
        // Add key to bloom filter
        _bloomFilter.add(entry.key);

        // Write key length and key
        await _writeInt32(raf, entry.key.length);
        await raf.writeFrom(entry.key);

        // Write value length and value
        await _writeInt32(raf, entry.value.length);
        await raf.writeFrom(entry.value);
      }

      // Write bloom filter
      final bloomFilterBytes = _serializeBloomFilter();
      await _writeInt32(raf, bloomFilterBytes.length);
      await raf.writeFrom(bloomFilterBytes);

      // Pad to block size
      final currentPos = await raf.position();
      final padding = BLOCK_SIZE - (currentPos % BLOCK_SIZE);
      if (padding < BLOCK_SIZE) {
        await raf.writeFrom(List<int>.filled(padding, 0));
      }
    } finally {
      await raf.close();
    }
  }

  /// Read a value by key from the SSTable
  Future<Uint8List?> get(Uint8List key) async {
    // Quick check using bloom filter
    if (!_bloomFilter.mightContain(key)) {
      return null;
    }

    final raf = await file.open(mode: FileMode.read);
    try {
      // Skip header
      await raf.setPosition(10); // 1 + 1 + 8 bytes for version, level, and id
      final numEntries = await _readInt64(raf);

      // Binary search through entries
      int left = 0;
      int right = numEntries - 1;

      while (left <= right) {
        final mid = (left + right) ~/ 2;
        final position = await _getEntryPosition(mid);
        await raf.setPosition(position);

        final keyLength = await _readInt32(raf);
        final currentKey = await raf.read(keyLength);

        final comparison = _compareBytes(key, currentKey);
        if (comparison == 0) {
          final valueLength = await _readInt32(raf);
          return await raf.read(valueLength);
        } else if (comparison < 0) {
          right = mid - 1;
        } else {
          left = mid + 1;
        }
      }
      return null;
    } finally {
      await raf.close();
    }
  }

  /// Get the position of an entry in the file
  Future<int> _getEntryPosition(int index) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      await raf.setPosition(10); // Skip header
      int position = 10;

      for (int i = 0; i < index; i++) {
        final keyLength = await _readInt32(raf);
        position += 4 + keyLength;

        final valueLength = await _readInt32(raf);
        position += 4 + valueLength;

        await raf.setPosition(position);
      }
      return position;
    } finally {
      await raf.close();
    }
  }

  /// Write a 32-bit integer to the file
  Future<void> _writeInt32(RandomAccessFile file, int value) async {
    final buffer = ByteData(4);
    buffer.setInt32(0, value, Endian.little);
    await file.writeFrom(buffer.buffer.asUint8List());
  }

  /// Write a 64-bit integer to the file
  Future<void> _writeInt64(RandomAccessFile file, int value) async {
    final buffer = ByteData(8);
    buffer.setInt64(0, value, Endian.little);
    await file.writeFrom(buffer.buffer.asUint8List());
  }

  /// Read a 32-bit integer from the file
  Future<int> _readInt32(RandomAccessFile file) async {
    final buffer = await file.read(4);
    return ByteData.view(buffer.buffer).getInt32(0, Endian.little);
  }

  /// Read a 64-bit integer from the file
  Future<int> _readInt64(RandomAccessFile file) async {
    final buffer = await file.read(8);
    return ByteData.view(buffer.buffer).getInt64(0, Endian.little);
  }

  /// Compare two byte arrays
  static int _compareBytes(Uint8List a, Uint8List b) {
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) {
        return a[i].compareTo(b[i]);
      }
    }
    return a.length.compareTo(b.length);
  }

  /// Serialize the bloom filter to bytes
  Uint8List _serializeBloomFilter() {
    final totalSize = _bloomFilter.size;
    final buffer = ByteData(totalSize);
    var offset = 0;

    for (final layer in _bloomFilter.layers) {
      for (final byte in layer) {
        buffer.setUint8(offset++, byte);
      }
    }

    return buffer.buffer.asUint8List();
  }

  /// Delete the SSTable file
  Future<void> delete() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
