// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:quanta_db/src/serialization/dart_bson.dart';
import 'package:quanta_db/src/storage/bloom_filter.dart';
import 'package:quanta_db/src/storage/memtable.dart';

/// A block size of 4KB for efficient I/O operations
const int blockSize = 4096;

/// Represents a Sorted String Table (SSTable) file
class SSTable {
  /// Creates a new SSTable instance
  SSTable(
      this.path, this.bloomFilter, this.index, this.file, this.level, this.id);

  /// The file path of the SSTable
  final String path;

  /// The bloom filter for quick key existence checks
  final BloomFilter bloomFilter;

  /// The index mapping keys to their offsets in the file
  final Map<String, int> index;

  /// The file handle for reading the SSTable
  final RandomAccessFile file;

  /// The level of this SSTable in the LSM tree
  final int level;

  /// The unique identifier of this SSTable
  final int id;

  /// Create a new SSTable from a MemTable
  static Future<SSTable> create(MemTable memTable, int level, int id) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'sstable_${level}_$timestamp.sst';
    final filePath = '${memTable.path}/$fileName';
    final file = await File(filePath).open(mode: FileMode.write);

    // Write header
    await file.writeByte(0x01); // Version
    await file.writeByte(level);
    await _writeInt64(file, id);
    await _writeInt64(file, memTable.entries.length);

    final bloomFilter = BloomFilter(memTable.entries.length);
    final index = <String, int>{};
    var offset = 16; // Skip header (1 + 1 + 8 + 8 bytes)

    // Write entries
    for (final entry in memTable.entries.entries) {
      final key = entry.key;
      final value = entry.value;

      // Write key length and key
      final keyBytes = utf8.encode(key);
      await _writeInt32(file, keyBytes.length);
      await file.writeFrom(keyBytes);

      // Write value length and value
      final valueBytes = DartBson.encode(value);
      await _writeInt32(file, valueBytes.length);
      await file.writeFrom(valueBytes);

      bloomFilter.add(key);
      index[key] = offset;
      offset += 4 + keyBytes.length + 4 + valueBytes.length;
    }

    await file.close();
    return SSTable(filePath, bloomFilter, index,
        await File(filePath).open(mode: FileMode.read), level, id);
  }

  /// Load an existing SSTable from file
  static Future<SSTable> load(String path) async {
    final file = await File(path).open(mode: FileMode.read);

    // Read and validate header
    final version = await file.readByte();
    if (version != 0x01) {
      throw FormatException('Unsupported SSTable version: $version');
    }

    final level = await file.readByte();
    final id = await _readInt64(file);
    final numEntries = await _readInt64(file);

    if (numEntries < 0 || numEntries > 1000000) {
      throw FormatException('Invalid number of entries: $numEntries');
    }

    final bloomFilter = BloomFilter(numEntries);
    final index = <String, int>{};
    var offset = 16; // Skip header (1 + 1 + 8 + 8 bytes)

    // Read entries to build index
    for (var i = 0; i < numEntries; i++) {
      final keyLength = await _readInt32(file);
      final keyBytes = await file.read(keyLength);
      final key = utf8.decode(keyBytes);

      final valueLength = await _readInt32(file);
      await file.read(valueLength); // Skip value

      bloomFilter.add(key);
      index[key] = offset;
      offset += 4 + keyLength + 4 + valueLength;
    }

    return SSTable(path, bloomFilter, index, file, level, id);
  }

  /// Get a value by key
  Future<T?> get<T>(String key) async {
    if (!bloomFilter.mightContain(key)) return null;

    final offset = index[key];
    if (offset == null) return null;

    await file.setPosition(offset);

    // Read key length and key
    final keyLength = await _readInt32(file);
    final storedKey = await file.read(keyLength);
    if (utf8.decode(storedKey) != key) return null;

    // Read value length and value
    final valueLength = await _readInt32(file);
    final valueBytes = await file.read(valueLength);

    return DartBson.decode(valueBytes) as T;
  }

  /// Get all entries from the SSTable
  Future<Map<String, dynamic>> getAll() async {
    final entries = <String, dynamic>{};
    await file.setPosition(0);

    // Skip header
    await file.readByte(); // Version
    await file.readByte(); // Level
    await _readInt64(file); // Table ID
    final numEntries = await _readInt64(file);

    for (var i = 0; i < numEntries; i++) {
      // Read key length and key
      final keyLength = await _readInt32(file);
      final keyBytes = await file.read(keyLength);
      final key = utf8.decode(keyBytes);

      // Read value length and value
      final valueLength = await _readInt32(file);
      final valueBytes = await file.read(valueLength);
      final value = DartBson.decode(valueBytes);

      entries[key] = value;
    }

    return entries;
  }

  /// Close the SSTable file
  Future<void> close() async {
    await file.close();
  }

  /// Delete the SSTable file
  Future<void> delete() async {
    if (await File(path).exists()) {
      await File(path).delete();
    }
  }

  /// Read a 32-bit integer from the file
  static Future<int> _readInt32(RandomAccessFile file) async {
    final bytes = await file.read(4);
    if (bytes.length < 4) {
      throw const FormatException(
          'Unexpected end of file while reading 32-bit integer');
    }
    // Read bytes in little-endian order
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }

  /// Read a 64-bit integer from the file
  static Future<int> _readInt64(RandomAccessFile file) async {
    final bytes = await file.read(8);
    if (bytes.length < 8) {
      throw const FormatException(
          'Unexpected end of file while reading 64-bit integer');
    }
    // Read bytes in little-endian order
    return bytes[0] |
        (bytes[1] << 8) |
        (bytes[2] << 16) |
        (bytes[3] << 24) |
        (bytes[4] << 32) |
        (bytes[5] << 40) |
        (bytes[6] << 48) |
        (bytes[7] << 56);
  }

  /// Write a 32-bit integer to the file
  static Future<void> _writeInt32(RandomAccessFile file, int value) async {
    // Write bytes in little-endian order
    final bytes = [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
    await file.writeFrom(bytes);
  }

  /// Write a 64-bit integer to the file
  static Future<void> _writeInt64(RandomAccessFile file, int value) async {
    // Write bytes in little-endian order
    final bytes = [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
      (value >> 32) & 0xFF,
      (value >> 40) & 0xFF,
      (value >> 48) & 0xFF,
      (value >> 56) & 0xFF,
    ];
    await file.writeFrom(bytes);
  }
}
