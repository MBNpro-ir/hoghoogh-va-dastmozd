import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings screen keeps application settings grouped once', () {
    final source = File(
      'lib/screens/settings/settings_screen.dart',
    ).readAsStringSync();

    expect(
      RegExp(r'const _AccessibilitySection\(\),').allMatches(source),
      hasLength(1),
    );
    expect(source, contains("title: 'تنظیمات حقوق و دستمزد'"));
    expect(source, contains("title: 'تنظیمات برنامه'"));
    expect(source, contains('if (width >= 1120) return 3;'));
  });
}
