import 'package:shamsi_date/shamsi_date.dart';

/// کلاس کمکی برای کار با تاریخ شمسی
class PersianDateHelper {
  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> weekDays = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه',
  ];

  static Jalali today([DateTime? now]) {
    return Jalali.fromDateTime(now ?? DateTime.now());
  }

  static int get currentYear => today().year;

  static int get currentMonth => today().month;

  static String todayText([DateTime? now]) => formatJalali(today(now));

  static List<int> nearbyYearOptions({
    int? selectedYear,
    int yearsBefore = 2,
    int yearsAfter = 2,
  }) {
    final current = currentYear;
    final years = <int>{
      for (
        var year = current - yearsBefore;
        year <= current + yearsAfter;
        year++
      )
        year,
    };
    if (selectedYear != null) years.add(selectedYear);
    return years.toList()..sort();
  }

  /// تعداد روزهای ماه شمسی
  static int daysInMonth(int year, int month) {
    if (month >= 1 && month <= 6) return 31;
    if (month >= 7 && month <= 11) return 30;
    // اسفند: 29 یا 30 (سال کبیسه)
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  /// تبدیل تاریخ میلادی به شمسی
  static Jalali fromGregorian(DateTime date) {
    return Jalali.fromDateTime(date);
  }

  /// تبدیل به متن شمسی
  static String formatJalali(Jalali date) {
    final f = date.formatter;
    return '${f.yyyy}/${f.mm}/${f.dd}';
  }

  /// تبدیل متن شمسی به Jalali (yyyy/mm/dd)
  static Jalali? parseJalali(String text) {
    try {
      final parts = text.trim().split('/');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return Jalali(y, m, d);
    } catch (_) {
      return null;
    }
  }

  /// محاسبه سابقه به سال (سال شمسی)
  static int yearsSince(Jalali startDate, {Jalali? endDate}) {
    final end = endDate ?? Jalali.now();
    int years = end.year - startDate.year;
    if (end.month < startDate.month ||
        (end.month == startDate.month && end.day < startDate.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  /// نام ماه
  static String monthName(int month) {
    if (month < 1 || month > 12) return '';
    return monthNames[month - 1];
  }
}
