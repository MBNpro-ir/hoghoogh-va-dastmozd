import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/utils/persian_date_helper.dart';

void main() {
  test('current payroll period is derived from the Jalali calendar', () {
    final date = PersianDateHelper.today(DateTime(2026, 6, 23));

    expect(date.year, 1405);
    expect(date.month, 4);
    expect(date.day, 2);
    expect(PersianDateHelper.todayText(DateTime(2026, 6, 23)), '1405/04/02');
  });

  test('nearby year options retain an older selected year', () {
    final options = PersianDateHelper.nearbyYearOptions(selectedYear: 1399);

    expect(options, contains(PersianDateHelper.currentYear));
    expect(options, contains(1399));
    expect(options, orderedEquals([...options]..sort()));
  });
}
