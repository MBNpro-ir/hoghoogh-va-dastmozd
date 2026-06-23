import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/utils/period_filter_helper.dart';

void main() {
  test('period helper parses Persian dates and sorts periods descending', () {
    final periods = PeriodFilterHelper.periodsFromDates([
      '۱۴۰۵/۰۴/۰۱',
      '1405/02/15',
      '1404/12/29',
      'invalid',
    ]);

    expect(periods, [(1405, 4), (1405, 2), (1404, 12)]);
    expect(PeriodFilterHelper.dateIsInPeriod('۱۴۰۵/۰۴/۰۳', (1405, 4)), true);
    expect(PeriodFilterHelper.label((1405, 4)), 'تیر ۱۴۰۵');
  });

  test('period index round trips across year boundaries', () {
    final esfand = PeriodFilterHelper.periodIndex((1404, 12));

    expect(PeriodFilterHelper.periodFromIndex(esfand + 1), (1405, 1));
  });

  test('period selection falls back after its last record is deleted', () {
    expect(
      PeriodFilterHelper.resolveAvailablePeriod(
        selected: (1405, 4),
        available: [(1405, 3), (1405, 2)],
        preferred: (1405, 4),
      ),
      (1405, 3),
    );
    expect(
      PeriodFilterHelper.resolveAvailablePeriod(
        selected: (1405, 4),
        available: const [],
      ),
      isNull,
    );
  });
}
