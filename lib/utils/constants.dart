/// ثابت‌های برنامه - مقادیر پیش‌فرض حقوق و دستمزد 1405
class AppConstants {
  static const String appName = 'حقوق و دستمزد فرایند کود و سم بافق';
  static const String appVersion = '0.0.2 alpha';
  static const String fontFamily = 'Vazirmatn';

  // سال محاسبات
  static const int currentYear = 1405;

  // ----- مقادیر پیش‌فرض حقوق مصوب 1405 (ریال) -----
  static const double defaultDailyWage = 5541850; // دستمزد روزانه پایه
  static const double defaultMonthlyFood = 22000000; // بن (ماهانه)
  static const double defaultMonthlyHousing = 30000000; // حق مسکن (ماهانه)
  static const double defaultMonthlyMarriage = 16625550; // حق تاهل (ماهانه)
  static const double defaultMonthlyChild = 5000000; // حق فرزند (ماهانه)
  static const double defaultDailySeniority = 166667; // پایه سنوات (روزانه)

  static const double salaryRateA = 1.45; // درصد سایر سطوح روزانه
  static const double salaryRateB = 1.50; // درصد سایر سطوح ریالی
  static const double fixedRial = 519549; // ثابت ریالی

  // ----- درصد بیمه -----
  static const double employeeInsuranceRate = 0.07; // 7% سهم کارمند
  static const double employerInsuranceRate = 0.20; // 20% سهم کارفرما
  static const double unemploymentInsuranceRate = 0.03; // 3% بیمه بیکاری

  // ----- جدول مالیات بر حقوق 1405 (ماهانه - ریال) -----
  // مطابق جدول شرکت فرایند کود و سم بافق
  static const List<Map<String, dynamic>> taxBrackets = [
    {'from': 0.0, 'to': 400000000.0, 'rate': 0.00},
    {'from': 400000000.0, 'to': 800000000.0, 'rate': 0.10},
    {'from': 800000000.0, 'to': 1000000000.0, 'rate': 0.15},
    {'from': 1000000000.0, 'to': 12000000000.0, 'rate': 0.20},
    {'from': 12000000000.0, 'to': 14000000000.0, 'rate': 0.25},
    {'from': 14000000000.0, 'to': double.infinity, 'rate': 0.30},
  ];

  // ----- معافیت دو هفتم (برای صنایع سخت) -----
  // ضریب اعمال بر حقوق پایه برای محاسبه معافیت
  static const double twoSevenRate = 2 / 7;

  // اعمال معافیت روی این درصد از حقوق پایه (تنظیم قابل تغییر)
  // در فایل اکسل ارسالی، نسبت کلی حدود 1.85% است
  static const double twoSevenBaseRate = 0.0186;

  // ----- روزهای استاندارد ماه -----
  static const int standardMonthDays = 30;

  // ساعت کار استاندارد ماه
  static const double standardMonthlyHours = 176; // 22 روز * 8 ساعت

  // ----- ضرایب اضافه‌کاری و نوبت‌کاری -----
  static const double overtimeMultiplier = 1.40; // 140% اضافه‌کاری
  static const double nightShiftMultiplier = 0.35; // 35% نوبت‌کاری شب
}
