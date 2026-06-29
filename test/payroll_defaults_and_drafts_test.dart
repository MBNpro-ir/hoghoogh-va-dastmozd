import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/salary_draft.dart';
import 'package:payroll_app/models/salary_record.dart';
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

  test('fixed benefit exemptions zero selected salary rows', () {
    final employee = Employee(
      personnelCode: 1,
      firstName: 'علی',
      lastName: 'آزمایشی',
      nationalId: '0012345678',
      dailyWage1405: 1000000,
      dailyHousing: 200000,
      dailyFood: 300000,
      dailySeniority: 400000,
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
        housingExempt: true,
        foodExempt: true,
        seniorityExempt: true,
        taxExempt: true,
      ),
    );
    final record = result.toRecord(
      employeeId: 1,
      year: 1405,
      month: 4,
      totalDays: 30,
      leaveDays: 0,
      sickLeaveDays: 0,
      workDays: 30,
      overtimeHours: 0,
      hourlyBenefitHours: 0,
      includeLeaveInPayslip: true,
      housingExempt: true,
      foodExempt: true,
      seniorityExempt: true,
    );

    expect(result.housing, 0);
    expect(result.food, 0);
    expect(result.seniority, 0);
    expect(result.totalEarnings, 30000000);
    final restored = SalaryRecord.fromMap(record.toMap());
    expect(restored.housingExempt, isTrue);
    expect(restored.foodExempt, isTrue);
    expect(restored.seniorityExempt, isTrue);
  });

  test('special payroll work rows affect earnings and deductions', () {
    final employee = Employee(
      personnelCode: 1,
      firstName: 'علی',
      lastName: 'آزمایشی',
      nationalId: '0012345678',
      dailyWage1405: 733000,
      dailyHousing: 0,
      dailyFood: 0,
      dailyMarriage: 0,
      dailyChildAllowance: 0,
      dailySeniority: 0,
      startDate: '1405/01/01',
    );
    final result = SalaryCalculator.calculate(
      employee: employee,
      settings: AppSettings(
        employeeInsuranceRate: 0,
        employerInsuranceRate: 0,
        unemploymentInsuranceRate: 0,
        nightWorkRate: 0.35,
        fridayWorkRate: 0.40,
        holidayWorkMultiplier: 1.40,
        missionDailyMultiplier: 1,
        absenceHourlyMultiplier: 1,
      ),
      input: SalaryCalculationInput(
        totalDays: 30,
        nightWorkHours: 2,
        fridayWorkHours: 3,
        holidayWorkHours: 4,
        missionDays: 1,
        absenceDays: 0.5,
        absenceHours: 2,
        taxExempt: true,
        seniorityExempt: true,
      ),
    );

    expect(result.nightWorkAmount, closeTo(70000, 1));
    expect(result.fridayWorkAmount, closeTo(120000, 1));
    expect(result.holidayWorkAmount, closeTo(560000, 1));
    expect(result.missionAmount, closeTo(733000, 1));
    expect(result.absenceDeduction, closeTo(566500, 1));

    final record = result.toRecord(
      employeeId: 1,
      year: 1405,
      month: 4,
      totalDays: 30,
      leaveDays: 0,
      sickLeaveDays: 0,
      workDays: 30,
      overtimeHours: 0,
      nightWorkHours: 2,
      fridayWorkHours: 3,
      holidayWorkHours: 4,
      missionDays: 1,
      absenceDays: 0.5,
      absenceHours: 2,
      hourlyBenefitHours: 0,
      includeLeaveInPayslip: true,
      housingExempt: false,
      foodExempt: false,
      seniorityExempt: true,
    );
    final restored = SalaryRecord.fromMap(record.toMap());
    expect(restored.nightWorkHours, 2);
    expect(restored.fridayWorkAmount, closeTo(120000, 1));
    expect(restored.absenceDeduction, closeTo(566500, 1));
    expect(restored.payrollCalculationDetailsJson, contains('salary-1405-v2'));
  });

  test('salary calculation derives seniority from the payslip period', () {
    final employee = Employee(
      personnelCode: 1,
      firstName: 'علی',
      lastName: 'آزمایشی',
      nationalId: '0012345678',
      dailyWage1405: 1000000,
      dailySeniority: 1,
      startDate: '1389/07/24',
    );
    final settings = AppSettings(
      year: 1405,
      employeeInsuranceRate: 0,
      employerInsuranceRate: 0,
      unemploymentInsuranceRate: 0,
    );

    final automatic = SalaryCalculator.calculate(
      employee: employee,
      settings: settings,
      input: SalaryCalculationInput(
        year: 1405,
        month: 1,
        totalDays: 31,
        taxExempt: true,
      ),
    );
    final manual = SalaryCalculator.calculate(
      employee: employee,
      settings: settings,
      input: SalaryCalculationInput(
        year: 1405,
        month: 1,
        totalDays: 31,
        dailySeniorityOverride: 2000000,
        taxExempt: true,
      ),
    );

    expect(automatic.seniority, 55597632);
    expect(manual.seniority, 62000000);
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
      nightWorkHours: 2,
      nightWorkAmount: 70000,
      fridayWorkHours: 3,
      fridayWorkAmount: 120000,
      holidayWorkHours: 4,
      holidayWorkAmount: 560000,
      missionDays: 1,
      missionAmount: 733000,
      useCustomOvertimeBase: true,
      overtimeBaseDaily: 5176500,
      autoShiftWork: true,
      autoLoanInstallment: false,
      skipLoanInstallment: true,
      insuranceExempt: true,
      housingExempt: true,
      foodExempt: true,
      seniorityExempt: true,
      dailySeniorityOverride: 123456,
      autoSeniority: false,
      absenceDays: 0.5,
      absenceHours: 2,
      absenceDeduction: 566500,
    );

    final restored = SalaryDraft.fromMap(draft.toMap());
    expect(restored.leaveDays, 1.5);
    expect(restored.sickLeaveDays, 2);
    expect(restored.overtimeHours, 8.25);
    expect(restored.nightWorkHours, 2);
    expect(restored.fridayWorkAmount, 120000);
    expect(restored.holidayWorkHours, 4);
    expect(restored.missionAmount, 733000);
    expect(restored.absenceDeduction, 566500);
    expect(restored.useCustomOvertimeBase, isTrue);
    expect(restored.overtimeBaseDaily, 5176500);
    expect(restored.autoShiftWork, isTrue);
    expect(restored.skipLoanInstallment, isTrue);
    expect(restored.insuranceExempt, isTrue);
    expect(restored.housingExempt, isTrue);
    expect(restored.foodExempt, isTrue);
    expect(restored.seniorityExempt, isTrue);
    expect(restored.dailySeniorityOverride, 123456);
    expect(restored.autoSeniority, isFalse);

    final nextMonth = restored.copyForPeriod(year: 1405, month: 4);
    expect(nextMonth.id, isNull);
    expect(nextMonth.month, 4);
    expect(nextMonth.overtimeHours, 8.25);
    expect(nextMonth.nightWorkHours, 2);
    expect(nextMonth.absenceHours, 2);
    expect(nextMonth.housingExempt, isTrue);
    expect(nextMonth.foodExempt, isTrue);
    expect(nextMonth.seniorityExempt, isTrue);
    expect(nextMonth.dailySeniorityOverride, 123456);
    expect(nextMonth.autoSeniority, isFalse);
  });
}
