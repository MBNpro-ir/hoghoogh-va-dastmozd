import '../database/database_helper.dart';
import '../models/loan.dart';
import 'sync_service.dart';

/// سرویس مدیریت وام و اقساط
class LoanService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<List<Loan>> getAll({bool onlyActive = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'loans',
      where: onlyActive
          ? 'deleted_at IS NULL AND is_active = ?'
          : 'deleted_at IS NULL',
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
        ? 'employee_id = ? AND deleted_at IS NULL AND is_active = ?'
        : 'employee_id = ? AND deleted_at IS NULL';
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
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  Future<int> insert(Loan loan) async {
    final db = await _db.database;
    final id = await db.insert('loans', loan.toMap()..remove('id'));
    await _sync.markUpsert('loans', id, schedule: false);
    await _sync.syncNow(silent: true);
    return id;
  }

  Future<int> update(Loan loan) async {
    final db = await _db.database;
    final result = await db.update(
      'loans',
      loan.toMap()..remove('id'),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [loan.id],
    );
    if (loan.id != null) {
      await _sync.markUpsert('loans', loan.id!, schedule: false);
      await _sync.syncNow(silent: true);
    }
    return result;
  }

  Future<int> delete(int id) async {
    final result = await _sync.markDelete('loans', id, schedule: false);
    await _sync.syncNow(silent: true);
    return result;
  }

  /// ثبت یک قسط (افزایش paid_installments)
  Future<void> recordInstallmentPayment(int loanId) async {
    final loan = await getById(loanId);
    if (loan == null) return;
    final newPaid = (loan.paidInstallments + loan.nextInstallmentStep)
        .clamp(0.0, loan.totalInstallments)
        .toDouble();
    final newRemaining = (loan.amount - loan.installmentAmount * newPaid)
        .clamp(0.0, double.infinity)
        .toDouble();
    final stillActive = newPaid < loan.totalInstallments && newRemaining > 0;
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
      total += loan.nextInstallmentAmount;
    }
    return total;
  }

  /// لیست وام‌های فعال یک کارمند با مبلغ قسط هر کدام
  Future<List<Loan>> getActiveLoansForEmployee(int employeeId) async {
    return await getByEmployee(employeeId, onlyActive: true);
  }
}
