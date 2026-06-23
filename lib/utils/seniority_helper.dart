import 'package:shamsi_date/shamsi_date.dart';

import 'persian_date_helper.dart';
import '../models/app_settings.dart';

class SeniorityHelper {
  static const Map<int, double> _cumulativeDailySeniority1405 = {
    1389: 1141068,
    1393: 1038853,
    1395: 922360,
    1396: 839722,
    1397: 764871,
    1398: 673957,
    1400: 435530,
    1402: 436949,
    1403: 94000,
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
    final serviceYears = PersianDateHelper.yearsSince(
      parsed,
      endDate: asOf ?? _payrollYearEnd(settings.year),
    );
    if (serviceYears < 1) return 0;
    if (settings.year == 1405) {
      return _cumulativeDailySeniority1405[parsed.year] ??
          settings.dailySeniority;
    }
    return settings.dailySeniority;
  }

  static Jalali _payrollYearEnd(int year) {
    return Jalali(year, 12, Jalali(year).isLeapYear() ? 30 : 29);
  }
}
