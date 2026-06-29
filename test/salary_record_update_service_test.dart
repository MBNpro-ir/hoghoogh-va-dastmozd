import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/salary_record.dart';
import 'package:payroll_app/services/salary_calculator.dart';
import 'package:payroll_app/services/salary_record_update_service.dart';

void main() {
  test('source snapshot detects changed leave loan and advance values', () {
    final record = _record();
    const snapshot = SalaryRecordSourceSnapshot(
      leaveDays: 3,
      sickLeaveDays: 1,
      loanInstallment: 2000000,
      advance: 500000,
    );

    expect(snapshot.hasChangesComparedTo(record), isTrue);
    expect(snapshot.changedLabelsComparedTo(record), [
      'مرخصی',
      'وام',
      'مساعده',
    ]);
  });

  test(
    'paid final loan installment does not mark the payslip stale by itself',
    () {
      final record = _record();
      const snapshot = SalaryRecordSourceSnapshot(
        leaveDays: 1,
        sickLeaveDays: 0,
        loanInstallment: 0,
        advance: 200000,
      );

      expect(snapshot.hasChangesComparedTo(record), isFalse);
    },
  );

  test('rebuildRecord updates the saved payslip with the current snapshot', () {
    final employee = _employee();
    final settings = _settings();
    final record = _record(employee: employee, settings: settings);
    const snapshot = SalaryRecordSourceSnapshot(
      leaveDays: 2,
      sickLeaveDays: 1,
      loanInstallment: 1500000,
      advance: 300000,
    );

    final updated = SalaryRecordUpdateService().rebuildRecord(
      record: record,
      employee: employee,
      settings: settings,
      snapshot: snapshot,
    );

    expect(updated.id, record.id);
    expect(updated.leaveDays, 2);
    expect(updated.sickLeaveDays, 1);
    expect(updated.workDays, 27);
    expect(updated.loanInstallment, 1500000);
    expect(updated.advance, 300000);
    expect(updated.finalPayment, isNot(record.finalPayment));
  });
}

Employee _employee() {
  return Employee(
    id: 7,
    personnelCode: 1001,
    firstName: 'کارمند',
    lastName: 'آزمایشی',
    nationalId: '0012345678',
    dailyWage1405: 5000000,
    dailyHousing: 100000,
    dailyFood: 100000,
    dailySeniority: 50000,
    startDate: '1400/01/01',
  );
}

AppSettings _settings() {
  return AppSettings(
    employeeInsuranceRate: 0,
    employerInsuranceRate: 0,
    unemploymentInsuranceRate: 0,
    monthlyLeaveAllowance: 2.5,
  );
}

SalaryRecord _record({Employee? employee, AppSettings? settings}) {
  final targetEmployee = employee ?? _employee();
  final targetSettings = settings ?? _settings();
  final input = SalaryCalculationInput(
    totalDays: 30,
    leaveDays: 1,
    sickLeaveDays: 0,
    insuranceExempt: true,
    taxExempt: true,
    loanInstallment: 1000000,
    advance: 200000,
  );
  final result = SalaryCalculator.calculate(
    employee: targetEmployee,
    settings: targetSettings,
    input: input,
  );

  return result
      .toRecord(
        employeeId: targetEmployee.id!,
        employeeFullNameSnapshot: targetEmployee.fullName,
        employeePersonnelCodeSnapshot: targetEmployee.personnelCode,
        employeeNationalIdSnapshot: targetEmployee.nationalId,
        year: 1405,
        month: 4,
        totalDays: input.totalDays,
        leaveDays: input.leaveDays,
        sickLeaveDays: input.sickLeaveDays,
        workDays: input.workDays,
        overtimeHours: input.overtimeHours,
        shiftWorkRate: input.shiftWorkRate,
        hourlyBenefitHours: input.hourlyBenefitHours,
        includeLeaveInPayslip: input.includeLeaveInPayslip,
        housingExempt: input.housingExempt,
        foodExempt: input.foodExempt,
        seniorityExempt: input.seniorityExempt,
      )
      .copyWithId(42);
}
