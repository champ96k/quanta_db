import 'dart:io';
import 'package:path/path.dart' as path;
import 'storage_platform_interface.dart';

class StorageIO implements StoragePlatform {
  @override
  Future<String> getStoragePath(String dbName) async {
    if (Platform.isIOS || Platform.isAndroid) {
      // For mobile platforms, use app's documents directory
      final appDir = await _getAppDirectory();
      return path.join(appDir.path, 'databases', dbName);
    } else if (Platform.isMacOS) {
      // For macOS, use Application Support
      final homeDir = Platform.environment['HOME'];
      return path.join(
          homeDir!, 'Library', 'Application Support', 'quanta_db', dbName);
    } else if (Platform.isWindows) {
      // For Windows, use AppData
      final appData = Platform.environment['APPDATA'];
      return path.join(appData!, 'quanta_db', dbName);
    } else if (Platform.isLinux) {
      // For Linux, use XDG data home
      final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
      return path.join(
          xdgDataHome ?? '${Platform.environment['HOME']}/.local/share',
          'quanta_db',
          dbName);
    } else {
      // For pure Dart, use a secure directory in the user's home
      final homeDir =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (homeDir != null) {
        // Create a hidden directory in the user's home
        return path.join(homeDir, '.quanta_db', dbName);
      }
      // Last resort: use current directory
      return path.join(Directory.current.path, dbName);
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  Future<Directory> _getAppDirectory() async {
    // For pure Dart, use a secure directory in the user's home
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir != null) {
      return Directory(path.join(homeDir, '.quanta_db'));
    }
    // Last resort: use current directory
    return Directory.current;
  }
}
