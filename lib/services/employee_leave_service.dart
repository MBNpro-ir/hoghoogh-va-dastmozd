import '../database/database_helper.dart';
import '../models/employee_leave.dart';
import '../utils/business_validation.dart';
import 'sync_service.dart';

class EmployeeLeaveService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<List<EmployeeLeave>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'leaves',
      where: 'deleted_at IS NULL',
      orderBy: 'from_date DESC, id DESC',
    );
    return rows.map(EmployeeLeave.fromMap).toList();
  }

  Future<List<EmployeeLeave>> getByEmployee(int employeeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'leaves',
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [employeeId],
      orderBy: 'from_date DESC, id DESC',
    );
    return rows.map(EmployeeLeave.fromMap).toList();
  }

  Future<List<EmployeeLeave>> getApprovedByEmployeeYearMonth(
    int employeeId,
    int year,
    int month,
  ) async {
    final db = await _db.database;
    final prefix = '$year/${month.toString().padLeft(2, '0')}/';
    final rows = await db.query(
      'leaves',
      where: '''
        employee_id = ?
        AND status = ?
        AND from_date LIKE ?
        AND deleted_at IS NULL
      ''',
      whereArgs: [employeeId, EmployeeLeave.statusApproved, '$prefix%'],
      orderBy: 'from_date ASC, id ASC',
    );
    return rows.map(EmployeeLeave.fromMap).toList();
  }

  Future<({double annual, double sick})> totalsForEmployeeYearMonth(
    int employeeId,
    int year,
    int month,
  ) async {
    final leaves = await getApprovedByEmployeeYearMonth(
      employeeId,
      year,
      month,
    );
    var annual = 0.0;
    var sick = 0.0;
    for (final leave in leaves) {
      if (leave.isSick) {
        sick += leave.days;
      } else {
        annual += leave.days;
      }
    }
    return (annual: annual, sick: sick);
  }

  Future<int> insert(EmployeeLeave leave) async {
    BusinessValidation.leave(leave);
    final db = await _db.database;
    final id = await db.insert('leaves', leave.toMap()..remove('id'));
    await _sync.markUpsert('leaves', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
    return id;
  }

  Future<int> update(EmployeeLeave leave) async {
    if (leave.id == null) {
      throw ArgumentError('Leave id is required for update.');
    }
    BusinessValidation.leave(leave);
    final db = await _db.database;
    final result = await db.update(
      'leaves',
      leave.toMap()..remove('id'),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [leave.id],
    );
    if (result == 0) {
      throw const BusinessValidationException(
        'این مرخصی قبلاً حذف شده است. فهرست را تازه کنید.',
      );
    }
    await _sync.markUpsert('leaves', leave.id!, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
    return result;
  }

  Future<int> delete(int id) async {
    final result = await _sync.markDelete('leaves', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
    return result;
  }
}
