import 'package:intl/intl.dart';

/// تبدیل اعداد انگلیسی به فارسی
class PersianNumberFormatter {
  static const Map<String, String> _enToFa = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };

  static const Map<String, String> _faToEn = {
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// تبدیل ارقام انگلیسی به فارسی
  static String toPersian(String input) {
    String result = input;
    _enToFa.forEach((en, fa) {
      result = result.replaceAll(en, fa);
    });
    return result;
  }

  /// تبدیل ارقام فارسی/عربی به انگلیسی
  static String toEnglish(String input) {
    String result = input;
    _faToEn.forEach((fa, en) {
      result = result.replaceAll(fa, en);
    });
    return result;
  }

  /// فرمت عدد با جداکننده هزارگان به صورت فارسی
  static String formatNumber(num value, {bool persian = true}) {
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(value);
    return persian ? toPersian(formatted) : formatted;
  }

  /// فرمت مقدار ریالی
  static String formatRial(
    num value, {
    bool persian = true,
    bool showUnit = false,
  }) {
    final formatted = formatNumber(value, persian: persian);
    return showUnit ? '$formatted ریال' : formatted;
  }

  /// تبدیل متن فارسی/انگلیسی به عدد
  static num? parseNumber(String input) {
    if (input.trim().isEmpty) return null;
    String cleaned = toEnglish(
      input,
    ).replaceAll(',', '').replaceAll('،', '').trim();
    return num.tryParse(cleaned);
  }
}
