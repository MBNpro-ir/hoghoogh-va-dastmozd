import '../database/database_helper.dart';
import '../models/advance_payment.dart';
import '../utils/business_validation.dart';
import 'sync_service.dart';

class AdvanceService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<List<AdvancePayment>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'advances',
      where: 'deleted_at IS NULL',
      orderBy: 'payment_date DESC, id DESC',
    );
    return rows.map(AdvancePayment.fromMap).toList();
  }

  Future<List<AdvancePayment>> getByEmployee(int employeeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'advances',
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [employeeId],
      orderBy: 'payment_date DESC, id DESC',
    );
    return rows.map(AdvancePayment.fromMap).toList();
  }

  Future<List<AdvancePayment>> getByEmployeeYearMonth(
    int employeeId,
    int year,
    int month,
  ) async {
    final db = await _db.database;
    final prefix = '$year/${month.toString().padLeft(2, '0')}/';
    final rows = await db.query(
      'advances',
      where: 'employee_id = ? AND payment_date LIKE ? AND deleted_at IS NULL',
      whereArgs: [employeeId, '$prefix%'],
      orderBy: 'payment_date ASC, id ASC',
    );
    return rows.map(AdvancePayment.fromMap).toList();
  }

  Future<double> totalForEmployeeYearMonth(
    int employeeId,
    int year,
    int month,
  ) async {
    final advances = await getByEmployeeYearMonth(employeeId, year, month);
    return advances.fold<double>(0, (sum, item) => sum + item.amount);
  }

  Future<int> insert(AdvancePayment advance) async {
    BusinessValidation.advance(advance);
    final db = await _db.database;
    final id = await db.insert('advances', advance.toMap()..remove('id'));
    await _sync.markUpsert('advances', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
    return id;
  }

  Future<int> update(AdvancePayment advance) async {
    if (advance.id == null) {
      throw ArgumentError('Advance id is required for update.');
    }
    BusinessValidation.advance(advance);
    final db = await _db.database;
    final result = await db.update(
      'advances',
      advance.toMap()..remove('id'),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [advance.id],
    );
    if (result == 0) {
      throw const BusinessValidationException(
        'این مساعده قبلاً حذف شده است. فهرست را تازه کنید.',
      );
    }
    await _sync.markUpsert('advances', advance.id!, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
    return result;
  }

  Future<int> delete(int id) async {
    final result = await _sync.markDelete('advances', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
    return result;
  }
}
