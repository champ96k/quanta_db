import 'package:flutter_test/flutter_test.dart';
import 'web_test_config.dart';
import 'storage/storage_manager_web_test.dart' as storage_tests;

void main() {
  configureWebTests();

  // Run all web-specific tests
  group('Web Tests', () {
    storage_tests.main();
  });
}
