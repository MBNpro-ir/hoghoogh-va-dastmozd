import 'dart:convert';

import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/salary_record.dart';
import '../utils/constants.dart';
import '../utils/seniority_helper.dart';

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
  final double nightWorkAmount;
  final double fridayWorkAmount;
  final double holidayWorkAmount;
  final double missionAmount;
  final bool useCustomOvertimeBase;
  final double overtimeBaseDaily;
  final double hourlyBenefitsAmount; // مزایای ساعتی
  final double hourlyBenefitHours; // ساعت مزایای ساعتی
  final double totalEarnings; // جمع حقوق و مزایا
  final double payableDays; // روزهای قابل پرداخت توسط کارفرما

  // کسورات
  final double insurance; // حق بیمه 7%
  final double tax; // مالیات
  final double loanInstallment; // قسط وام
  final double advance; // مساعده
  final double otherDeductions; // سایر کسورات
  final double leaveAllowanceDays; // مرخصی مجاز ماهانه
  final double excessLeaveDays; // مرخصی مازاد
  final double leaveDeduction; // کسر مرخصی مازاد
  final double absenceDeduction;
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
  final String payrollCalculationDetailsJson;

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
    required this.nightWorkAmount,
    required this.fridayWorkAmount,
    required this.holidayWorkAmount,
    required this.missionAmount,
    required this.useCustomOvertimeBase,
    required this.overtimeBaseDaily,
    required this.hourlyBenefitsAmount,
    required this.hourlyBenefitHours,
    required this.totalEarnings,
    required this.payableDays,
    required this.insurance,
    required this.tax,
    required this.loanInstallment,
    required this.advance,
    required this.otherDeductions,
    required this.leaveAllowanceDays,
    required this.excessLeaveDays,
    required this.leaveDeduction,
    required this.absenceDeduction,
    required this.totalDeductions,
    required this.insuranceBase,
    required this.taxBase,
    required this.twoSevenExemption,
    required this.employerInsurance,
    required this.unemploymentInsurance,
    required this.netSalary,
    required this.rounding,
    required this.finalPayment,
    required this.payrollCalculationDetailsJson,
  });

  SalaryRecord toRecord({
    required int employeeId,
    String? employeeFullNameSnapshot,
    int? employeePersonnelCodeSnapshot,
    String? employeeNationalIdSnapshot,
    String? employeePayslipFooterNoteSnapshot,
    required int year,
    required int month,
    required int totalDays,
    required double leaveDays,
    required double sickLeaveDays,
    required double workDays,
    required double overtimeHours,
    double nightWorkHours = 0,
    double fridayWorkHours = 0,
    double holidayWorkHours = 0,
    double missionDays = 0,
    double absenceDays = 0,
    double absenceHours = 0,
    required double hourlyBenefitHours,
    required bool includeLeaveInPayslip,
    required bool housingExempt,
    required bool foodExempt,
    required bool seniorityExempt,
    String? notes,
  }) => SalaryRecord(
    employeeId: employeeId,
    employeeFullNameSnapshot: employeeFullNameSnapshot,
    employeePersonnelCodeSnapshot: employeePersonnelCodeSnapshot,
    employeeNationalIdSnapshot: employeeNationalIdSnapshot,
    employeePayslipFooterNoteSnapshot: employeePayslipFooterNoteSnapshot,
    year: year,
    month: month,
    totalDays: totalDays,
    leaveDays: leaveDays,
    sickLeaveDays: sickLeaveDays,
    workDays: workDays,
    overtimeHours: overtimeHours,
    overtimeAmount: overtimeAmount,
    nightWorkHours: nightWorkHours,
    nightWorkAmount: nightWorkAmount,
    fridayWorkHours: fridayWorkHours,
    fridayWorkAmount: fridayWorkAmount,
    holidayWorkHours: holidayWorkHours,
    holidayWorkAmount: holidayWorkAmount,
    missionDays: missionDays,
    missionAmount: missionAmount,
    useCustomOvertimeBase: useCustomOvertimeBase,
    overtimeBaseDaily: overtimeBaseDaily,
    shiftWork: shiftWork,
    hourlyBenefitsAmount: hourlyBenefitsAmount,
    hourlyBenefitHours: hourlyBenefitHours,
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
    absenceDays: absenceDays,
    absenceHours: absenceHours,
    absenceDeduction: absenceDeduction,
    includeLeaveInPayslip: includeLeaveInPayslip,
    housingExempt: housingExempt,
    foodExempt: foodExempt,
    seniorityExempt: seniorityExempt,
    leaveAllowanceDays: leaveAllowanceDays,
    excessLeaveDays: excessLeaveDays,
    leaveDeduction: leaveDeduction,
    totalDeductions: totalDeductions,
    insuranceBase: insuranceBase,
    taxBase: taxBase,
    twoSevenExemption: twoSevenExemption,
    netSalary: netSalary,
    rounding: rounding,
    finalPayment: finalPayment,
    payrollCalculationDetailsJson: payrollCalculationDetailsJson,
    notes: notes,
  );
}

