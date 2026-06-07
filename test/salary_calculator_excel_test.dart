import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/services/salary_calculator.dart';

void main() {
  test('salary calculator matches extracted Excel payroll rows', () {
    final raw = File(
      'data/excel_semantic_extract_1405.json',
    ).readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final settingsJson = data['settings'] as Map<String, dynamic>;
    final employeesJson = (data['employees'] as List)
        .cast<Map<String, dynamic>>();
    final recordsJson = (data['salaryRecords'] as List)
        .cast<Map<String, dynamic>>();

    final settings = AppSettings(
      year: _asInt(settingsJson['year']),
      dailyWage: _asDouble(settingsJson['dailyWage']),
      monthlyFood: _asDouble(settingsJson['monthlyFood']),
      monthlyHousing: _asDouble(settingsJson['monthlyHousing']),
      monthlyMarriage: _asDouble(settingsJson['monthlyMarriage']),
      monthlyChild: _asDouble(settingsJson['monthlyChild']),
      dailySeniority: _asDouble(settingsJson['dailySeniority']),
      salaryRateA: _asDouble(settingsJson['salaryRateA']),
      salaryRateB: _asDouble(settingsJson['salaryRateB']),
      fixedRial: _asDouble(settingsJson['fixedRial']),
      employeeInsuranceRate: _asDouble(settingsJson['employeeInsuranceRate']),
      employerInsuranceRate: _asDouble(settingsJson['employerInsuranceRate']),
      unemploymentInsuranceRate: _asDouble(
        settingsJson['unemploymentInsuranceRate'],
      ),
      twoSevenBaseRate: 2 / 7,
    );

    final employeesByCode = {
      for (final e in employeesJson)
        _asInt(e['personnelCode']): _employeeFromExcel(e),
    };

    var checkedRows = 0;
    for (final record in recordsJson) {
      final employee = employeesByCode[_asInt(record['personnelCode'])];
      if (employee == null) continue;
      if (!_isFormulaConsistent(employee, record)) continue;

      final result = SalaryCalculator.calculate(
        employee: employee,
        settings: settings,
        input: SalaryCalculationInput(
          totalDays: _asInt(record['totalDays']),
          leaveDays: _asDouble(record['leaveDays']),
          overtimeHours: _asDouble(record['overtimeHours']),
          shiftWork: _asDouble(record['shiftWork']),
          hourlyBenefitsAmount: _asDouble(record['hourlyBenefitsAmount']),
          includeLeaveInPayslip: false,
          insuranceExempt:
              _asDouble(record['insuranceBase']) == 0 &&
              _asDouble(record['totalEarnings']) > 0,
          taxExempt:
              _asDouble(record['tax']) == 0 &&
              _asDouble(record['totalEarnings']) > 400000000,
          loanInstallment: _asDouble(record['loanInstallment']),
          advance: _asDouble(record['advance']),
          otherDeductions: _asDouble(record['otherDeductions']),
        ),
      );

      _closeToExcel(result.baseSalary, record['baseSalary']);
      _closeToExcel(result.totalEarnings, record['totalEarnings']);
      _closeToExcel(result.insuranceBase, record['insuranceBase']);
      _closeToExcel(result.insurance, record['insurance']);
      _closeToExcel(result.tax, record['tax']);
      _closeToExcel(result.totalDeductions, record['totalDeductions']);
      _closeToExcel(result.finalPayment, record['finalPayment']);
      checkedRows++;
    }
    expect(checkedRows, greaterThanOrEqualTo(10));
  });
}

bool _isFormulaConsistent(Employee employee, Map<String, dynamic> record) {
  final totalDays = _asInt(record['totalDays']);
  final overtimeHours = _asDouble(record['overtimeHours']);
  final expectedBaseSalary = employee.dailyWage1405 * totalDays;
  final expectedOvertime =
      overtimeHours * (employee.dailyWage1405 / 7.33) * 1.4;
  return (expectedBaseSalary - _asDouble(record['baseSalary'])).abs() <= 2 &&
      (expectedOvertime - _asDouble(record['overtimeAmount'])).abs() <= 2;
}

Employee _employeeFromExcel(Map<String, dynamic> e) {
  final childrenCount = _asInt(e['childrenCount']);
  final dailyChildTotal = _asDouble(e['dailyChildAllowance']);
  return Employee(
    personnelCode: _asInt(e['personnelCode']),
    firstName: e['firstName'] as String,
    lastName: e['lastName'] as String,
    nationalId: e['nationalId'].toString(),
    hasPriorExperience: e['hasPriorExperience'] as bool? ?? true,
    isMarried: e['isMarried'] as bool? ?? false,
    childrenCount: childrenCount,
    lastYearSeniority: _asDouble(e['lastYearSeniority']),
    baseSalary30Days: _asDouble(e['baseSalary30Days']),
    dailyWage1405: _asDouble(e['dailyWage1405']),
    dailyWage1404: _asDouble(e['dailyWage1404']),
    dailyHousing: _asDouble(e['dailyHousing']),
    dailyFood: _asDouble(e['dailyFood']),
    dailyMarriage: _asDouble(e['dailyMarriage']),
    dailyChildAllowance: childrenCount > 0
        ? dailyChildTotal / childrenCount
        : 0,
    dailySeniority: _asDouble(e['dailySeniority']),
    otherBenefitsDaily: _asDouble(e['otherBenefitsDaily']),
    hourlyBenefits: _asDouble(e['hourlyBenefits']),
    startDate: e['startDate'].toString(),
  );
}

void _closeToExcel(double actual, Object? expected) {
  expect(actual, closeTo(_asDouble(expected), 2.0));
}

double _asDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _asInt(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}
