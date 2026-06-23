import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/employee_leave.dart';

void main() {
  test('employee leave normalizes type and status for payroll use', () {
    final sick = EmployeeLeave.fromMap({
      'id': 1,
      'employee_id': 2,
      'from_date': '1405/04/01',
      'to_date': '1405/04/01',
      'days': 1.5,
      'type': 'استعلاجی',
      'status': 'approved',
    });

    expect(sick.isSick, isTrue);
    expect(sick.isApproved, isTrue);
    expect(sick.toMap()['type'], EmployeeLeave.typeSick);
    expect(sick.toMap()['status'], EmployeeLeave.statusApproved);
  });

  test('pending annual leave is stored but excluded by status flag', () {
    const leave = EmployeeLeave(
      employeeId: 2,
      fromDate: '1405/04/02',
      toDate: '1405/04/02',
      days: 2,
      type: EmployeeLeave.typeAnnual,
      status: EmployeeLeave.statusPending,
    );

    expect(leave.isSick, isFalse);
    expect(leave.isApproved, isFalse);
    expect(leave.toMap()['type'], EmployeeLeave.typeAnnual);
    expect(leave.toMap()['status'], EmployeeLeave.statusPending);
  });
}
