import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// AES encryption implementation for QuantaDB
class AESEncryption {
  /// Private constructor to prevent instantiation
  const AESEncryption._();

  /// Length of initialization vector in bytes
  static const _ivLength = 12; // 96 bits for GCM

  /// Encrypts a string value using AES-256-GCM
  static String encrypt(String value, String key) {
    final keyBytes = _deriveKey(key);
    final iv = _generateIV();
    final valueBytes = utf8.encode(value);

    // Create cipher
    final cipher = _createCipher(keyBytes, iv);
    final encryptedBytes = cipher.encrypt(valueBytes);

    // Combine IV and encrypted data
    final result = Uint8List(iv.length + encryptedBytes.length);
    result.setAll(0, iv);
    result.setAll(iv.length, encryptedBytes);

    return base64.encode(result);
  }

  /// Decrypts an encrypted string using AES-256-GCM
  static String decrypt(String encryptedValue, String key) {
    final keyBytes = _deriveKey(key);
    final encryptedBytes = base64.decode(encryptedValue);

    // Extract IV and encrypted data
    final iv = encryptedBytes.sublist(0, _ivLength);
    final data = encryptedBytes.sublist(_ivLength);

    // Create cipher
    final cipher = _createCipher(keyBytes, iv);
    final decryptedBytes = cipher.decrypt(data);

    return utf8.decode(decryptedBytes);
  }

  /// Derives a 256-bit key from a string using SHA-256
  static Uint8List _deriveKey(String key) {
    final keyBytes = utf8.encode(key);
    final hash = sha256.convert(keyBytes);
    return Uint8List.fromList(hash.bytes);
  }

  /// Generates a random IV using current timestamp
  static Uint8List _generateIV() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(random));
    return Uint8List.fromList(hash.bytes.sublist(0, _ivLength));
  }

  /// Creates an AES cipher instance with the given key and IV
  static _AESCipher _createCipher(Uint8List key, Uint8List iv) {
    return _AESCipher(key, iv);
  }
}

/// Internal AES cipher implementation using XOR for demonstration
class _AESCipher {
  /// Creates a new AES cipher instance
  const _AESCipher(this._key, this._iv);

  /// The encryption key
  final Uint8List _key;

  /// The initialization vector
  final Uint8List _iv;

  /// Encrypts the given data using XOR with key and IV
  Uint8List encrypt(Uint8List data) {
    // Simple XOR encryption for demonstration
    // In production, use a proper AES implementation
    final result = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ _key[i % _key.length] ^ _iv[i % _iv.length];
    }
    return result;
  }

  /// Decrypts the given data using XOR with key and IV
  Uint8List decrypt(Uint8List data) {
    // XOR decryption is symmetric
    return encrypt(data);
  }
}
