import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/salary_draft.dart';
import 'package:payroll_app/services/salary_calculator.dart';

void main() {
  test('employee payroll defaults survive database mapping', () {
    final employee = Employee(
      personnelCode: 1,
      firstName: 'علی',
      lastName: 'آزمایشی',
      nationalId: '0012345678',
      hasShiftWork: true,
      useCustomOvertimeBase: true,
      overtimeBaseDaily: 5176500,
      startDate: '1400/01/01',
    );

    final restored = Employee.fromMap(employee.toMap());
    expect(restored.hasShiftWork, isTrue);
    expect(restored.useCustomOvertimeBase, isTrue);
    expect(restored.overtimeBaseDaily, 5176500);
  });

  test('manual overtime base is used in the overtime formula', () {
    final employee = Employee(
      personnelCode: 1,
      firstName: 'علی',
      lastName: 'آزمایشی',
      nationalId: '0012345678',
      dailyWage1405: 4000000,
      startDate: '1400/01/01',
    );
    final result = SalaryCalculator.calculate(
      employee: employee,
      settings: AppSettings(
        employeeInsuranceRate: 0,
        employerInsuranceRate: 0,
        unemploymentInsuranceRate: 0,
      ),
      input: SalaryCalculationInput(
        overtimeHours: 12.5,
        useCustomOvertimeBase: true,
        overtimeBaseDaily: 5176500,
        insuranceExempt: true,
        taxExempt: true,
      ),
    );

    expect(result.overtimeAmount, closeTo((5176500 / 7.33) * 1.4 * 12.5, 1));
    expect(result.useCustomOvertimeBase, isTrue);
    expect(result.overtimeBaseDaily, 5176500);
  });

  test('salary draft preserves exact monthly form state', () {
    const draft = SalaryDraft(
      employeeId: 4,
      year: 1405,
      month: 3,
      totalDays: 31,
      leaveDays: 1.5,
      sickLeaveDays: 2,
      overtimeHours: 8.25,
      useCustomOvertimeBase: true,
      overtimeBaseDaily: 5176500,
      autoShiftWork: true,
      autoLoanInstallment: false,
      skipLoanInstallment: true,
      insuranceExempt: true,
    );

    final restored = SalaryDraft.fromMap(draft.toMap());
    expect(restored.leaveDays, 1.5);
    expect(restored.sickLeaveDays, 2);
    expect(restored.overtimeHours, 8.25);
    expect(restored.useCustomOvertimeBase, isTrue);
    expect(restored.overtimeBaseDaily, 5176500);
    expect(restored.autoShiftWork, isTrue);
    expect(restored.skipLoanInstallment, isTrue);
    expect(restored.insuranceExempt, isTrue);

    final nextMonth = restored.copyForPeriod(year: 1405, month: 4);
    expect(nextMonth.id, isNull);
    expect(nextMonth.month, 4);
    expect(nextMonth.overtimeHours, 8.25);
  });
}
