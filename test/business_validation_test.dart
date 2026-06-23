import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee_leave.dart';
import 'package:payroll_app/models/loan.dart';
import 'package:payroll_app/models/salary_draft.dart';
import 'package:payroll_app/utils/app_error_message.dart';
import 'package:payroll_app/utils/business_validation.dart';

void main() {
  test('loan validation rejects impossible installment values', () {
    final loan = Loan(
      employeeId: 1,
      loanNumber: 1,
      amount: 1000000,
      installmentAmount: 100000,
      totalInstallments: 10,
      paidInstallments: 11,
      startDate: '1405/04/01',
    );

    expect(
      () => BusinessValidation.loan(loan),
      throwsA(isA<BusinessValidationException>()),
    );
  });

  test('leave validation rejects days outside selected date range', () {
    const leave = EmployeeLeave(
      employeeId: 1,
      fromDate: '1405/04/01',
      toDate: '1405/04/02',
      days: 3,
    );

    expect(
      () => BusinessValidation.leave(leave),
      throwsA(isA<BusinessValidationException>()),
    );
  });

  test('salary draft validation rejects invalid payroll periods', () {
    const draft = SalaryDraft(
      employeeId: 1,
      year: 1405,
      month: 13,
      totalDays: 30,
    );

    expect(
      () => BusinessValidation.salaryDraft(draft),
      throwsA(isA<BusinessValidationException>()),
    );
  });

  test('settings validation rejects percentage outside allowed range', () {
    final settings = AppSettings(employeeInsuranceRate: 1.1);

    expect(
      () => BusinessValidation.settings(settings),
      throwsA(isA<BusinessValidationException>()),
    );
  });

  test('technical unique errors are converted to a user message', () {
    final message = AppErrorMessage.from(
      Exception('SQLite constraint failed: UNIQUE constraint failed'),
      fallback: 'fallback',
    );

    expect(message, contains('قبلاً ثبت شده'));
    expect(message, isNot(contains('SQLite')));
  });
}