/// ورودی‌های محاسبه ماهانه
class SalaryCalculationInput {
  final int? year;
  final int? month;
  final int totalDays; // کل کارکرد (روزهای ماه)
  final double leaveDays; // مرخصی
  final double sickLeaveDays; // مرخصی استعلاجی تاییدشده
  final double overtimeHours; // ساعت اضافه‌کاری
  final double nightWorkHours;
  final double fridayWorkHours;
  final double holidayWorkHours;
  final double missionDays;
  final bool useCustomOvertimeBase;
  final double overtimeBaseDaily;
  final double shiftWork; // مبلغ نوبت‌کاری
  final double hourlyBenefitsAmount; // مزایای ساعتی محاسبه‌شده
  final double hourlyBenefitHours; // ساعت مزایای ساعتی
  final bool autoShiftWork; // محاسبه ۱۵٪ نوبت‌کاری از حقوق ثابت
  final bool autoHourlyBenefits; // محاسبه از ساعت مزایای ثبت‌شده در قرارداد
  final bool includeLeaveInPayslip; // محاسبه مرخصی در فیش
  final bool insuranceExempt; // عدم شمول بیمه برای ردیف‌های خاص
  final bool taxExempt; // عدم شمول مالیات برای ردیف‌های خاص
  final bool housingExempt; // حذف حق مسکن از این فیش
  final bool foodExempt; // حذف حق خواروبار از این فیش
  final bool seniorityExempt; // حذف پایه سنوات از این فیش
  final double dailySeniorityOverride; // نرخ روزانه دستی؛ منفی یعنی خودکار
  final double otherBenefitsOverride; // سایر مزایا - دستی
  final double loanInstallment; // قسط وام
  final double advance; // مساعده
  final double otherDeductions; // سایر کسورات (مابه‌تفاوت)
  final double absenceDays;
  final double absenceHours;

  SalaryCalculationInput({
    this.year,
    this.month,
    this.totalDays = 30,
    this.leaveDays = 0,
    this.sickLeaveDays = 0,
    this.overtimeHours = 0,
    this.nightWorkHours = 0,
    this.fridayWorkHours = 0,
    this.holidayWorkHours = 0,
    this.missionDays = 0,
    this.useCustomOvertimeBase = false,
    this.overtimeBaseDaily = 0,
    this.shiftWork = 0,
    this.hourlyBenefitsAmount = 0,
    this.hourlyBenefitHours = 0,
    this.autoShiftWork = false,
    this.autoHourlyBenefits = false,
    this.includeLeaveInPayslip = true,
    this.insuranceExempt = false,
    this.taxExempt = false,
    this.housingExempt = false,
    this.foodExempt = false,
    this.seniorityExempt = false,
    this.dailySeniorityOverride = -1,
    this.otherBenefitsOverride = -1, // -1 = خودکار (از کارمند)
    this.loanInstallment = 0,
    this.advance = 0,
    this.otherDeductions = 0,
    this.absenceDays = 0,
    this.absenceHours = 0,
  });

