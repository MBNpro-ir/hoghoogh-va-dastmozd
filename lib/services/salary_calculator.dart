import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/salary_record.dart';
import '../utils/constants.dart';

/// نتیجه محاسبه فیش حقوق
class SalaryCalculationResult {
  // اجزای حقوق و مزایا
  final double baseSalary; // حقوق ثابت
  final double housing; // حق مسکن
  final double food; // حق خواروبار
  final double marriage; // حق تاهل
  final double childAllowance; // حق فرزند
  final double seniority; // پایه سنوات
  final double otherBenefits; // سایر مزایا
  final double shiftWork; // نوبت‌کاری
  final double overtimeAmount; // اضافه‌کاری
  final double hourlyBenefitsAmount; // مزایای ساعتی
  final double totalEarnings; // جمع حقوق و مزایا

  // کسورات
  final double insurance; // حق بیمه 7%
  final double tax; // مالیات
  final double loanInstallment; // قسط وام
  final double advance; // مساعده
  final double otherDeductions; // سایر کسورات
  final double totalDeductions; // جمع کسورات

  // محاسبات
  final double insuranceBase; // مبنای بیمه (حقوق مشمول بیمه)
  final double taxBase; // مبنای مالیات
  final double twoSevenExemption; // معافیت دو هفتم

  // مبالغ کارفرما
  final double employerInsurance; // سهم کارفرما (20%)
  final double unemploymentInsurance; // بیمه بیکاری (3%)

  // نهایی
  final double netSalary; // خالص حقوق
  final int rounding; // رند
  final double finalPayment; // خالص دریافتی

  SalaryCalculationResult({
    required this.baseSalary,
    required this.housing,
    required this.food,
    required this.marriage,
    required this.childAllowance,
    required this.seniority,
    required this.otherBenefits,
    required this.shiftWork,
    required this.overtimeAmount,
    required this.hourlyBenefitsAmount,
    required this.totalEarnings,
    required this.insurance,
    required this.tax,
    required this.loanInstallment,
    required this.advance,
    required this.otherDeductions,
    required this.totalDeductions,
    required this.insuranceBase,
    required this.taxBase,
    required this.twoSevenExemption,
    required this.employerInsurance,
    required this.unemploymentInsurance,
    required this.netSalary,
    required this.rounding,
    required this.finalPayment,
  });

  SalaryRecord toRecord({
    required int employeeId,
    required int year,
    required int month,
    required int totalDays,
    required int leaveDays,
    required int workDays,
    required double overtimeHours,
    String? notes,
  }) =>
      SalaryRecord(
        employeeId: employeeId,
        year: year,
        month: month,
        totalDays: totalDays,
        leaveDays: leaveDays,
        workDays: workDays,
        overtimeHours: overtimeHours,
        overtimeAmount: overtimeAmount,
        shiftWork: shiftWork,
        hourlyBenefitsAmount: hourlyBenefitsAmount,
        baseSalary: baseSalary,
        housing: housing,
        food: food,
        marriage: marriage,
        childAllowance: childAllowance,
        seniority: seniority,
        otherBenefits: otherBenefits,
        totalEarnings: totalEarnings,
        insurance: insurance,
        tax: tax,
        loanInstallment: loanInstallment,
        advance: advance,
        otherDeductions: otherDeductions,
        totalDeductions: totalDeductions,
        insuranceBase: insuranceBase,
        taxBase: taxBase,
        twoSevenExemption: twoSevenExemption,
        netSalary: netSalary,
        rounding: rounding,
        finalPayment: finalPayment,
        notes: notes,
      );
}

/// ورودی‌های محاسبه ماهانه
class SalaryCalculationInput {
  final int totalDays; // کل کارکرد (روزهای ماه)
  final int leaveDays; // مرخصی
  final double overtimeHours; // ساعت اضافه‌کاری
  final double shiftWork; // مبلغ نوبت‌کاری
  final double hourlyBenefitsAmount; // مزایای ساعتی محاسبه‌شده
  final double otherBenefitsOverride; // سایر مزایا - دستی
  final double loanInstallment; // قسط وام
  final double advance; // مساعده
  final double otherDeductions; // سایر کسورات (مابه‌تفاوت)

  SalaryCalculationInput({
    this.totalDays = 30,
    this.leaveDays = 0,
    this.overtimeHours = 0,
    this.shiftWork = 0,
    this.hourlyBenefitsAmount = 0,
    this.otherBenefitsOverride = -1, // -1 = خودکار (از کارمند)
    this.loanInstallment = 0,
    this.advance = 0,
    this.otherDeductions = 0,
  });

  int get workDays => (totalDays - leaveDays).clamp(0, totalDays);
}

/// سرویس محاسبه حقوق - منطق اصلی برنامه
class SalaryCalculator {
  /// محاسبه دستمزد روزانه 1405 بر اساس دستمزد 1404 و ضریب افزایش
  ///
  /// فرمول طبق فایل اکسل ارسالی:
  /// دستمزد روزانه 1405 = دستمزد روزانه 1404 × ضریب + ثابت ریالی
  ///
  /// ضریب: 1.45 برای کارگری | 1.50 برای ریالی
  static double calculateDailyWage1405({
    required double dailyWage1404,
    required double rate, // 1.45 یا 1.50
    required double fixedRial,
  }) {
    return dailyWage1404 * rate + fixedRial;
  }

  /// محاسبه پایه سنوات روزانه بر اساس سابقه کار
  /// سابقه کار بیش از یک سال مشمول پایه سنوات می‌شود
  static double calculateDailySeniority({
    required int yearsOfService,
    double basePerYear = 0,
  }) {
    if (yearsOfService < 1) return 0;
    return basePerYear;
  }

