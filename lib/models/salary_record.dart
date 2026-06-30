import 'dart:convert';

import '../utils/constants.dart';

/// مدل فیش حقوق ماهانه
class SalaryRecord {
  final int? id;
  final int employeeId;
  final String? employeeFullNameSnapshot;
  final int? employeePersonnelCodeSnapshot;
  final String? employeeNationalIdSnapshot;
  final String? employeePayslipFooterNoteSnapshot;
  final int year; // سال شمسی
  final int month; // ماه شمسی (1 تا 12)

  // ورودی‌های زمانی
  final int totalDays; // کل کارکرد (روز)
  final double leaveDays; // مرخصی
  final double sickLeaveDays; // مرخصی استعلاجی
  final double workDays; // کارکرد خالص

  // ساعات و مزایا
  final double overtimeHours; // ساعت اضافه‌کاری
  final double overtimeAmount; // مبلغ اضافه‌کاری
  final double nightWorkHours;
  final double nightWorkAmount;
  final double fridayWorkHours;
  final double fridayWorkAmount;
  final double holidayWorkHours;
  final double holidayWorkAmount;
  final double missionDays;
  final double missionAmount;
  final bool usePartTimeWage;
  final double partTimeWorkHours;
  final bool useCustomOvertimeBase;
  final double overtimeBaseDaily;
  final double shiftWork; // نوبت‌کاری
  final double shiftWorkRate;
  final double hourlyBenefitsAmount; // مزایای 60-64-160 ساعته
  final double hourlyBenefitHours; // ساعت مزایای ساعتی

  // اجزای حقوق و مزایا
  final double baseSalary; // حقوق ثابت
  final double housing; // حق مسکن
  final double food; // حق خواروبار
  final double marriage; // حق تاهل
  final double childAllowance; // حق فرزند
  final double seniority; // پایه سنوات
  final double otherBenefits; // سایر مزایا
  final double jobRelatedBenefits;
  final double employeeRelatedBenefits;
  final double welfareBenefits;
  final double totalEarnings; // جمع حقوق و مزایا

  // کسورات
  final double insurance; // حق بیمه 7%
  final double tax; // مالیات
  final double loanInstallment; // قسط وام
  final double advance; // مساعده
  final double supplementaryInsurance;
  final double otherDeductions; // سایر کسورات (مابه‌تفاوت)
  final double absenceDays;
  final double absenceHours;
  final double absenceDeduction;
  final bool includeLeaveInPayslip; // محاسبه محدودیت مرخصی در فیش
  final bool housingExempt; // معافیت حق مسکن برای این فیش
  final bool foodExempt; // معافیت حق خواروبار برای این فیش
  final bool seniorityExempt; // معافیت پایه سنوات برای این فیش
  final double leaveAllowanceDays; // سقف مرخصی مجاز ماهانه
  final double excessLeaveDays; // مرخصی مازاد
  final double leaveDeduction; // کسر مرخصی مازاد
  final double totalDeductions; // جمع کسورات

  // محاسبات نهایی
  final double insuranceBase; // حقوق مشمول بیمه
  final double taxBase; // مبنای مالیات
  final double twoSevenExemption; // کسر حق بیمه سهم کارگر از مالیات
  final double taxReliefRate;
  final double taxReliefAmount;
  final double netSalary; // خالص حقوق
  final int rounding; // رند حقوق
  final double finalPayment; // خالص دریافتی نهایی
  final String payrollCalculationDetailsJson;

  final String? notes;
  final DateTime createdAt;

