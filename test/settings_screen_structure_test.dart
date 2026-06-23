import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings screen shows the accessibility section only once', () {
    final source = File(
      'lib/screens/settings/settings_screen.dart',
    ).readAsStringSync();

    expect(
      RegExp(r'child:\s*const _AccessibilitySection\(\)').allMatches(source),
      hasLength(1),
    );
  });
}
