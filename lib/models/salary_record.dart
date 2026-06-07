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
  final double workDays; // کارکرد خالص

  // ساعات و مزایا
  final double overtimeHours; // ساعت اضافه‌کاری
  final double overtimeAmount; // مبلغ اضافه‌کاری
  final double shiftWork; // نوبت‌کاری
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
  final double totalEarnings; // جمع حقوق و مزایا

  // کسورات
  final double insurance; // حق بیمه 7%
  final double tax; // مالیات
  final double loanInstallment; // قسط وام
  final double advance; // مساعده
  final double otherDeductions; // سایر کسورات (مابه‌تفاوت)
  final bool includeLeaveInPayslip; // محاسبه محدودیت مرخصی در فیش
  final double leaveAllowanceDays; // سقف مرخصی مجاز ماهانه
  final double excessLeaveDays; // مرخصی مازاد
  final double leaveDeduction; // کسر مرخصی مازاد
  final double totalDeductions; // جمع کسورات

  // محاسبات نهایی
  final double insuranceBase; // حقوق مشمول بیمه
  final double taxBase; // مبنای مالیات
  final double twoSevenExemption; // معافیت دو هفتم
  final double netSalary; // خالص حقوق
  final int rounding; // رند حقوق
  final double finalPayment; // خالص دریافتی نهایی

  final String? notes;
  final DateTime createdAt;

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
    required this.workDays,
    this.overtimeHours = 0,
    this.overtimeAmount = 0,
    this.shiftWork = 0,
    this.hourlyBenefitsAmount = 0,
    this.hourlyBenefitHours = 0,
    required this.baseSalary,
    required this.housing,
    required this.food,
    required this.marriage,
    required this.childAllowance,
    required this.seniority,
    this.otherBenefits = 0,
    required this.totalEarnings,
    required this.insurance,
    required this.tax,
    this.loanInstallment = 0,
    this.advance = 0,
    this.otherDeductions = 0,
    this.includeLeaveInPayslip = true,
    this.leaveAllowanceDays = 2.5,
    this.excessLeaveDays = 0,
    this.leaveDeduction = 0,
    required this.totalDeductions,
    required this.insuranceBase,
    required this.taxBase,
    this.twoSevenExemption = 0,
    required this.netSalary,
    this.rounding = 0,
    required this.finalPayment,
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
    'work_days': workDays,
    'overtime_hours': overtimeHours,
    'overtime_amount': overtimeAmount,
    'shift_work': shiftWork,
    'hourly_benefits_amount': hourlyBenefitsAmount,
    'hourly_benefit_hours': hourlyBenefitHours,
    'base_salary': baseSalary,
    'housing': housing,
    'food': food,
    'marriage': marriage,
    'child_allowance': childAllowance,
    'seniority': seniority,
    'other_benefits': otherBenefits,
    'total_earnings': totalEarnings,
    'insurance': insurance,
    'tax': tax,
    'loan_installment': loanInstallment,
    'advance': advance,
    'other_deductions': otherDeductions,
    'include_leave_in_payslip': includeLeaveInPayslip ? 1 : 0,
    'leave_allowance_days': leaveAllowanceDays,
    'excess_leave_days': excessLeaveDays,
    'leave_deduction': leaveDeduction,
    'total_deductions': totalDeductions,
    'insurance_base': insuranceBase,
    'tax_base': taxBase,
    'two_seven_exemption': twoSevenExemption,
    'net_salary': netSalary,
    'rounding': rounding,
    'final_payment': finalPayment,
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
    workDays: (map['work_days'] as num).toDouble(),
    overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0,
    overtimeAmount: (map['overtime_amount'] as num?)?.toDouble() ?? 0,
    shiftWork: (map['shift_work'] as num?)?.toDouble() ?? 0,
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
    totalEarnings: (map['total_earnings'] as num).toDouble(),
    insurance: (map['insurance'] as num).toDouble(),
    tax: (map['tax'] as num).toDouble(),
    loanInstallment: (map['loan_installment'] as num?)?.toDouble() ?? 0,
    advance: (map['advance'] as num?)?.toDouble() ?? 0,
    otherDeductions: (map['other_deductions'] as num?)?.toDouble() ?? 0,
    includeLeaveInPayslip: (map['include_leave_in_payslip'] as int? ?? 1) == 1,
    leaveAllowanceDays:
        (map['leave_allowance_days'] as num?)?.toDouble() ?? 2.5,
    excessLeaveDays: (map['excess_leave_days'] as num?)?.toDouble() ?? 0,
    leaveDeduction: (map['leave_deduction'] as num?)?.toDouble() ?? 0,
    totalDeductions: (map['total_deductions'] as num).toDouble(),
    insuranceBase: (map['insurance_base'] as num).toDouble(),
    taxBase: (map['tax_base'] as num).toDouble(),
    twoSevenExemption: (map['two_seven_exemption'] as num?)?.toDouble() ?? 0,
    netSalary: (map['net_salary'] as num).toDouble(),
    rounding: map['rounding'] as int? ?? 0,
    finalPayment: (map['final_payment'] as num).toDouble(),
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
    workDays: workDays,
    overtimeHours: overtimeHours,
    overtimeAmount: overtimeAmount,
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
    includeLeaveInPayslip: includeLeaveInPayslip,
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
    double? workDays,
    double? hourlyBenefitHours,
    double? hourlyBenefitsAmount,
    bool? includeLeaveInPayslip,
    double? leaveAllowanceDays,
    double? excessLeaveDays,
    double? leaveDeduction,
    double? totalDeductions,
    double? netSalary,
    int? rounding,
    double? finalPayment,
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
    workDays: workDays ?? this.workDays,
    overtimeHours: overtimeHours,
    overtimeAmount: overtimeAmount,
    shiftWork: shiftWork,
    hourlyBenefitsAmount: hourlyBenefitsAmount ?? this.hourlyBenefitsAmount,
    hourlyBenefitHours: hourlyBenefitHours ?? this.hourlyBenefitHours,
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
    includeLeaveInPayslip: includeLeaveInPayslip ?? this.includeLeaveInPayslip,
    leaveAllowanceDays: leaveAllowanceDays ?? this.leaveAllowanceDays,
    excessLeaveDays: excessLeaveDays ?? this.excessLeaveDays,
    leaveDeduction: leaveDeduction ?? this.leaveDeduction,
    totalDeductions: totalDeductions ?? this.totalDeductions,
    insuranceBase: insuranceBase,
    taxBase: taxBase,
    twoSevenExemption: twoSevenExemption,
    netSalary: netSalary ?? this.netSalary,
    rounding: rounding ?? this.rounding,
    finalPayment: finalPayment ?? this.finalPayment,
    notes: notes,
    createdAt: createdAt,
  );
}
