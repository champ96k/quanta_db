import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Manages encryption keys securely
class KeyManager {
  /// Private constructor to prevent instantiation
  const KeyManager._();

  static const _keyDir = 'keys';
  static const _masterKeyFile = 'master.key';
  static const _keyFile = 'encryption.key';

  /// Initializes the key management system
  static Future<void> initialize(String dbDir) async {
    final keyDir = Directory(path.join(dbDir, _keyDir));
    if (!await keyDir.exists()) {
      await keyDir.create(recursive: true);
      await _generateMasterKey(keyDir.path);
    }
  }

  /// Gets the encryption key, generating it if it doesn't exist
  static Future<String> getEncryptionKey(String dbDir) async {
    final keyFile = File(path.join(dbDir, _keyDir, _keyFile));
    if (!await keyFile.exists()) {
      await _generateEncryptionKey(dbDir);
    }
    return await keyFile.readAsString();
  }

  /// Rotates the encryption key
  static Future<void> rotateKey(String dbDir) async {
    await _generateEncryptionKey(dbDir);
  }

  /// Generates a new master key
  static Future<void> _generateMasterKey(String dbDir) async {
    final masterKey = _generateSecureRandom(32);
    final masterKeyFile = File(path.join(dbDir, _keyDir, _masterKeyFile));
    await masterKeyFile.writeAsBytes(masterKey);
  }

  /// Generates a new encryption key
  static Future<void> _generateEncryptionKey(String dbDir) async {
    final masterKeyFile = File(path.join(dbDir, _keyDir, _masterKeyFile));
    final masterKey = await masterKeyFile.readAsBytes();

    final random = _generateSecureRandom(32);
    final key = _deriveKey(random, masterKey);

    final keyFile = File(path.join(dbDir, _keyDir, _keyFile));
    await keyFile.writeAsBytes(key);
  }

  /// Derives a key using HKDF
  static Uint8List _deriveKey(Uint8List input, Uint8List salt) {
    final hmac = Hmac(sha256, salt);
    final prk = hmac.convert(input).bytes;
    final info = utf8.encode('QUANTA_DB_KEY');
    return Uint8List.fromList(hmac.convert([...prk, ...info]).bytes);
  }

  /// Generates secure random bytes
  static Uint8List _generateSecureRandom(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (i) => random.nextInt(256)),
    );
  }
}
