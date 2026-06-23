import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/screens/home_screen.dart';

void main() {
  test('salary entry pages keep state across sync data refreshes', () {
    expect(homePageStateKey(2, 1), homePageStateKey(2, 2));
    expect(homePageStateKey(7, 1), homePageStateKey(7, 2));
  });

  test('non-editing pages still refresh when synced data changes', () {
    expect(homePageStateKey(0, 1), isNot(homePageStateKey(0, 2)));
    expect(homePageStateKey(3, 1), isNot(homePageStateKey(3, 2)));
  });
}
