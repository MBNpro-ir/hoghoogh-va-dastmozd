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
  }) => SalaryRecord(
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
  final bool autoShiftWork; // محاسبه ۱۵٪ نوبت‌کاری از حقوق ثابت
  final bool autoHourlyBenefits; // محاسبه از ساعت مزایای ثبت‌شده در قرارداد
  final bool insuranceExempt; // عدم شمول بیمه برای ردیف‌های خاص
  final bool taxExempt; // عدم شمول مالیات برای ردیف‌های خاص
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
    this.autoShiftWork = false,
    this.autoHourlyBenefits = false,
    this.insuranceExempt = false,
    this.taxExempt = false,
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
      final taxableInBracket = (monthlyTaxableIncome.clamp(from, to) - from)
          .clamp(0.0, double.infinity);
      tax += taxableInBracket * rate;
      if (monthlyTaxableIncome <= to) break;
    }
    return tax;
  }

  /// محاسبه معافیت دو هفتم
  /// در فایل ارسالی نسبت تقریبی 1.86٪ از جمع حقوق و مزایا است
  static double calculateTwoSevenExemption({
    required double insurance,
    required double exemptionRate,
  }) {
    return insurance * exemptionRate;
  }

  /// محاسبه کامل فیش حقوق ماهانه
  static SalaryCalculationResult calculate({
    required Employee employee,
    required AppSettings settings,
    required SalaryCalculationInput input,
  }) {
    final totalDays = input.totalDays;
    final benefitDays = totalDays.clamp(0, AppConstants.standardMonthDays);

    // 1) حقوق ثابت = دستمزد روزانه × کل روزها
    final baseSalary = employee.dailyWage1405 * totalDays;

    // 2) مزایای ثابت در اکسل با سقف 30 روز محاسبه می‌شوند.
    final housing = employee.dailyHousing * benefitDays;

    // 3) حق خواروبار = روزانه × min(کل کارکرد، 30)
    final food = employee.dailyFood * benefitDays;

    // 4) حق تاهل = (در صورت متاهل بودن) روزانه × min(کل کارکرد، 30)
    final marriage = employee.isMarried
        ? employee.dailyMarriage * benefitDays
        : 0.0;

    // 5) حق فرزند = مبلغ روزانه هر فرزند × تعداد فرزند × min(کل کارکرد، 30)
    final childAllowance =
        employee.dailyChildAllowance * employee.childrenCount * benefitDays;

    // 6) پایه سنوات در اکسل با کل کارکرد محاسبه می‌شود.
    final seniority = employee.dailySeniority * totalDays;

    // 7) سایر مزایا = روزانه × کل کارکرد (یا مقدار override)
    final otherBenefits = input.otherBenefitsOverride >= 0
        ? input.otherBenefitsOverride
        : employee.otherBenefitsDaily * totalDays;

    // 8) اضافه‌کاری و مزایای ساعتی = ساعت × (دستمزد ساعتی × 1.40)
    final hourlyRate = employee.dailyWage1405 / AppConstants.dailyWorkHours;
    final overtimeRate = hourlyRate * AppConstants.overtimeMultiplier;
    final overtimeAmount = input.overtimeHours * overtimeRate;
    final hourlyBenefitsAmount = input.autoHourlyBenefits
        ? employee.hourlyBenefits * overtimeRate
        : input.hourlyBenefitsAmount;

    // 9) نوبت‌کاری در اکسل برای افراد مشمول، 15٪ حقوق ثابت است.
    final shiftWork = input.autoShiftWork
        ? baseSalary * AppConstants.shiftWorkRate
        : input.shiftWork;

    // 10) جمع کل حقوق و مزایا
    final totalEarnings =
        baseSalary +
        housing +
        food +
        marriage +
        childAllowance +
        seniority +
        otherBenefits +
        shiftWork +
        overtimeAmount +
        hourlyBenefitsAmount;

    // 11) مبنای بیمه مطابق اکسل:
    // min(جمع حقوق و مزایا - حق فرزند، حداقل دستمزد روزانه × 7 × کل کارکرد)
    final uncappedInsuranceBase = (totalEarnings - childAllowance).clamp(
      0.0,
      double.infinity,
    );
    final insuranceCap =
        settings.dailyWage * AppConstants.insuranceCapMultiplier * totalDays;
    final insuranceBase = input.insuranceExempt
        ? 0.0
        : uncappedInsuranceBase < insuranceCap
        ? uncappedInsuranceBase
        : insuranceCap;

    final insurance = insuranceBase * settings.employeeInsuranceRate;

    // 12) معافیت دو هفتم = دو هفتم حق بیمه کارگر
    final twoSevenExemption = calculateTwoSevenExemption(
      insurance: insurance,
      exemptionRate: settings.twoSevenBaseRate,
    );

    // 13) مبنای مالیات
    final taxBase = (totalEarnings - twoSevenExemption).clamp(
      0.0,
      double.infinity,
    );

    final tax = input.taxExempt ? 0.0 : calculateTax(taxBase);

    // 14) جمع کسورات
    final totalDeductions =
        insurance +
        tax +
        input.loanInstallment +
        input.advance +
        input.otherDeductions;

    // 15) خالص حقوق
    final netSalary = totalEarnings - totalDeductions;

    // 16) رند نهایی اکسل: ROUND(خالص، -3)
    final roundedFinal = netSalary <= 0 ? 0 : (netSalary / 1000).round() * 1000;
    final rounding = (roundedFinal - netSalary).round();

    // 17) سهم کارفرما
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
      shiftWork: shiftWork,
      overtimeAmount: overtimeAmount,
      hourlyBenefitsAmount: hourlyBenefitsAmount,
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
