import 'package:shamsi_date/shamsi_date.dart';

import 'persian_date_helper.dart';
import '../models/app_settings.dart';

class SeniorityHelper {
  static const double dailySeniority1405 = 166667;

  static const Map<int, double> _cumulativeDailySeniority1405 = {
    1376: 1929905,
    1377: 1925108,
    1378: 1919514,
    1379: 1912677,
    1380: 1912677,
    1381: 1912677,
    1382: 1912677,
    1383: 1912677,
    1384: 1912677,
    1385: 1912677,
    1386: 1890983,
    1387: 1870320,
    1388: 1850642,
    1389: 1821216,
    1390: 1793460,
    1391: 1761029,
    1392: 1725652,
    1393: 1673007,
    1394: 1583016,
    1395: 1504079,
    1396: 1384261,
    1397: 1275730,
    1398: 1143903,
    1399: 980142,
    1400: 798186,
    1401: 600404,
    1402: 436949,
    1403: 302967,
    1404: 166667,
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
      if (parsed.year >= settings.year) return 0;
      final fullYearRate =
          _cumulativeDailySeniority1405[parsed.year] ??
          _cumulativeDailySeniority1405[_cumulativeDailySeniority1405
              .keys
              .first] ??
          settings.dailySeniority;
      final anniversary = _anniversaryInYear(parsed, settings.year);
      return _compare(effectiveDate, anniversary) < 0
          ? (fullYearRate - dailySeniority1405).clamp(0, double.infinity)
          : fullYearRate;
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

  static Jalali _anniversaryInYear(Jalali startDate, int year) {
    final day = startDate.day.clamp(
      1,
      PersianDateHelper.daysInMonth(year, startDate.month),
    );
    return Jalali(year, startDate.month, day);
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
