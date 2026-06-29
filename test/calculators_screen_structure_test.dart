import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculators screen has no inner app bar header', () {
    final source = File(
      'lib/screens/calculators/calculators_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("AppBar(title: const Text('محاسبه‌گرها'))")));
    expect(source, isNot(contains("appBar: AppBar(title:")));
  });
}
