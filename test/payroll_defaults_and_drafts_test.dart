import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/salary_draft.dart';
import 'package:payroll_app/models/salary_record.dart';
import 'package:payroll_app/services/payroll_calculator_registry.dart';
import 'package:payroll_app/services/salary_calculator.dart';
import 'package:payroll_app/utils/constants.dart';

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
      shiftWorkRate: AppConstants.shiftWorkRate,
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
      shiftWorkRate: AppConstants.shiftWorkRate,
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

  test(
    'complementary payslip rows affect earnings deductions and tax relief',
    () {
      final employee = Employee(
        personnelCode: 1,
        firstName: 'علی',
        lastName: 'تکمیلی',
        nationalId: '0012345678',
        dailyWage1405: 10000000,
        dailyHousing: 0,
        dailyFood: 0,
        dailyMarriage: 0,
        dailyChildAllowance: 0,
        dailySeniority: 0,
        startDate: '1405/01/01',
      );
      final settings = AppSettings(
        dailyWage: 10000000,
        employeeInsuranceRate: 0.07,
        employerInsuranceRate: 0.20,
        unemploymentInsuranceRate: 0.03,
      );
      final result = SalaryCalculator.calculate(
        employee: employee,
        settings: settings,
        input: SalaryCalculationInput(
          totalDays: 30,
          autoShiftWork: true,
          shiftWorkRate: 0.225,
          jobRelatedBenefits: 3000000,
          employeeRelatedBenefits: 2000000,
          welfareBenefits: 1000000,
          supplementaryInsurance: 500000,
          taxReliefRate: 0.50,
          seniorityExempt: true,
        ),
      );

      final expectedBaseSalary = 300000000.0;
      final expectedShiftWork = expectedBaseSalary * 0.225;
      final expectedGross =
          expectedBaseSalary + expectedShiftWork + 3000000 + 2000000 + 1000000;
      final expectedInsurance = expectedGross * settings.employeeInsuranceRate;
      final expectedTwoSeven = expectedInsurance * settings.twoSevenBaseRate;
      final expectedTaxBase = expectedGross - expectedTwoSeven - 500000;
      final expectedGrossTax = SalaryCalculator.calculateTax(expectedTaxBase);

      expect(result.shiftWorkRate, 0.225);
      expect(result.shiftWork, closeTo(expectedShiftWork, 1));
      expect(result.totalEarnings, closeTo(expectedGross, 1));
      expect(result.jobRelatedBenefits, 3000000);
      expect(result.employeeRelatedBenefits, 2000000);
      expect(result.welfareBenefits, 1000000);
      expect(result.supplementaryInsurance, 500000);
      expect(result.insurance, closeTo(expectedInsurance, 1));
      expect(result.taxBase, closeTo(expectedTaxBase, 1));
      expect(result.taxReliefAmount, closeTo(expectedGrossTax * 0.50, 1));
      expect(
        result.totalDeductions,
        closeTo(
          expectedInsurance + result.tax + result.supplementaryInsurance,
          1,
        ),
      );
    },
  );

  test('calculator registry exposes payslip complementary rows', () {
    final settings = AppSettings(
      dailyWage: 10000000,
      employeeInsuranceRate: 0,
      employerInsuranceRate: 0,
      unemploymentInsuranceRate: 0,
    );
    final online = PayrollCalculatorRegistry.byId('online_payslip')!;
    final outputs = online.calculate({
      'daily_wage': 10000000,
      'payable_days': 30,
      'shift_rate': 0.10,
      'job_related_benefits': 1000000,
      'employee_related_benefits': 2000000,
      'welfare_benefits': 3000000,
      'supplementary_insurance': 400000,
      'tax_relief_rate': 0.50,
    }, settings);

    expect(online.appliesToPayslip, isTrue);
    expect(outputs['shift_work'], 30000000);
    expect(outputs['job_related_benefits'], 1000000);
    expect(outputs['employee_related_benefits'], 2000000);
    expect(outputs['welfare_benefits'], 3000000);
    expect(outputs['supplementary_insurance'], 400000);
    expect(
      PayrollCalculatorRegistry.byId('job_wage_benefits')?.appliesToPayslip,
      isTrue,
    );
    expect(
      PayrollCalculatorRegistry.byId(
        'supplementary_insurance',
      )?.appliesToPayslip,
      isTrue,
    );
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
      shiftWorkRate: 0.225,
      jobRelatedBenefits: 1000000,
      employeeRelatedBenefits: 2000000,
      welfareBenefits: 3000000,
      useCustomOvertimeBase: true,
      overtimeBaseDaily: 5176500,
      autoShiftWork: true,
      autoLoanInstallment: false,
      skipLoanInstallment: true,
      insuranceExempt: true,
      supplementaryInsurance: 400000,
      housingExempt: true,
      foodExempt: true,
      seniorityExempt: true,
      taxReliefRate: 0.50,
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
    expect(restored.shiftWorkRate, 0.225);
    expect(restored.jobRelatedBenefits, 1000000);
    expect(restored.employeeRelatedBenefits, 2000000);
    expect(restored.welfareBenefits, 3000000);
    expect(restored.absenceDeduction, 566500);
    expect(restored.useCustomOvertimeBase, isTrue);
    expect(restored.overtimeBaseDaily, 5176500);
    expect(restored.autoShiftWork, isTrue);
    expect(restored.skipLoanInstallment, isTrue);
    expect(restored.insuranceExempt, isTrue);
    expect(restored.supplementaryInsurance, 400000);
    expect(restored.housingExempt, isTrue);
    expect(restored.foodExempt, isTrue);
    expect(restored.seniorityExempt, isTrue);
    expect(restored.taxReliefRate, 0.50);
    expect(restored.dailySeniorityOverride, 123456);
    expect(restored.autoSeniority, isFalse);

    final nextMonth = restored.copyForPeriod(year: 1405, month: 4);
    expect(nextMonth.id, isNull);
    expect(nextMonth.month, 4);
    expect(nextMonth.overtimeHours, 8.25);
    expect(nextMonth.nightWorkHours, 2);
    expect(nextMonth.shiftWorkRate, 0.225);
    expect(nextMonth.jobRelatedBenefits, 1000000);
    expect(nextMonth.supplementaryInsurance, 400000);
    expect(nextMonth.absenceHours, 2);
    expect(nextMonth.housingExempt, isTrue);
    expect(nextMonth.foodExempt, isTrue);
    expect(nextMonth.seniorityExempt, isTrue);
    expect(nextMonth.taxReliefRate, 0.50);
    expect(nextMonth.dailySeniorityOverride, 123456);
    expect(nextMonth.autoSeniority, isFalse);
  });
}