  double get normalizedLeaveDays =>
      leaveDays.clamp(0.0, totalDays.toDouble()).toDouble();

  double get normalizedSickLeaveDays =>
      sickLeaveDays.clamp(0.0, totalDays - normalizedLeaveDays).toDouble();

  double get workDays =>
      totalDays - normalizedLeaveDays - normalizedSickLeaveDays;

  double get payableDays => totalDays - normalizedSickLeaveDays;
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
    final payableDays = input.payableDays;
    final benefitDays = payableDays.clamp(
      0.0,
      AppConstants.standardMonthDays.toDouble(),
    );
    final workDays = input.workDays;

    // غرامت ایام بیماری را تامین اجتماعی جداگانه می‌پردازد؛ این فیش فقط
    // روزهایی را محاسبه می‌کند که پرداخت آن‌ها بر عهده کارفرماست.
    final baseSalary = employee.dailyWage1405 * payableDays;

    // 2) مزایای ثابت در اکسل با سقف 30 روز محاسبه می‌شوند.
    final housing = input.housingExempt
        ? 0.0
        : employee.dailyHousing * benefitDays;

    // 3) حق خواروبار = روزانه × min(کل کارکرد، 30)
    final food = input.foodExempt ? 0.0 : employee.dailyFood * benefitDays;

    // 4) حق تاهل = (در صورت متاهل بودن) روزانه × min(کل کارکرد، 30)
    final marriage = employee.isMarried
        ? employee.dailyMarriage * benefitDays
        : 0.0;

    // 5) حق فرزند = مبلغ روزانه هر فرزند × تعداد فرزند × min(کل کارکرد، 30)
    final childAllowance =
        employee.dailyChildAllowance * employee.childrenCount * benefitDays;

    // 6) پایه سنوات از تاریخ شروع کار و دوره فیش محاسبه می‌شود.
    final seniority = input.seniorityExempt
        ? 0.0
        : input.dailySeniorityOverride >= 0
        ? input.dailySeniorityOverride * payableDays
        : SeniorityHelper.calculateMonthlySeniority(
            startDate: employee.startDate,
            settings: settings,
            year: input.year ?? settings.year,
            month: input.month ?? 1,
            payableDays: payableDays,
          );

    // 7) سایر مزایا دستی = مبلغ روزانه × کارکرد خالص؛ خودکار مطابق قرارداد/اکسل.
    final otherBenefits = input.otherBenefitsOverride >= 0
        ? input.otherBenefitsOverride * workDays
        : employee.otherBenefitsDaily * payableDays;

    // 8) اضافه‌کاری و مزایای ساعتی = ساعت × (دستمزد ساعتی × 1.40)
    final overtimeBaseDaily = input.useCustomOvertimeBase
        ? input.overtimeBaseDaily
        : employee.dailyWage1405;
    final overtimeHourlyRate = overtimeBaseDaily / AppConstants.dailyWorkHours;
    final overtimeRate = overtimeHourlyRate * AppConstants.overtimeMultiplier;
    final overtimeAmount = input.overtimeHours * overtimeRate;
    final regularHourlyRate =
        employee.dailyWage1405 / AppConstants.dailyWorkHours;
    final nightWorkAmount =
        input.nightWorkHours * regularHourlyRate * settings.nightWorkRate;
    final fridayWorkAmount =
        input.fridayWorkHours * regularHourlyRate * settings.fridayWorkRate;
    final holidayWorkAmount =
        input.holidayWorkHours *
        regularHourlyRate *
        settings.holidayWorkMultiplier;
    final missionAmount =
        input.missionDays *
        employee.dailyWage1405 *
        settings.missionDailyMultiplier;
    final hourlyBenefitHours = input.autoHourlyBenefits
        ? (input.hourlyBenefitHours > 0
              ? input.hourlyBenefitHours
              : employee.hourlyBenefits)
        : 0.0;
    final hourlyBenefitsRate =
        (employee.dailyWage1405 / AppConstants.dailyWorkHours) *
        AppConstants.overtimeMultiplier;
    final hourlyBenefitsAmount = input.autoHourlyBenefits
        ? hourlyBenefitHours * hourlyBenefitsRate
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
        nightWorkAmount +
        fridayWorkAmount +
        holidayWorkAmount +
        missionAmount +
        hourlyBenefitsAmount;

