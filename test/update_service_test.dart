import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/services/update_service.dart';

void main() {
  test('version parser compares stable versions above alpha releases', () {
    final alpha = AppVersion.parse('v0.9.1-alpha+25');
    final stable = AppVersion.parse('0.9.1+26');

    expect(stable.compareTo(alpha), greaterThan(0));
  });

  test('version parser orders newer alpha releases correctly', () {
    final current = AppVersion.parse('v0.9.10-alpha');
    final next = AppVersion.parse('v0.9.11-alpha');

    expect(next.compareTo(current), greaterThan(0));
  });
}
