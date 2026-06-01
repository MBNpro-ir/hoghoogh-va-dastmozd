import '../database/database_helper.dart';
import '../models/salary_record.dart';

/// سرویس مدیریت فیش‌های حقوق
class SalaryService {
  final _db = DatabaseHelper.instance;

  Future<List<SalaryRecord>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('salary_records',
        orderBy: 'year DESC, month DESC, employee_id ASC');
    return rows.map(SalaryRecord.fromMap).toList();
  }

  Future<List<SalaryRecord>> getByYearMonth(int year, int month) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'employee_id ASC',
    );
    return rows.map(SalaryRecord.fromMap).toList();
  }

  Future<List<SalaryRecord>> getByEmployee(int employeeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'year DESC, month DESC',
    );
    return rows.map(SalaryRecord.fromMap).toList();
  }

  Future<SalaryRecord?> getByEmployeeYearMonth(int employeeId, int year, int month) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_records',
      where: 'employee_id = ? AND year = ? AND month = ?',
      whereArgs: [employeeId, year, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SalaryRecord.fromMap(rows.first);
  }

  Future<int> insertOrUpdate(SalaryRecord record) async {
    final db = await _db.database;
    final existing = await getByEmployeeYearMonth(record.employeeId, record.year, record.month);
    if (existing != null) {
      final map = record.toMap()..remove('id');
      await db.update(
        'salary_records',
        map,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    } else {
      final map = record.toMap()..remove('id');
      return await db.insert('salary_records', map);
    }
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('salary_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByEmployeeYearMonth(int employeeId, int year, int month) async {
    final db = await _db.database;
    return await db.delete(
      'salary_records',
      where: 'employee_id = ? AND year = ? AND month = ?',
      whereArgs: [employeeId, year, month],
    );
  }

  /// لیست ماه‌هایی که فیش حقوق ثبت شده
  Future<List<(int year, int month)>> getRecordedMonths() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT year, month FROM salary_records ORDER BY year DESC, month DESC');
    return rows.map((r) => (r['year'] as int, r['month'] as int)).toList();
  }
}
