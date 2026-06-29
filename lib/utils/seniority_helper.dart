import 'package:shamsi_date/shamsi_date.dart';

import 'persian_date_helper.dart';
import '../models/app_settings.dart';

class SeniorityHelper {
  static const double dailySeniority1405 = 166667;

  static const Map<int, double> _dailySeniority1405ByServiceYears = {
    1: 166667,
    2: 302967,
    3: 436947,
    4: 600403,
    5: 798184,
    6: 980142,
    7: 1143906,
    8: 1275733,
    9: 1384264,
    10: 1504088,
    11: 1583025,
    12: 1673014,
    13: 1725660,
    14: 1761041,
    15: 1793472,
    16: 1821234,
    17: 1850658,
    18: 1870336,
    19: 1890997,
    20: 1912693,
    21: 1936558,
    22: 1957976,
    23: 1976879,
    24: 1991789,
    25: 2004572,
    26: 2015417,
    27: 2024591,
    28: 2030201,
    29: 2034946,
    30: 2039736,
  };

  static Jalali? parseStartDate(String text) {
    final normalized = text.trim().replaceAll('-', '/');
    return PersianDateHelper.parseJalali(normalized);
  }

  static bool hasAtLeastOneYear(String startDate, {Jalali? asOf}) {
    final parsed = parseStartDate(startDate);
    if (parsed == null) return false;
    return PersianDateHelper.yearsSince(parsed, endDate: asOf) >= 1;
  }

  static bool isEligibleForPriorExperience({
    required String startDate,
    required AppSettings settings,
  }) {
    return hasAtLeastOneYear(startDate, asOf: _payrollYearEnd(settings.year));
  }

  static double calculateDailySeniority({
    required String startDate,
    required AppSettings settings,
    Jalali? asOf,
  }) {
    final parsed = parseStartDate(startDate);
    if (parsed == null) return 0;
    final effectiveDate = asOf ?? _payrollYearEnd(settings.year);
    if (_compare(effectiveDate, parsed) < 0) return 0;
    final serviceYears = PersianDateHelper.yearsSince(
      parsed,
      endDate: effectiveDate,
    );
    if (serviceYears < 1) return 0;
    if (settings.year == 1405) {
      return _dailySeniority1405ByServiceYears[serviceYears] ??
          _dailySeniority1405ByServiceYears[
              _dailySeniority1405ByServiceYears.keys.last] ??
          settings.dailySeniority;
    }
    return settings.dailySeniority;
  }

  /// Average daily rate for a payroll month. In an anniversary month this
  /// preserves the exact split between days before and after the anniversary.
  static double calculateEffectiveDailySeniorityForMonth({
    required String startDate,
    required AppSettings settings,
    required int year,
    required int month,
  }) {
    final days = PersianDateHelper.daysInMonth(year, month);
    var total = 0.0;
    for (var day = 1; day <= days; day++) {
      total += calculateDailySeniority(
        startDate: startDate,
        settings: settings,
        asOf: Jalali(year, month, day),
      );
    }
    return total / days;
  }

  static double calculateMonthlySeniority({
    required String startDate,
    required AppSettings settings,
    required int year,
    required int month,
    required double payableDays,
  }) {
    return calculateEffectiveDailySeniorityForMonth(
          startDate: startDate,
          settings: settings,
          year: year,
          month: month,
        ) *
        payableDays;
  }

  static int _compare(Jalali left, Jalali right) {
    if (left.year != right.year) return left.year.compareTo(right.year);
    if (left.month != right.month) return left.month.compareTo(right.month);
    return left.day.compareTo(right.day);
  }

  static Jalali _payrollYearEnd(int year) {
    return Jalali(year, 12, Jalali(year).isLeapYear() ? 30 : 29);
  }
}
