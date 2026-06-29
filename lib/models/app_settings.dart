import '../utils/constants.dart';

/// تنظیمات کلی برنامه - مقادیر پایه حقوق
class AppSettings {
  final int? id;
  final int year; // سال محاسبات
  final double dailyWage; // دستمزد روزانه مصوب
  final double monthlyFood; // بن (ماهانه)
  final double monthlyHousing; // حق مسکن (ماهانه)
  final double monthlyMarriage; // حق تاهل (ماهانه)
  final double monthlyChild; // حق فرزند (ماهانه)
  final double dailySeniority; // پایه سنوات (روزانه)
  final double salaryRateA; // درصد سایر سطوح (روزانه) - 1.45
  final double salaryRateB; // درصد سایر سطوح (ریالی) - 1.50
  final double fixedRial; // ثابت ریالی

  final double employeeInsuranceRate; // درصد بیمه کارمند
  final double employerInsuranceRate; // درصد بیمه کارفرما
  final double unemploymentInsuranceRate; // درصد بیمه بیکاری

  final double twoSevenBaseRate; // ضریب معافیت دو هفتم
  final double monthlyLeaveAllowance;
  final double annualLeaveAllowance;
  final double nightWorkRate;
  final double fridayWorkRate;
  final double holidayWorkMultiplier;
  final double missionDailyMultiplier;
  final double absenceHourlyMultiplier;
  final String companyName; // نام شرکت

