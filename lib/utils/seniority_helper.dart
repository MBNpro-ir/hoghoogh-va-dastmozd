import 'package:shamsi_date/shamsi_date.dart';

import 'persian_date_helper.dart';
import '../models/app_settings.dart';

class SeniorityHelper {
  static const Map<int, double> _cumulativeDailySeniority1405 = {
    1375: 2039736,
    1376: 2034946,
    1377: 2030201,
    1378: 2024591,
    1379: 2015417,
    1380: 2004572,
    1381: 1991789,
    1382: 1976879,
    1383: 1957976,
    1384: 1936558,
    1385: 1912693,
    1386: 1890997,
    1387: 1870336,
    1388: 1850658,
    1389: 1821234,
    1390: 1793472,
    1391: 1761041,
    1392: 1725660,
    1393: 1673014,
    1394: 1583025,
    1395: 1504088,
    1396: 1384264,
    1397: 1275733,
    1398: 1143906,
    1399: 980142,
    1400: 798184,
    1401: 600403,
    1402: 436947,
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
    final serviceYears = PersianDateHelper.yearsSince(
      parsed,
      endDate: asOf ?? _payrollYearEnd(settings.year),
    );
    if (serviceYears < 1) return 0;
    if (settings.year == 1405) {
      if (parsed.year >= settings.year) return 0;
      return _cumulativeDailySeniority1405[parsed.year] ??
          _cumulativeDailySeniority1405[_cumulativeDailySeniority1405
              .keys
              .first] ??
          settings.dailySeniority;
    }
    return settings.dailySeniority;
  }

  static Jalali _payrollYearEnd(int year) {
    return Jalali(year, 12, Jalali(year).isLeapYear() ? 30 : 29);
  }
}
