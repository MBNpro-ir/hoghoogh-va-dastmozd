import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/loan.dart';

void main() {
  test(
    'loan supports fractional installment counts and final partial payment',
    () {
      final loan = Loan(
        employeeId: 1,
        loanNumber: 1,
        amount: 500000000,
        installmentAmount: 40000000,
        totalInstallments: 12.5,
        paidInstallments: 12,
        startDate: '1405/01/01',
      );

      expect(loan.remainingInstallments, 0.5);
      expect(loan.remainingAmount, 20000000);
      expect(loan.nextInstallmentAmount, 20000000);
      expect(loan.nextInstallmentStep, 0.5);
    },
  );
}