  AppSettings({
    this.id,
    this.year = AppConstants.currentYear,
    this.dailyWage = AppConstants.defaultDailyWage,
    this.monthlyFood = AppConstants.defaultMonthlyFood,
    this.monthlyHousing = AppConstants.defaultMonthlyHousing,
    this.monthlyMarriage = AppConstants.defaultMonthlyMarriage,
    this.monthlyChild = AppConstants.defaultMonthlyChild,
    this.dailySeniority = AppConstants.defaultDailySeniority,
    this.salaryRateA = AppConstants.salaryRateA,
    this.salaryRateB = AppConstants.salaryRateB,
    this.fixedRial = AppConstants.fixedRial,
    this.employeeInsuranceRate = AppConstants.employeeInsuranceRate,
    this.employerInsuranceRate = AppConstants.employerInsuranceRate,
    this.unemploymentInsuranceRate = AppConstants.unemploymentInsuranceRate,
    this.twoSevenBaseRate = AppConstants.twoSevenBaseRate,
    this.monthlyLeaveAllowance = AppConstants.defaultMonthlyLeaveAllowance,
    this.annualLeaveAllowance = AppConstants.defaultAnnualLeaveAllowance,
    this.nightWorkRate = AppConstants.nightShiftMultiplier,
    this.fridayWorkRate = AppConstants.fridayWorkRate,
    this.holidayWorkMultiplier = AppConstants.holidayWorkMultiplier,
    this.missionDailyMultiplier = AppConstants.missionDailyMultiplier,
    this.absenceHourlyMultiplier = AppConstants.absenceHourlyMultiplier,
    this.companyName = 'شرکت اصلی',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'year': year,
    'daily_wage': dailyWage,
    'monthly_food': monthlyFood,
    'monthly_housing': monthlyHousing,
    'monthly_marriage': monthlyMarriage,
    'monthly_child': monthlyChild,
    'daily_seniority': dailySeniority,
    'salary_rate_a': salaryRateA,
    'salary_rate_b': salaryRateB,
    'fixed_rial': fixedRial,
    'employee_insurance_rate': employeeInsuranceRate,
    'employer_insurance_rate': employerInsuranceRate,
    'unemployment_insurance_rate': unemploymentInsuranceRate,
    'two_seven_base_rate': twoSevenBaseRate,
    'monthly_leave_allowance': monthlyLeaveAllowance,
    'annual_leave_allowance': annualLeaveAllowance,
    'night_work_rate': nightWorkRate,
    'friday_work_rate': fridayWorkRate,
    'holiday_work_multiplier': holidayWorkMultiplier,
    'mission_daily_multiplier': missionDailyMultiplier,
    'absence_hourly_multiplier': absenceHourlyMultiplier,
    'company_name': companyName,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    id: map['id'] as int?,
    year: map['year'] as int? ?? AppConstants.currentYear,
    dailyWage:
        (map['daily_wage'] as num?)?.toDouble() ??
        AppConstants.defaultDailyWage,
    monthlyFood:
        (map['monthly_food'] as num?)?.toDouble() ??
        AppConstants.defaultMonthlyFood,
    monthlyHousing:
        (map['monthly_housing'] as num?)?.toDouble() ??
        AppConstants.defaultMonthlyHousing,
    monthlyMarriage:
        (map['monthly_marriage'] as num?)?.toDouble() ??
        AppConstants.defaultMonthlyMarriage,
    monthlyChild:
        (map['monthly_child'] as num?)?.toDouble() ??
        AppConstants.defaultMonthlyChild,
    dailySeniority:
        (map['daily_seniority'] as num?)?.toDouble() ??
        AppConstants.defaultDailySeniority,
    salaryRateA:
        (map['salary_rate_a'] as num?)?.toDouble() ?? AppConstants.salaryRateA,
    salaryRateB:
        (map['salary_rate_b'] as num?)?.toDouble() ?? AppConstants.salaryRateB,
    fixedRial:
        (map['fixed_rial'] as num?)?.toDouble() ?? AppConstants.fixedRial,
    employeeInsuranceRate:
        (map['employee_insurance_rate'] as num?)?.toDouble() ??
        AppConstants.employeeInsuranceRate,
    employerInsuranceRate:
        (map['employer_insurance_rate'] as num?)?.toDouble() ??
        AppConstants.employerInsuranceRate,
    unemploymentInsuranceRate:
        (map['unemployment_insurance_rate'] as num?)?.toDouble() ??
        AppConstants.unemploymentInsuranceRate,
    twoSevenBaseRate:
        (map['two_seven_base_rate'] as num?)?.toDouble() ??
        AppConstants.twoSevenBaseRate,
    monthlyLeaveAllowance:
        (map['monthly_leave_allowance'] as num?)?.toDouble() ??
        AppConstants.defaultMonthlyLeaveAllowance,
    annualLeaveAllowance:
        (map['annual_leave_allowance'] as num?)?.toDouble() ??
        AppConstants.defaultAnnualLeaveAllowance,
    nightWorkRate:
        (map['night_work_rate'] as num?)?.toDouble() ??
        AppConstants.nightShiftMultiplier,
    fridayWorkRate:
        (map['friday_work_rate'] as num?)?.toDouble() ??
        AppConstants.fridayWorkRate,
    holidayWorkMultiplier:
        (map['holiday_work_multiplier'] as num?)?.toDouble() ??
        AppConstants.holidayWorkMultiplier,
    missionDailyMultiplier:
        (map['mission_daily_multiplier'] as num?)?.toDouble() ??
        AppConstants.missionDailyMultiplier,
    absenceHourlyMultiplier:
        (map['absence_hourly_multiplier'] as num?)?.toDouble() ??
        AppConstants.absenceHourlyMultiplier,
    companyName: map['company_name'] as String? ?? 'شرکت اصلی',
  );

  AppSettings copyWith({
    int? year,
    double? dailyWage,
    double? monthlyFood,
    double? monthlyHousing,
    double? monthlyMarriage,
    double? monthlyChild,
    double? dailySeniority,
    double? salaryRateA,
    double? salaryRateB,
    double? fixedRial,
    double? employeeInsuranceRate,
    double? employerInsuranceRate,
    double? unemploymentInsuranceRate,
    double? twoSevenBaseRate,
    double? monthlyLeaveAllowance,
    double? annualLeaveAllowance,
    double? nightWorkRate,
    double? fridayWorkRate,
    double? holidayWorkMultiplier,
    double? missionDailyMultiplier,
    double? absenceHourlyMultiplier,
    String? companyName,
  }) => AppSettings(
    id: id,
    year: year ?? this.year,
    dailyWage: dailyWage ?? this.dailyWage,
    monthlyFood: monthlyFood ?? this.monthlyFood,
    monthlyHousing: monthlyHousing ?? this.monthlyHousing,
    monthlyMarriage: monthlyMarriage ?? this.monthlyMarriage,
    monthlyChild: monthlyChild ?? this.monthlyChild,
    dailySeniority: dailySeniority ?? this.dailySeniority,
    salaryRateA: salaryRateA ?? this.salaryRateA,
    salaryRateB: salaryRateB ?? this.salaryRateB,
    fixedRial: fixedRial ?? this.fixedRial,
    employeeInsuranceRate: employeeInsuranceRate ?? this.employeeInsuranceRate,
    employerInsuranceRate: employerInsuranceRate ?? this.employerInsuranceRate,
    unemploymentInsuranceRate:
        unemploymentInsuranceRate ?? this.unemploymentInsuranceRate,
    twoSevenBaseRate: twoSevenBaseRate ?? this.twoSevenBaseRate,
    monthlyLeaveAllowance: monthlyLeaveAllowance ?? this.monthlyLeaveAllowance,
    annualLeaveAllowance: annualLeaveAllowance ?? this.annualLeaveAllowance,
    nightWorkRate: nightWorkRate ?? this.nightWorkRate,
    fridayWorkRate: fridayWorkRate ?? this.fridayWorkRate,
    holidayWorkMultiplier: holidayWorkMultiplier ?? this.holidayWorkMultiplier,
    missionDailyMultiplier:
        missionDailyMultiplier ?? this.missionDailyMultiplier,
    absenceHourlyMultiplier:
        absenceHourlyMultiplier ?? this.absenceHourlyMultiplier,
    companyName: companyName ?? this.companyName,
  );
}
