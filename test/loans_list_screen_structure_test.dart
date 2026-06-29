import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loan table actions use compact buttons that fit the actions column',
    () {
      final source = File(
        'lib/screens/loans/loans_list_screen.dart',
      ).readAsStringSync();

      expect(source, contains('Widget _compactActionButton'));
      expect(
        source,
        contains('BoxConstraints.tightFor(width: 30, height: 40)'),
      );
    },
  );
}
