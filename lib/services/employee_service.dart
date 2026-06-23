import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/employee.dart';
import 'sync_service.dart';

/// سرویس مدیریت کارمندان
class EmployeeService {
  static const _uuid = Uuid();

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

  Future<List<int>> insertMany(
    List<Employee> employees, {
    bool sync = true,
  }) async {
    if (employees.isEmpty) return const [];
    final db = await _db.database;
    final existingRows = await db.query(
      'employees',
      columns: ['personnel_code'],
      where: 'deleted_at IS NULL',
    );
    final existingCodes = existingRows
        .map((row) => (row['personnel_code'] as num).toInt())
        .toSet();
    final incomingCodes = <int>{};
    for (final employee in employees) {
      if (existingCodes.contains(employee.personnelCode) ||
          !incomingCodes.add(employee.personnelCode)) {
        throw ArgumentError('کد پرسنلی ${employee.personnelCode} تکراری است');
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final ids = await db.transaction<List<int>>((txn) async {
      final insertedIds = <int>[];
      for (final employee in employees) {
        final values = employee.toMap()
          ..remove('id')
          ..addAll({
            'sync_id': _uuid.v4(),
            'updated_at': now,
            'deleted_at': null,
            'sync_state': 'pending',
          });
        insertedIds.add(await txn.insert('employees', values));
      }
      return insertedIds;
    });
    if (sync) await _sync.syncNow(silent: true);
    return ids;
  }

  Future<int> update(Employee employee, {bool sync = true}) async {
    final db = await _db.database;
    final result = await db.update(
      'employees',
      employee.toMap()..remove('id'),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [employee.id],
    );
    if (employee.id != null) {
      await _sync.markUpsert('employees', employee.id!, schedule: false);
      if (sync) await _sync.syncNow(silent: true);
    }
    return result;
  }

  Future<int> delete(int id, {bool sync = true}) async {
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
    final advanceRows = await db.query(
      'advances',
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
    for (final row in advanceRows) {
      final childId = row['id'] as int?;
      if (childId != null) {
        await _sync.markDelete('advances', childId, schedule: false);
      }
    }
    final result = await _sync.markDelete('employees', id, schedule: false);
    if (sync) await _sync.syncNow(silent: true);
    return result;
  }

  Future<void> applyBatchChanges({
    required List<Employee> newEmployees,
    required List<Employee> updatedEmployees,
    required Set<int> deletedIds,
  }) async {
    for (final id in deletedIds) {
      await delete(id, sync: false);
    }
    for (final employee in updatedEmployees) {
      await update(employee, sync: false);
    }
    await insertMany(newEmployees, sync: false);
    await _sync.syncNow(silent: true);
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