  double get payableDays {
    final fromDetails = _numberFromDetails([
      'payable_days',
      'part_time_equivalent_days',
    ]);
    if (fromDetails != null) {
      return fromDetails.clamp(0.0, totalDays.toDouble()).toDouble();
    }
    if (usePartTimeWage && partTimeWorkHours > 0) {
      final mandatoryHours = AppConstants.mandatoryMonthlyHoursFor(
        year: year,
        month: month,
        totalDays: totalDays,
      );
      if (mandatoryHours > 0) {
        return ((partTimeWorkHours.clamp(0.0, mandatoryHours) /
                    mandatoryHours) *
                totalDays)
            .clamp(0.0, (totalDays - sickLeaveDays).toDouble())
            .toDouble();
      }
    }
    return (totalDays - sickLeaveDays)
        .clamp(0.0, totalDays.toDouble())
        .toDouble();
  }

  double? _numberFromDetails(List<String> keys) {
    try {
      final decoded = jsonDecode(payrollCalculationDetailsJson);
      if (decoded is! Map<String, dynamic>) return null;
      for (final key in keys) {
        final direct = decoded[key];
        if (direct is num) return direct.toDouble();
        final rates = decoded['rates'];
        if (rates is Map<String, dynamic>) {
          final value = rates[key];
          if (value is num) return value.toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  SalaryRecord({
    this.id,
    required this.employeeId,
    this.employeeFullNameSnapshot,
    this.employeePersonnelCodeSnapshot,
    this.employeeNationalIdSnapshot,
    this.employeePayslipFooterNoteSnapshot,
    required this.year,
    required this.month,
    required this.totalDays,
    required this.leaveDays,
    this.sickLeaveDays = 0,
    required this.workDays,
    this.overtimeHours = 0,
    this.overtimeAmount = 0,
    this.nightWorkHours = 0,
    this.nightWorkAmount = 0,
    this.fridayWorkHours = 0,
    this.fridayWorkAmount = 0,
    this.holidayWorkHours = 0,
    this.holidayWorkAmount = 0,
    this.missionDays = 0,
    this.missionAmount = 0,
    this.usePartTimeWage = false,
    this.partTimeWorkHours = 0,
    this.useCustomOvertimeBase = false,
    this.overtimeBaseDaily = 0,
    this.shiftWork = 0,
    this.shiftWorkRate = 0,
    this.hourlyBenefitsAmount = 0,
    this.hourlyBenefitHours = 0,
    required this.baseSalary,
    required this.housing,
    required this.food,
    required this.marriage,
    required this.childAllowance,
    required this.seniority,
    this.otherBenefits = 0,
    this.jobRelatedBenefits = 0,
    this.employeeRelatedBenefits = 0,
    this.welfareBenefits = 0,
    required this.totalEarnings,
    required this.insurance,
    required this.tax,
    this.loanInstallment = 0,
    this.advance = 0,
    this.supplementaryInsurance = 0,
    this.otherDeductions = 0,
    this.absenceDays = 0,
    this.absenceHours = 0,
    this.absenceDeduction = 0,
    this.includeLeaveInPayslip = true,
    this.housingExempt = false,
    this.foodExempt = false,
    this.seniorityExempt = false,
    this.leaveAllowanceDays = 2.5,
    this.excessLeaveDays = 0,
    this.leaveDeduction = 0,
    required this.totalDeductions,
    required this.insuranceBase,
    required this.taxBase,
    this.twoSevenExemption = 0,
    this.taxReliefRate = 0,
    this.taxReliefAmount = 0,
    required this.netSalary,
    this.rounding = 0,
    required this.finalPayment,
    this.payrollCalculationDetailsJson = '{}',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'employee_full_name_snapshot': employeeFullNameSnapshot,
    'employee_personnel_code_snapshot': employeePersonnelCodeSnapshot,
    'employee_national_id_snapshot': employeeNationalIdSnapshot,
    'employee_payslip_footer_note_snapshot': employeePayslipFooterNoteSnapshot,
    'year': year,
    'month': month,
    'total_days': totalDays,
    'leave_days': leaveDays,
    'sick_leave_days': sickLeaveDays,
    'work_days': workDays,
    'overtime_hours': overtimeHours,
    'overtime_amount': overtimeAmount,
    'night_work_hours': nightWorkHours,
    'night_work_amount': nightWorkAmount,
    'friday_work_hours': fridayWorkHours,
    'friday_work_amount': fridayWorkAmount,
    'holiday_work_hours': holidayWorkHours,
    'holiday_work_amount': holidayWorkAmount,
    'mission_days': missionDays,
    'mission_amount': missionAmount,
    'use_part_time_wage': usePartTimeWage ? 1 : 0,
    'part_time_work_hours': partTimeWorkHours,
    'use_custom_overtime_base': useCustomOvertimeBase ? 1 : 0,
    'overtime_base_daily': overtimeBaseDaily,
    'shift_work': shiftWork,
    'shift_work_rate': shiftWorkRate,
    'hourly_benefits_amount': hourlyBenefitsAmount,
    'hourly_benefit_hours': hourlyBenefitHours,
    'base_salary': baseSalary,
    'housing': housing,
    'food': food,
    'marriage': marriage,
    'child_allowance': childAllowance,
    'seniority': seniority,
    'other_benefits': otherBenefits,
    'job_related_benefits': jobRelatedBenefits,
    'employee_related_benefits': employeeRelatedBenefits,
    'welfare_benefits': welfareBenefits,
    'total_earnings': totalEarnings,
    'insurance': insurance,
    'tax': tax,
    'loan_installment': loanInstallment,
    'advance': advance,
    'supplementary_insurance': supplementaryInsurance,
    'other_deductions': otherDeductions,
    'absence_days': absenceDays,
    'absence_hours': absenceHours,
    'absence_deduction': absenceDeduction,
    'include_leave_in_payslip': includeLeaveInPayslip ? 1 : 0,
    'housing_exempt': housingExempt ? 1 : 0,
    'food_exempt': foodExempt ? 1 : 0,
    'seniority_exempt': seniorityExempt ? 1 : 0,
    'leave_allowance_days': leaveAllowanceDays,
    'excess_leave_days': excessLeaveDays,
    'leave_deduction': leaveDeduction,
    'total_deductions': totalDeductions,
    'insurance_base': insuranceBase,
    'tax_base': taxBase,
    'two_seven_exemption': twoSevenExemption,
    'tax_relief_rate': taxReliefRate,
    'tax_relief_amount': taxReliefAmount,
    'net_salary': netSalary,
    'rounding': rounding,
    'final_payment': finalPayment,
    'payroll_calculation_details_json': payrollCalculationDetailsJson,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory SalaryRecord.fromMap(Map<String, dynamic> map) => SalaryRecord(
    id: map['id'] as int?,
    employeeId: map['employee_id'] as int,
    employeeFullNameSnapshot: map['employee_full_name_snapshot'] as String?,
    employeePersonnelCodeSnapshot:
        (map['employee_personnel_code_snapshot'] as num?)?.toInt(),
    employeeNationalIdSnapshot: map['employee_national_id_snapshot'] as String?,
    employeePayslipFooterNoteSnapshot:
        map['employee_payslip_footer_note_snapshot'] as String?,
    year: map['year'] as int,
    month: map['month'] as int,
    totalDays: map['total_days'] as int,
    leaveDays: (map['leave_days'] as num).toDouble(),
    sickLeaveDays: (map['sick_leave_days'] as num?)?.toDouble() ?? 0,
    workDays: (map['work_days'] as num).toDouble(),
    overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0,
    overtimeAmount: (map['overtime_amount'] as num?)?.toDouble() ?? 0,
    nightWorkHours: (map['night_work_hours'] as num?)?.toDouble() ?? 0,
    nightWorkAmount: (map['night_work_amount'] as num?)?.toDouble() ?? 0,
    fridayWorkHours: (map['friday_work_hours'] as num?)?.toDouble() ?? 0,
    fridayWorkAmount: (map['friday_work_amount'] as num?)?.toDouble() ?? 0,
    holidayWorkHours: (map['holiday_work_hours'] as num?)?.toDouble() ?? 0,
    holidayWorkAmount: (map['holiday_work_amount'] as num?)?.toDouble() ?? 0,
    missionDays: (map['mission_days'] as num?)?.toDouble() ?? 0,
    missionAmount: (map['mission_amount'] as num?)?.toDouble() ?? 0,
    usePartTimeWage: (map['use_part_time_wage'] as int? ?? 0) == 1,
    partTimeWorkHours: (map['part_time_work_hours'] as num?)?.toDouble() ?? 0,
    useCustomOvertimeBase: (map['use_custom_overtime_base'] as int? ?? 0) == 1,
    overtimeBaseDaily: (map['overtime_base_daily'] as num?)?.toDouble() ?? 0,
    shiftWork: (map['shift_work'] as num?)?.toDouble() ?? 0,
    shiftWorkRate: (map['shift_work_rate'] as num?)?.toDouble() ?? 0,
    hourlyBenefitsAmount:
        (map['hourly_benefits_amount'] as num?)?.toDouble() ?? 0,
    hourlyBenefitHours: (map['hourly_benefit_hours'] as num?)?.toDouble() ?? 0,
    baseSalary: (map['base_salary'] as num).toDouble(),
    housing: (map['housing'] as num).toDouble(),
    food: (map['food'] as num).toDouble(),
    marriage: (map['marriage'] as num).toDouble(),
    childAllowance: (map['child_allowance'] as num).toDouble(),
    seniority: (map['seniority'] as num).toDouble(),
    otherBenefits: (map['other_benefits'] as num?)?.toDouble() ?? 0,
    jobRelatedBenefits: (map['job_related_benefits'] as num?)?.toDouble() ?? 0,
    employeeRelatedBenefits:
        (map['employee_related_benefits'] as num?)?.toDouble() ?? 0,
    welfareBenefits: (map['welfare_benefits'] as num?)?.toDouble() ?? 0,
    totalEarnings: (map['total_earnings'] as num).toDouble(),
    insurance: (map['insurance'] as num).toDouble(),
    tax: (map['tax'] as num).toDouble(),
    loanInstallment: (map['loan_installment'] as num?)?.toDouble() ?? 0,
    advance: (map['advance'] as num?)?.toDouble() ?? 0,
    supplementaryInsurance:
        (map['supplementary_insurance'] as num?)?.toDouble() ?? 0,
    otherDeductions: (map['other_deductions'] as num?)?.toDouble() ?? 0,
    absenceDays: (map['absence_days'] as num?)?.toDouble() ?? 0,
    absenceHours: (map['absence_hours'] as num?)?.toDouble() ?? 0,
    absenceDeduction: (map['absence_deduction'] as num?)?.toDouble() ?? 0,
    includeLeaveInPayslip: (map['include_leave_in_payslip'] as int? ?? 1) == 1,
    housingExempt: (map['housing_exempt'] as int? ?? 0) == 1,
    foodExempt: (map['food_exempt'] as int? ?? 0) == 1,
    seniorityExempt: (map['seniority_exempt'] as int? ?? 0) == 1,
    leaveAllowanceDays:
        (map['leave_allowance_days'] as num?)?.toDouble() ?? 2.5,
    excessLeaveDays: (map['excess_leave_days'] as num?)?.toDouble() ?? 0,
    leaveDeduction: (map['leave_deduction'] as num?)?.toDouble() ?? 0,
    totalDeductions: (map['total_deductions'] as num).toDouble(),
    insuranceBase: (map['insurance_base'] as num).toDouble(),
    taxBase: (map['tax_base'] as num).toDouble(),
    twoSevenExemption: (map['two_seven_exemption'] as num?)?.toDouble() ?? 0,
    taxReliefRate: (map['tax_relief_rate'] as num?)?.toDouble() ?? 0,
    taxReliefAmount: (map['tax_relief_amount'] as num?)?.toDouble() ?? 0,
    netSalary: (map['net_salary'] as num).toDouble(),
    rounding: map['rounding'] as int? ?? 0,
    finalPayment: (map['final_payment'] as num).toDouble(),
    payrollCalculationDetailsJson:
        map['payroll_calculation_details_json']?.toString() ?? '{}',
    notes: map['notes'] as String?,
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  SalaryRecord copyWithId(int newId) => SalaryRecord(
    id: newId,
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
    usePartTimeWage: usePartTimeWage,
    partTimeWorkHours: partTimeWorkHours,
    useCustomOvertimeBase: useCustomOvertimeBase,
    overtimeBaseDaily: overtimeBaseDaily,
    shiftWork: shiftWork,
    shiftWorkRate: shiftWorkRate,
    hourlyBenefitsAmount: hourlyBenefitsAmount,
    hourlyBenefitHours: hourlyBenefitHours,
    baseSalary: baseSalary,
    housing: housing,
    food: food,
    marriage: marriage,
    childAllowance: childAllowance,
    seniority: seniority,
    otherBenefits: otherBenefits,
    jobRelatedBenefits: jobRelatedBenefits,
    employeeRelatedBenefits: employeeRelatedBenefits,
    welfareBenefits: welfareBenefits,
    totalEarnings: totalEarnings,
    insurance: insurance,
    tax: tax,
    loanInstallment: loanInstallment,
    advance: advance,
    supplementaryInsurance: supplementaryInsurance,
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
    taxReliefRate: taxReliefRate,
    taxReliefAmount: taxReliefAmount,
    netSalary: netSalary,
    rounding: rounding,
    finalPayment: finalPayment,
    payrollCalculationDetailsJson: payrollCalculationDetailsJson,
    notes: notes,
    createdAt: createdAt,
  );

  SalaryRecord copyWith({
    int? id,
    String? employeeFullNameSnapshot,
    int? employeePersonnelCodeSnapshot,
    String? employeeNationalIdSnapshot,
    String? employeePayslipFooterNoteSnapshot,
    double? leaveDays,
    double? sickLeaveDays,
    double? workDays,
    double? hourlyBenefitHours,
    double? hourlyBenefitsAmount,
    bool? useCustomOvertimeBase,
    double? overtimeBaseDaily,
    double? shiftWorkRate,
    double? jobRelatedBenefits,
    double? employeeRelatedBenefits,
    double? welfareBenefits,
    double? supplementaryInsurance,
    double? taxReliefRate,
    double? taxReliefAmount,
    double? nightWorkHours,
    double? nightWorkAmount,
    double? fridayWorkHours,
    double? fridayWorkAmount,
    double? holidayWorkHours,
    double? holidayWorkAmount,
    double? missionDays,
    double? missionAmount,
    bool? usePartTimeWage,
    double? partTimeWorkHours,
    bool? includeLeaveInPayslip,
    bool? housingExempt,
    bool? foodExempt,
    bool? seniorityExempt,
    double? leaveAllowanceDays,
    double? excessLeaveDays,
    double? leaveDeduction,
    double? absenceDays,
    double? absenceHours,
    double? absenceDeduction,
    double? totalDeductions,
    double? netSalary,
    int? rounding,
    double? finalPayment,
    String? payrollCalculationDetailsJson,
  }) => SalaryRecord(
    id: id ?? this.id,
    employeeId: employeeId,
    employeeFullNameSnapshot:
        employeeFullNameSnapshot ?? this.employeeFullNameSnapshot,
    employeePersonnelCodeSnapshot:
        employeePersonnelCodeSnapshot ?? this.employeePersonnelCodeSnapshot,
    employeeNationalIdSnapshot:
        employeeNationalIdSnapshot ?? this.employeeNationalIdSnapshot,
    employeePayslipFooterNoteSnapshot:
        employeePayslipFooterNoteSnapshot ??
        this.employeePayslipFooterNoteSnapshot,
    year: year,
    month: month,
    totalDays: totalDays,
    leaveDays: leaveDays ?? this.leaveDays,
    sickLeaveDays: sickLeaveDays ?? this.sickLeaveDays,
    workDays: workDays ?? this.workDays,
    overtimeHours: overtimeHours,
    overtimeAmount: overtimeAmount,
    nightWorkHours: nightWorkHours ?? this.nightWorkHours,
    nightWorkAmount: nightWorkAmount ?? this.nightWorkAmount,
    fridayWorkHours: fridayWorkHours ?? this.fridayWorkHours,
    fridayWorkAmount: fridayWorkAmount ?? this.fridayWorkAmount,
    holidayWorkHours: holidayWorkHours ?? this.holidayWorkHours,
    holidayWorkAmount: holidayWorkAmount ?? this.holidayWorkAmount,
    missionDays: missionDays ?? this.missionDays,
    missionAmount: missionAmount ?? this.missionAmount,
    usePartTimeWage: usePartTimeWage ?? this.usePartTimeWage,
    partTimeWorkHours: partTimeWorkHours ?? this.partTimeWorkHours,
    useCustomOvertimeBase: useCustomOvertimeBase ?? this.useCustomOvertimeBase,
    overtimeBaseDaily: overtimeBaseDaily ?? this.overtimeBaseDaily,
    shiftWork: shiftWork,
    shiftWorkRate: shiftWorkRate ?? this.shiftWorkRate,
    hourlyBenefitsAmount: hourlyBenefitsAmount ?? this.hourlyBenefitsAmount,
    hourlyBenefitHours: hourlyBenefitHours ?? this.hourlyBenefitHours,
    baseSalary: baseSalary,
    housing: housing,
    food: food,
    marriage: marriage,
    childAllowance: childAllowance,
    seniority: seniority,
    otherBenefits: otherBenefits,
    jobRelatedBenefits: jobRelatedBenefits ?? this.jobRelatedBenefits,
    employeeRelatedBenefits:
        employeeRelatedBenefits ?? this.employeeRelatedBenefits,
    welfareBenefits: welfareBenefits ?? this.welfareBenefits,
    totalEarnings: totalEarnings,
    insurance: insurance,
    tax: tax,
    loanInstallment: loanInstallment,
    advance: advance,
    supplementaryInsurance:
        supplementaryInsurance ?? this.supplementaryInsurance,
    otherDeductions: otherDeductions,
    absenceDays: absenceDays ?? this.absenceDays,
    absenceHours: absenceHours ?? this.absenceHours,
    absenceDeduction: absenceDeduction ?? this.absenceDeduction,
    includeLeaveInPayslip: includeLeaveInPayslip ?? this.includeLeaveInPayslip,
    housingExempt: housingExempt ?? this.housingExempt,
    foodExempt: foodExempt ?? this.foodExempt,
    seniorityExempt: seniorityExempt ?? this.seniorityExempt,
    leaveAllowanceDays: leaveAllowanceDays ?? this.leaveAllowanceDays,
    excessLeaveDays: excessLeaveDays ?? this.excessLeaveDays,
    leaveDeduction: leaveDeduction ?? this.leaveDeduction,
    totalDeductions: totalDeductions ?? this.totalDeductions,
    insuranceBase: insuranceBase,
    taxBase: taxBase,
    twoSevenExemption: twoSevenExemption,
    taxReliefRate: taxReliefRate ?? this.taxReliefRate,
    taxReliefAmount: taxReliefAmount ?? this.taxReliefAmount,
    netSalary: netSalary ?? this.netSalary,
    rounding: rounding ?? this.rounding,
    finalPayment: finalPayment ?? this.finalPayment,
    payrollCalculationDetailsJson:
        payrollCalculationDetailsJson ?? this.payrollCalculationDetailsJson,
    notes: notes,
    createdAt: createdAt,
  );
}
