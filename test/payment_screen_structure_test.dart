import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected payment cards have a visible highlight', () {
    final source = File(
      'lib/screens/payments/payment_screen.dart',
    ).readAsStringSync();

    expect(source, contains('final selectedBorderColor = selected'));
    expect(source, contains('final selectedBackground = selected'));
    expect(source, contains('if (selected)'));
    expect(source, contains('width: selected ? 1.8 : 1'));
  });
}
