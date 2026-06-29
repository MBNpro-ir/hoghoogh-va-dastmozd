import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/screens/home_screen.dart';
import 'dart:io';

void main() {
  test('salary entry pages keep state across sync data refreshes', () {
    expect(homePageStateKey(2, 1), homePageStateKey(2, 2));
    expect(homePageStateKey(7, 1), homePageStateKey(7, 2));
  });

  test('non-editing pages still refresh when synced data changes', () {
    expect(homePageStateKey(0, 1), isNot(homePageStateKey(0, 2)));
    expect(homePageStateKey(3, 1), isNot(homePageStateKey(3, 2)));
  });

  test('android home shell overlays the floating nav on top of body', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(source, contains('extendBody: Platform.isAndroid'));
    expect(source, contains('Widget _buildAndroidMobileBody()'));
    expect(source, contains('return Stack('));
    expect(source, contains('bottomNavigationBar: Platform.isAndroid'));
    expect(source, contains('? null'));
  });
}
