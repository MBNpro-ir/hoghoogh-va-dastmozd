import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/salary_record.dart';
import 'package:payroll_app/services/salary_calculator.dart';

void main() {
  final employee = Employee(
    personnelCode: 1,
    firstName: 'تست',
    lastName: 'استعلاجی',
    nationalId: '0012345678',
    dailyWage1405: 1000000,
    dailyHousing: 0,
    dailyFood: 0,
    dailyMarriage: 0,
    dailyChildAllowance: 0,
    dailySeniority: 0,
    otherBenefitsDaily: 0,
    startDate: '1400/01/01',
  );
  final settings = AppSettings(
    dailyWage: 1000000,
    employeeInsuranceRate: 0,
    employerInsuranceRate: 0,
    unemploymentInsuranceRate: 0,
    monthlyLeaveAllowance: 2.5,
  );

  test('sick leave is separate from annual leave and employer-paid days', () {
    final input = SalaryCalculationInput(
      totalDays: 30,
      leaveDays: 2,
      sickLeaveDays: 3,
      includeLeaveInPayslip: true,
      taxExempt: true,
    );
    final result = SalaryCalculator.calculate(
      employee: employee,
      settings: settings,
      input: input,
    );

    expect(input.workDays, 25);
    expect(input.payableDays, 27);
    expect(result.payableDays, 27);
    expect(result.baseSalary, 27000000);
    expect(result.excessLeaveDays, 0);
  });

  test('salary records persist sick leave and read old rows as zero', () {
    final result = SalaryCalculator.calculate(
      employee: employee,
      settings: settings,
      input: SalaryCalculationInput(
        totalDays: 30,
        sickLeaveDays: 1.5,
        taxExempt: true,
      ),
    );
    final record = result.toRecord(
      employeeId: 1,
      year: 1405,
      month: 1,
      totalDays: 30,
      leaveDays: 0,
      sickLeaveDays: 1.5,
      workDays: 28.5,
      overtimeHours: 0,
      hourlyBenefitHours: 0,
      includeLeaveInPayslip: true,
      housingExempt: false,
      foodExempt: false,
      seniorityExempt: false,
    );

    expect(SalaryRecord.fromMap(record.toMap()).sickLeaveDays, 1.5);
    final oldRow = record.toMap()..remove('sick_leave_days');
    expect(SalaryRecord.fromMap(oldRow).sickLeaveDays, 0);
  });
}
