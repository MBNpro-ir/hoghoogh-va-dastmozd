import '../database/database_helper.dart';
import '../models/employee.dart';
import 'sync_service.dart';

/// سرویس مدیریت کارمندان
class EmployeeService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<List<Employee>> getAll({bool onlyActive = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'employees',
      where: onlyActive
          ? 'deleted_at IS NULL AND is_active = ?'
          : 'deleted_at IS NULL',
      whereArgs: onlyActive ? [1] : null,
      orderBy: 'personnel_code ASC',
    );
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'employees',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<Employee?> getByPersonnelCode(int code) async {
    final db = await _db.database;
    final rows = await db.query(
      'employees',
      where: 'personnel_code = ? AND deleted_at IS NULL',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<int> insert(Employee employee) async {
    final db = await _db.database;
    final id = await db.insert('employees', employee.toMap()..remove('id'));
    await _sync.markUpsert('employees', id, schedule: false);
    await _sync.syncNow(silent: true);
    return id;
  }

  Future<int> update(Employee employee) async {
    final db = await _db.database;
    final result = await db.update(
      'employees',
      employee.toMap()..remove('id'),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [employee.id],
    );
    if (employee.id != null) {
      await _sync.markUpsert('employees', employee.id!, schedule: false);
      await _sync.syncNow(silent: true);
    }
    return result;
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    final salaryRows = await db.query(
      'salary_records',
      columns: ['id'],
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    final loanRows = await db.query(
      'loans',
      columns: ['id'],
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    for (final row in salaryRows) {
      final childId = row['id'] as int?;
      if (childId != null) {
        await _sync.markDelete('salary_records', childId, schedule: false);
      }
    }
    for (final row in loanRows) {
      final childId = row['id'] as int?;
      if (childId != null) {
        await _sync.markDelete('loans', childId, schedule: false);
      }
    }
    final result = await _sync.markDelete('employees', id, schedule: false);
    await _sync.syncNow(silent: true);
    return result;
  }

  Future<int> getNextPersonnelCode() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MAX(personnel_code) as max_code FROM employees',
    );
    final max = result.first['max_code'] as int? ?? 0;
    return max + 1;
  }
}
