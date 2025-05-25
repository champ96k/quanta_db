import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void configureWebTests() {
  setUpAll(() {
    if (!kIsWeb) {
      fail('These tests should only run on web platform');
    }
  });
}
