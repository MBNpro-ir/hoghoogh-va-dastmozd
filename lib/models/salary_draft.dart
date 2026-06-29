class SalaryDraft {
  final int? id;
  final int employeeId;
  final int year;
  final int month;
  final int totalDays;
  final double leaveDays;
  final double sickLeaveDays;
  final double overtimeHours;
  final double nightWorkHours;
  final double nightWorkAmount;
  final double fridayWorkHours;
  final double fridayWorkAmount;
  final double holidayWorkHours;
  final double holidayWorkAmount;
  final double missionDays;
  final double missionAmount;
  final bool useCustomOvertimeBase;
  final double overtimeBaseDaily;
  final double shiftWork;
  final bool autoShiftWork;
  final double hourlyBenefitsAmount;
  final double hourlyBenefitHours;
  final bool autoHourlyBenefits;
  final double otherBenefitsOverride;
  final bool autoOtherBenefits;
  final double dailySeniorityOverride;
  final bool autoSeniority;
  final double loanInstallment;
  final bool autoLoanInstallment;
  final bool skipLoanInstallment;
  final double advance;
  final bool autoAdvances;
  final double otherDeductions;
  final double absenceDays;
  final double absenceHours;
  final double absenceDeduction;
  final bool includeLeaveInPayslip;
  final bool insuranceExempt;
  final bool taxExempt;
  final bool housingExempt;
  final bool foodExempt;
  final bool seniorityExempt;
  final String payrollCalculationDetailsJson;

  const SalaryDraft({
    this.id,
    required this.employeeId,
    required this.year,
    required this.month,
    required this.totalDays,
    this.leaveDays = 0,
    this.sickLeaveDays = 0,
    this.overtimeHours = 0,
    this.nightWorkHours = 0,
    this.nightWorkAmount = 0,
    this.fridayWorkHours = 0,
    this.fridayWorkAmount = 0,
    this.holidayWorkHours = 0,
    this.holidayWorkAmount = 0,
    this.missionDays = 0,
    this.missionAmount = 0,
    this.useCustomOvertimeBase = false,
    this.overtimeBaseDaily = 0,
    this.shiftWork = 0,
    this.autoShiftWork = false,
    this.hourlyBenefitsAmount = 0,
    this.hourlyBenefitHours = 0,
    this.autoHourlyBenefits = true,
    this.otherBenefitsOverride = -1,
    this.autoOtherBenefits = true,
    this.dailySeniorityOverride = -1,
    this.autoSeniority = true,
    this.loanInstallment = 0,
    this.autoLoanInstallment = true,
    this.skipLoanInstallment = false,
    this.advance = 0,
    this.autoAdvances = true,
    this.otherDeductions = 0,
    this.absenceDays = 0,
    this.absenceHours = 0,
    this.absenceDeduction = 0,
    this.includeLeaveInPayslip = true,
    this.insuranceExempt = false,
    this.taxExempt = false,
    this.housingExempt = false,
    this.foodExempt = false,
    this.seniorityExempt = false,
    this.payrollCalculationDetailsJson = '{}',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'year': year,
    'month': month,
    'total_days': totalDays,
    'leave_days': leaveDays,
    'sick_leave_days': sickLeaveDays,
    'overtime_hours': overtimeHours,
    'night_work_hours': nightWorkHours,
    'night_work_amount': nightWorkAmount,
    'friday_work_hours': fridayWorkHours,
    'friday_work_amount': fridayWorkAmount,
    'holiday_work_hours': holidayWorkHours,
    'holiday_work_amount': holidayWorkAmount,
    'mission_days': missionDays,
    'mission_amount': missionAmount,
    'use_custom_overtime_base': useCustomOvertimeBase ? 1 : 0,
    'overtime_base_daily': overtimeBaseDaily,
    'shift_work': shiftWork,
    'auto_shift_work': autoShiftWork ? 1 : 0,
    'hourly_benefits_amount': hourlyBenefitsAmount,
    'hourly_benefit_hours': hourlyBenefitHours,
    'auto_hourly_benefits': autoHourlyBenefits ? 1 : 0,
    'other_benefits_override': otherBenefitsOverride,
    'auto_other_benefits': autoOtherBenefits ? 1 : 0,
    'daily_seniority_override': dailySeniorityOverride,
    'auto_seniority': autoSeniority ? 1 : 0,
    'loan_installment': loanInstallment,
    'auto_loan_installment': autoLoanInstallment ? 1 : 0,
    'skip_loan_installment': skipLoanInstallment ? 1 : 0,
    'advance': advance,
    'auto_advances': autoAdvances ? 1 : 0,
    'other_deductions': otherDeductions,
    'absence_days': absenceDays,
    'absence_hours': absenceHours,
    'absence_deduction': absenceDeduction,
    'include_leave_in_payslip': includeLeaveInPayslip ? 1 : 0,
    'insurance_exempt': insuranceExempt ? 1 : 0,
    'tax_exempt': taxExempt ? 1 : 0,
    'housing_exempt': housingExempt ? 1 : 0,
    'food_exempt': foodExempt ? 1 : 0,
    'seniority_exempt': seniorityExempt ? 1 : 0,
    'payroll_calculation_details_json': payrollCalculationDetailsJson,
  };

  factory SalaryDraft.fromMap(Map<String, dynamic> map) => SalaryDraft(
    id: map['id'] as int?,
    employeeId: (map['employee_id'] as num).toInt(),
    year: (map['year'] as num).toInt(),
    month: (map['month'] as num).toInt(),
    totalDays: (map['total_days'] as num).toInt(),
    leaveDays: (map['leave_days'] as num?)?.toDouble() ?? 0,
    sickLeaveDays: (map['sick_leave_days'] as num?)?.toDouble() ?? 0,
    overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0,
    nightWorkHours: (map['night_work_hours'] as num?)?.toDouble() ?? 0,
    nightWorkAmount: (map['night_work_amount'] as num?)?.toDouble() ?? 0,
    fridayWorkHours: (map['friday_work_hours'] as num?)?.toDouble() ?? 0,
    fridayWorkAmount: (map['friday_work_amount'] as num?)?.toDouble() ?? 0,
    holidayWorkHours: (map['holiday_work_hours'] as num?)?.toDouble() ?? 0,
    holidayWorkAmount: (map['holiday_work_amount'] as num?)?.toDouble() ?? 0,
    missionDays: (map['mission_days'] as num?)?.toDouble() ?? 0,
    missionAmount: (map['mission_amount'] as num?)?.toDouble() ?? 0,
    useCustomOvertimeBase: (map['use_custom_overtime_base'] as int? ?? 0) == 1,
    overtimeBaseDaily: (map['overtime_base_daily'] as num?)?.toDouble() ?? 0,
    shiftWork: (map['shift_work'] as num?)?.toDouble() ?? 0,
    autoShiftWork: (map['auto_shift_work'] as int? ?? 0) == 1,
    hourlyBenefitsAmount:
        (map['hourly_benefits_amount'] as num?)?.toDouble() ?? 0,
    hourlyBenefitHours: (map['hourly_benefit_hours'] as num?)?.toDouble() ?? 0,
    autoHourlyBenefits: (map['auto_hourly_benefits'] as int? ?? 1) == 1,
    otherBenefitsOverride:
        (map['other_benefits_override'] as num?)?.toDouble() ?? -1,
    autoOtherBenefits: (map['auto_other_benefits'] as int? ?? 1) == 1,
    dailySeniorityOverride:
        (map['daily_seniority_override'] as num?)?.toDouble() ?? -1,
    autoSeniority: (map['auto_seniority'] as int? ?? 1) == 1,
    loanInstallment: (map['loan_installment'] as num?)?.toDouble() ?? 0,
    autoLoanInstallment: (map['auto_loan_installment'] as int? ?? 1) == 1,
    skipLoanInstallment: (map['skip_loan_installment'] as int? ?? 0) == 1,
    advance: (map['advance'] as num?)?.toDouble() ?? 0,
    autoAdvances: (map['auto_advances'] as int? ?? 1) == 1,
    otherDeductions: (map['other_deductions'] as num?)?.toDouble() ?? 0,
    absenceDays: (map['absence_days'] as num?)?.toDouble() ?? 0,
    absenceHours: (map['absence_hours'] as num?)?.toDouble() ?? 0,
    absenceDeduction: (map['absence_deduction'] as num?)?.toDouble() ?? 0,
    includeLeaveInPayslip: (map['include_leave_in_payslip'] as int? ?? 1) == 1,
    insuranceExempt: (map['insurance_exempt'] as int? ?? 0) == 1,
    taxExempt: (map['tax_exempt'] as int? ?? 0) == 1,
    housingExempt: (map['housing_exempt'] as int? ?? 0) == 1,
    foodExempt: (map['food_exempt'] as int? ?? 0) == 1,
    seniorityExempt: (map['seniority_exempt'] as int? ?? 0) == 1,
    payrollCalculationDetailsJson:
        map['payroll_calculation_details_json']?.toString() ?? '{}',
  );

  SalaryDraft copyForPeriod({required int year, required int month}) {
    return SalaryDraft(
      employeeId: employeeId,
      year: year,
      month: month,
      totalDays: totalDays,
      leaveDays: leaveDays,
      sickLeaveDays: sickLeaveDays,
      overtimeHours: overtimeHours,
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
      autoShiftWork: autoShiftWork,
      hourlyBenefitsAmount: hourlyBenefitsAmount,
      hourlyBenefitHours: hourlyBenefitHours,
      autoHourlyBenefits: autoHourlyBenefits,
      otherBenefitsOverride: otherBenefitsOverride,
      autoOtherBenefits: autoOtherBenefits,
      dailySeniorityOverride: dailySeniorityOverride,
      autoSeniority: autoSeniority,
      loanInstallment: loanInstallment,
      autoLoanInstallment: autoLoanInstallment,
      skipLoanInstallment: skipLoanInstallment,
      advance: advance,
      autoAdvances: autoAdvances,
      otherDeductions: otherDeductions,
      absenceDays: absenceDays,
      absenceHours: absenceHours,
      absenceDeduction: absenceDeduction,
      includeLeaveInPayslip: includeLeaveInPayslip,
      insuranceExempt: insuranceExempt,
      taxExempt: taxExempt,
      housingExempt: housingExempt,
      foodExempt: foodExempt,
      seniorityExempt: seniorityExempt,
      payrollCalculationDetailsJson: payrollCalculationDetailsJson,
    );
  }
}
