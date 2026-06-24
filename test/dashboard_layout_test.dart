import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/salary_record.dart';
import 'package:payroll_app/screens/home/dashboard_view.dart';
import 'package:payroll_app/services/dashboard_service.dart';

void main() {
  testWidgets('desktop dashboard lays out populated bottom cards', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);

    final snapshot = _dashboardSnapshot();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardView(
          onNavigateToEmployees: () {},
          onNavigateToSalaryCalc: () {},
          onNavigateToSalaryRecords: () {},
          onNavigateToLoans: () {},
          onNavigateToSettings: () {},
          service: _FakeDashboardService(snapshot),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop bottom cards tolerate scaled Windows text metrics', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);

    final snapshot = _dashboardSnapshot();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1600, 1000),
            textScaler: TextScaler.linear(1.1),
          ),
          child: DashboardView(
            onNavigateToEmployees: () {},
            onNavigateToSalaryCalc: () {},
            onNavigateToSalaryRecords: () {},
            onNavigateToLoans: () {},
            onNavigateToSettings: () {},
            service: _FakeDashboardService(snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

DashboardSnapshot _dashboardSnapshot() {
  final employee = Employee(
    id: 1,
    personnelCode: 1,
    firstName: 'Test',
    lastName: 'Employee',
    nationalId: '0012345678',
    startDate: '1400/01/01',
  );
  final record = SalaryRecord(
    id: 1,
    employeeId: 1,
    employeeFullNameSnapshot: employee.fullName,
    employeePersonnelCodeSnapshot: employee.personnelCode,
    year: 1405,
    month: 3,
    totalDays: 31,
    leaveDays: 0,
    workDays: 31,
    baseSalary: 100000000,
    housing: 20000000,
    food: 22000000,
    marriage: 0,
    childAllowance: 0,
    seniority: 0,
    totalEarnings: 142000000,
    insurance: 9940000,
    tax: 0,
    totalDeductions: 9940000,
    insuranceBase: 142000000,
    taxBase: 142000000,
    netSalary: 132060000,
    finalPayment: 132060000,
  );
  final records = List<SalaryRecord>.filled(5, record);
  return DashboardSnapshot(
    settings: AppSettings(year: 1405),
    targetYear: 1405,
    targetMonth: 3,
    targetLabel: '1405/03',
    now: DateTime(2026, 6, 24),
    employees: [employee],
    activeEmployees: [employee],
    marriedCount: 0,
    withChildrenCount: 0,
    priorExperienceCount: 1,
    currentRecords: records,
    hasAnyRecord: true,
    monthRecordCount: records.length,
    monthNet: 660300000,
    monthGross: 710000000,
    monthTax: 0,
    monthInsuranceEmployee: 49700000,
    monthInsuranceEmployer: 0,
    monthLoanInstallment: 0,
    monthOvertime: 0,
    avgNet: 132060000,
    maxNet: 132060000,
    activeLoans: const [],
    totalActiveLoanAmount: 0,
    totalRemainingLoan: 0,
    totalPaidLoan: 0,
    monthlyInstallmentSum: 0,
    loanProgress: 0,
    monthlyHistory: const [],
    recentRecords: records,
    topEarners: records,
    ytdNet: 660300000,
    ytdGross: 710000000,
    ytdTax: 0,
    ytdInsuranceEmployee: 49700000,
    ytdInsuranceEmployer: 0,
    ytdLoanInstallment: 0,
  );
}

class _FakeDashboardService extends DashboardService {
  final DashboardSnapshot snapshot;

  _FakeDashboardService(this.snapshot);

  @override
  Future<DashboardSnapshot> loadSnapshot({required int currentYear}) async =>
      snapshot;
}
