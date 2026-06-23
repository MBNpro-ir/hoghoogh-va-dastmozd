import 'persian_date_helper.dart';
import 'persian_number_formatter.dart';

class PeriodFilterHelper {
  const PeriodFilterHelper._();

  static (int, int)? parsePeriod(String value) {
    final normalized = PersianNumberFormatter.toEnglish(value.trim());
    final match = RegExp(r'^(\d{4})[/-](\d{1,2})').firstMatch(normalized);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }
    return (year, month);
  }

  static int periodIndex((int, int) period) => period.$1 * 12 + period.$2;

  static (int, int) periodFromIndex(int index) {
    final year = (index - 1) ~/ 12;
    final month = ((index - 1) % 12) + 1;
    return (year, month);
  }

  static List<(int, int)> periodsFromDates(Iterable<String> dates) {
    final periods = <(int, int)>{};
    for (final date in dates) {
      final period = parsePeriod(date);
      if (period != null) periods.add(period);
    }
    final sorted = periods.toList();
    sorted.sort((a, b) => periodIndex(b).compareTo(periodIndex(a)));
    return sorted;
  }

  static bool dateIsInPeriod(String date, (int, int) period) {
    return parsePeriod(date) == period;
  }

  static (int, int)? resolveAvailablePeriod({
    required (int, int)? selected,
    required List<(int, int)> available,
    (int, int)? preferred,
  }) {
    if (selected != null && available.contains(selected)) return selected;
    if (available.isEmpty) return null;
    if (preferred != null && available.contains(preferred)) return preferred;
    return available.first;
  }

  static String label((int, int) period) {
    return '${PersianDateHelper.monthName(period.$2)} '
        '${PersianNumberFormatter.toPersian(period.$1.toString())}';
  }
}