  /// محاسبه مالیات بر حقوق بر اساس جدول پلکانی 1405
  /// مبنای مالیات: جمع حقوق و مزایا منهای معافیت دو هفتم
  static double calculateTax(double monthlyTaxableIncome) {
    if (monthlyTaxableIncome <= 0) return 0;
    double tax = 0;
    for (final bracket in AppConstants.taxBrackets) {
      final from = bracket['from'] as double;
      final to = bracket['to'] as double;
      final rate = bracket['rate'] as double;

      if (monthlyTaxableIncome <= from) break;
      final taxableInBracket =
          (monthlyTaxableIncome.clamp(from, to) - from).clamp(0.0, double.infinity);
      tax += taxableInBracket * rate;
      if (monthlyTaxableIncome <= to) break;
    }
    return tax;
  }

  /// محاسبه معافیت دو هفتم
  /// در فایل ارسالی نسبت تقریبی 1.86٪ از جمع حقوق و مزایا است
  static double calculateTwoSevenExemption({
    required double totalEarnings,
    required double exemptionRate,
  }) {
    return totalEarnings * exemptionRate;
  }

  /// محاسبه کامل فیش حقوق ماهانه
  static SalaryCalculationResult calculate({
    required Employee employee,
    required AppSettings settings,
    required SalaryCalculationInput input,
  }) {
    final totalDays = input.totalDays;
    final workDays = input.workDays;

    // 1) حقوق ثابت = دستمزد روزانه × کل روزها
    final baseSalary = employee.dailyWage1405 * totalDays;

    // 2) حق مسکن = روزانه × 30 (استاندارد)
    final housing = employee.dailyHousing * AppConstants.standardMonthDays;

    // 3) حق خواروبار = روزانه × 30
    final food = employee.dailyFood * AppConstants.standardMonthDays;

    // 4) حق تاهل = (در صورت متاهل بودن) روزانه × 30
    final marriage = employee.isMarried
        ? employee.dailyMarriage * AppConstants.standardMonthDays
        : 0.0;

    // 5) حق فرزند = روزانه × 30 × تعداد فرزند
    final childAllowance = employee.dailyChildAllowance *
        AppConstants.standardMonthDays *
        employee.childrenCount;

    // 6) پایه سنوات = روزانه × 30
    final seniority =
        employee.dailySeniority * AppConstants.standardMonthDays;

    // 7) سایر مزایا = روزانه × کارکرد خالص (یا مقدار override)
    final otherBenefits = input.otherBenefitsOverride >= 0
        ? input.otherBenefitsOverride
        : employee.otherBenefitsDaily * workDays;

    // 8) اضافه‌کاری = ساعت × (دستمزد ساعتی × 1.40)
    final hourlyRate = employee.dailyWage1405 / 7.33; // 220 ساعت ماهانه / 30 روز ≈ 7.33
    final overtimeAmount =
        input.overtimeHours * hourlyRate * AppConstants.overtimeMultiplier;

    // 9) جمع کل حقوق و مزایا
    final totalEarnings = baseSalary +
        housing +
        food +
        marriage +
        childAllowance +
        seniority +
        otherBenefits +
        input.shiftWork +
        overtimeAmount +
        input.hourlyBenefitsAmount;

    // 10) مبنای بیمه = حقوق ثابت + مزایای مشمول
    // حقوق مشمول بیمه = حقوق و مزایا منهای کمک هزینه‌های غیرنقدی (مسکن، خواروبار)
    final insuranceBase = baseSalary +
        marriage +
        childAllowance +
        seniority +
        otherBenefits +
        input.shiftWork +
        overtimeAmount +
        input.hourlyBenefitsAmount;

    final insurance = insuranceBase * settings.employeeInsuranceRate;

    // 11) معافیت دو هفتم
    final twoSevenExemption = calculateTwoSevenExemption(
      totalEarnings: totalEarnings,
      exemptionRate: settings.twoSevenBaseRate,
    );

    // 12) مبنای مالیات
    final taxBase =
        (totalEarnings - twoSevenExemption).clamp(0.0, double.infinity);

    final tax = calculateTax(taxBase);

    // 13) جمع کسورات
    final totalDeductions = insurance +
        tax +
        input.loanInstallment +
        input.advance +
        input.otherDeductions;

    // 14) خالص حقوق
    final netSalary = totalEarnings - totalDeductions;

    // 15) رند نهایی (به نزدیکترین 1000)
    final roundedFinal = (netSalary ~/ 1000) * 1000;
    final rounding = (netSalary - roundedFinal).round();

    // 16) سهم کارفرما
    final employerInsurance = insuranceBase * settings.employerInsuranceRate;
    final unemploymentInsurance =
        insuranceBase * settings.unemploymentInsuranceRate;

    return SalaryCalculationResult(
      baseSalary: baseSalary,
      housing: housing,
      food: food,
      marriage: marriage,
      childAllowance: childAllowance,
      seniority: seniority,
      otherBenefits: otherBenefits,
      shiftWork: input.shiftWork,
      overtimeAmount: overtimeAmount,
      hourlyBenefitsAmount: input.hourlyBenefitsAmount,
      totalEarnings: totalEarnings,
      insurance: insurance,
      tax: tax,
      loanInstallment: input.loanInstallment,
      advance: input.advance,
      otherDeductions: input.otherDeductions,
      totalDeductions: totalDeductions,
      insuranceBase: insuranceBase,
      taxBase: taxBase,
      twoSevenExemption: twoSevenExemption,
      employerInsurance: employerInsurance,
      unemploymentInsurance: unemploymentInsurance,
      netSalary: netSalary,
      rounding: rounding,
      finalPayment: roundedFinal.toDouble(),
    );
  }
}
