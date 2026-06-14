import '../database/database_helper.dart';
import '../models/salary_record.dart';
import 'sync_service.dart';

/// سرویس مدیریت فیش‌های حقوق
class SalaryService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<List<SalaryRecord>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where: 'deleted_at IS NULL',
      orderBy: 'year DESC, month DESC, employee_id ASC',
    );
    return rows.map(SalaryRecord.fromMap).toList();
  }

  Future<List<SalaryRecord>> getByYearMonth(int year, int month) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where: 'year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [year, month],
      orderBy: 'employee_id ASC',
    );
    return rows.map(SalaryRecord.fromMap).toList();
  }

  Future<List<SalaryRecord>> getByEmployee(int employeeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [employeeId],
      orderBy: 'year DESC, month DESC',
    );
    return rows.map(SalaryRecord.fromMap).toList();
  }

  Future<SalaryRecord?> getByEmployeeYearMonth(
    int employeeId,
    int year,
    int month,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where:
          'employee_id = ? AND year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [employeeId, year, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SalaryRecord.fromMap(rows.first);
  }

  Future<int> insertOrUpdate(SalaryRecord record) async {
    final db = await _db.database;
    final existing = await getByEmployeeYearMonth(
      record.employeeId,
      record.year,
      record.month,
    );
    if (existing != null) {
      final map = record.toMap()..remove('id');
      await db.update(
        'salary_records',
        map,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      await _sync.markUpsert('salary_records', existing.id!, schedule: false);
      await _sync.syncNow(silent: true);
      return existing.id!;
    } else {
      final map = record.toMap()..remove('id');
      final id = await db.insert('salary_records', map);
      await _sync.markUpsert('salary_records', id, schedule: false);
      await _sync.syncNow(silent: true);
      return id;
    }
  }

  Future<int> update(SalaryRecord record) async {
    if (record.id == null) {
      throw ArgumentError('Salary record id is required for update.');
    }
    final db = await _db.database;
    final map = record.toMap()..remove('id');
    final result = await db.update(
      'salary_records',
      map,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [record.id!],
    );
    await _sync.markUpsert('salary_records', record.id!, schedule: false);
    await _sync.syncNow(silent: true);
    return result;
  }

  Future<int> delete(int id) async {
    final result = await _sync.markDelete(
      'salary_records',
      id,
      schedule: false,
    );
    await _sync.syncNow(silent: true);
    return result;
  }

  Future<int> deleteByEmployeeYearMonth(
    int employeeId,
    int year,
    int month,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      columns: ['id'],
      where:
          'employee_id = ? AND year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [employeeId, year, month],
    );
    var changed = 0;
    for (final row in rows) {
      final id = row['id'] as int?;
      if (id != null) {
        changed += await _sync.markDelete(
          'salary_records',
          id,
          schedule: false,
        );
      }
    }
    if (changed > 0) await _sync.syncNow(silent: true);
    return changed;
  }

  /// خلاصه پرداخت‌های یک ماه مشخص
  Future<({double totalEarnings, double employerInsurance, double tax})>
  getMonthlySummary(int year, int month) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT '
      'COALESCE(SUM(total_earnings), 0) AS total_earnings, '
      'COALESCE(SUM(insurance_base * 0.20), 0) AS employer_insurance, '
      'COALESCE(SUM(tax), 0) AS tax '
      'FROM salary_records WHERE year = ? AND month = ? AND deleted_at IS NULL',
      [year, month],
    );
    final row = rows.first;
    return (
      totalEarnings: (row['total_earnings'] as num).toDouble(),
      employerInsurance: (row['employer_insurance'] as num).toDouble(),
      tax: (row['tax'] as num).toDouble(),
    );
  }

  /// لیست ماه‌هایی که فیش حقوق ثبت شده
  Future<List<(int year, int month)>> getRecordedMonths() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT year, month FROM salary_records WHERE deleted_at IS NULL ORDER BY year DESC, month DESC',
    );
    return rows.map((r) => (r['year'] as int, r['month'] as int)).toList();
  }
}
