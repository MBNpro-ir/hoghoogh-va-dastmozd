import '../database/database_helper.dart';
import '../models/loan.dart';

/// سرویس مدیریت وام و اقساط
class LoanService {
  final _db = DatabaseHelper.instance;

  Future<List<Loan>> getAll({bool onlyActive = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'loans',
      where: onlyActive ? 'is_active = ?' : null,
      whereArgs: onlyActive ? [1] : null,
      orderBy: 'employee_id ASC, loan_number ASC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<List<Loan>> getByEmployee(
    int employeeId, {
    bool onlyActive = false,
  }) async {
    final db = await _db.database;
    final where = onlyActive
        ? 'employee_id = ? AND is_active = ?'
        : 'employee_id = ?';
    final args = onlyActive ? [employeeId, 1] : [employeeId];
    final rows = await db.query(
      'loans',
      where: where,
      whereArgs: args,
      orderBy: 'loan_number ASC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<Loan?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  Future<int> insert(Loan loan) async {
    final db = await _db.database;
    return await db.insert('loans', loan.toMap()..remove('id'));
  }

  Future<int> update(Loan loan) async {
    final db = await _db.database;
    return await db.update(
      'loans',
      loan.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  /// ثبت یک قسط (افزایش paid_installments)
  Future<void> recordInstallmentPayment(int loanId) async {
    final loan = await getById(loanId);
    if (loan == null) return;
    final newPaid = loan.paidInstallments + 1;
    final stillActive = newPaid < loan.totalInstallments;
    await update(
      loan.copyWith(
        paidInstallments: newPaid,
        isActive: stillActive,
        endDate: stillActive ? null : DateTime.now().toIso8601String(),
      ),
    );
  }

  /// محاسبه جمع اقساط ماهانه برای یک کارمند (وام‌های فعال)
  Future<double> getMonthlyInstallmentTotal(int employeeId) async {
    final loans = await getByEmployee(employeeId, onlyActive: true);
    double total = 0;
    for (final loan in loans) {
      total += loan.installmentAmount;
    }
    return total;
  }

  /// لیست وام‌های فعال یک کارمند با مبلغ قسط هر کدام
  Future<List<Loan>> getActiveLoansForEmployee(int employeeId) async {
    return await getByEmployee(employeeId, onlyActive: true);
  }
}