    // 11) مبنای بیمه مطابق اکسل:
    // min(جمع حقوق و مزایا - حق فرزند، حداقل دستمزد روزانه × 7 × کل کارکرد)
    final uncappedInsuranceBase = (totalEarnings - childAllowance).clamp(
      0.0,
      double.infinity,
    );
    final insuranceCap =
        settings.dailyWage * AppConstants.insuranceCapMultiplier * payableDays;
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

    final leaveAllowanceDays = settings.monthlyLeaveAllowance;
    final excessLeaveDays = input.includeLeaveInPayslip
        ? (input.leaveDays - leaveAllowanceDays)
              .clamp(0.0, double.infinity)
              .toDouble()
        : 0.0;
    final leaveDeduction = excessLeaveDays * employee.dailyWage1405;
    final absenceDeduction =
        input.absenceDays * employee.dailyWage1405 +
        input.absenceHours *
            regularHourlyRate *
            settings.absenceHourlyMultiplier;

    // 14) جمع کسورات
    final totalDeductions =
        insurance +
        tax +
        input.loanInstallment +
        input.advance +
        input.otherDeductions +
        absenceDeduction +
        leaveDeduction;

    // 15) خالص حقوق
    final netSalary = totalEarnings - totalDeductions;

    // 16) رند نهایی اکسل: ROUND(خالص، -3)
    final roundedFinal = netSalary <= 0 ? 0 : (netSalary / 1000).round() * 1000;
    final rounding = (roundedFinal - netSalary).round();

    // 17) سهم کارفرما
    final employerInsurance = insuranceBase * settings.employerInsuranceRate;
    final unemploymentInsurance =
        insuranceBase * settings.unemploymentInsuranceRate;
    final calculationDetailsJson = jsonEncode({
      'formula_version': 'salary-1405-v2',
      'law_year': settings.year,
      'rates': {
        'overtime_multiplier': AppConstants.overtimeMultiplier,
        'night_work_rate': settings.nightWorkRate,
        'friday_work_rate': settings.fridayWorkRate,
        'holiday_work_multiplier': settings.holidayWorkMultiplier,
        'mission_daily_multiplier': settings.missionDailyMultiplier,
        'absence_hourly_multiplier': settings.absenceHourlyMultiplier,
      },
    });

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
      nightWorkAmount: nightWorkAmount,
      fridayWorkAmount: fridayWorkAmount,
      holidayWorkAmount: holidayWorkAmount,
      missionAmount: missionAmount,
      useCustomOvertimeBase: input.useCustomOvertimeBase,
      overtimeBaseDaily: overtimeBaseDaily,
      hourlyBenefitsAmount: hourlyBenefitsAmount,
      hourlyBenefitHours: hourlyBenefitHours,
      totalEarnings: totalEarnings,
      payableDays: payableDays,
      insurance: insurance,
      tax: tax,
      loanInstallment: input.loanInstallment,
      advance: input.advance,
      otherDeductions: input.otherDeductions,
      leaveAllowanceDays: leaveAllowanceDays,
      excessLeaveDays: excessLeaveDays,
      leaveDeduction: leaveDeduction,
      absenceDeduction: absenceDeduction,
      totalDeductions: totalDeductions,
      insuranceBase: insuranceBase,
      taxBase: taxBase,
      twoSevenExemption: twoSevenExemption,
      employerInsurance: employerInsurance,
      unemploymentInsurance: unemploymentInsurance,
      netSalary: netSalary,
      rounding: rounding,
      finalPayment: roundedFinal.toDouble(),
      payrollCalculationDetailsJson: calculationDetailsJson,
    );
  }
}
