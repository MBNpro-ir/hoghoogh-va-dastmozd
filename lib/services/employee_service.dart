import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/employee.dart';
import '../utils/business_validation.dart';
import 'salary_draft_service.dart';
import 'sync_service.dart';

/// سرویس مدیریت کارمندان
class EmployeeService {
  static const _uuid = Uuid();

  final _db = DatabaseHelper.instance;
  final _sync = SyncService();
  final _drafts = SalaryDraftService();

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

  Future<Employee?> getByNationalId(String nationalId) async {
    final db = await _db.database;
    final rows = await db.query(
      'employees',
      where: 'national_id = ? AND deleted_at IS NULL',
      whereArgs: [nationalId.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<int> insert(Employee employee) async {
    BusinessValidation.employee(employee);
    final db = await _db.database;
    final codeRows = await db.query(
      'employees',
      columns: ['deleted_at'],
      where: 'personnel_code = ?',
      whereArgs: [employee.personnelCode],
      limit: 1,
    );
    if (codeRows.isNotEmpty) {
      final deleting = codeRows.first['deleted_at'] != null;
      throw BusinessValidationException(
        deleting
            ? 'این کد پرسنلی در صف حذف است. ابتدا همگام‌سازی را کامل کنید.'
            : 'این کد پرسنلی قبلاً ثبت شده است.',
      );
    }
    if (await getByNationalId(employee.nationalId) != null) {
      throw const BusinessValidationException('این کد ملی قبلاً ثبت شده است.');
    }
    final id = await db.insert('employees', employee.toMap()..remove('id'));
    await _sync.markUpsert('employees', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
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
      columns: ['personnel_code', 'national_id'],
    );
    final existingCodes = existingRows
        .map((row) => (row['personnel_code'] as num).toInt())
        .toSet();
    final existingNationalIds = existingRows
        .map((row) => row['national_id']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    final incomingCodes = <int>{};
    final incomingNationalIds = <String>{};
    for (final employee in employees) {
      BusinessValidation.employee(employee);
      if (existingCodes.contains(employee.personnelCode) ||
          !incomingCodes.add(employee.personnelCode)) {
        throw ArgumentError('کد پرسنلی ${employee.personnelCode} تکراری است');
      }
      if (existingNationalIds.contains(employee.nationalId) ||
          !incomingNationalIds.add(employee.nationalId)) {
        throw ArgumentError('کد ملی ${employee.nationalId} تکراری است');
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
    if (sync) {
      await _sync.syncNow(silent: true, throwOnServerError: true);
    }
    return ids;
  }

  Future<int> update(Employee employee, {bool sync = true}) async {
    if (employee.id == null) {
      throw const BusinessValidationException(
        'کارمند موردنظر برای ویرایش پیدا نشد.',
      );
    }
    BusinessValidation.employee(employee);
    final db = await _db.database;
    final result = await db.update(
      'employees',
      employee.toMap()..remove('id'),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [employee.id],
    );
    if (result == 0) {
      throw const BusinessValidationException(
        'این کارمند قبلاً حذف شده است. فهرست را تازه کنید.',
      );
    }
    await _sync.markUpsert('employees', employee.id!, schedule: false);
    if (sync) {
      await _sync.syncNow(silent: true, throwOnServerError: true);
    }
    return result;
  }

  Future<int> delete(int id, {bool sync = true}) async {
    final db = await _db.database;
    await _drafts.markEmployeeDraftsDeleted(id);
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
    final leaveRows = await db.query(
      'leaves',
      columns: ['id'],
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    final paymentRows = await db.query(
      'salary_payment_statuses',
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
    for (final row in leaveRows) {
      final childId = row['id'] as int?;
      if (childId != null) {
        await _sync.markDelete('leaves', childId, schedule: false);
      }
    }
    for (final row in paymentRows) {
      final childId = row['id'] as int?;
      if (childId != null) {
        await _sync.markDelete(
          'salary_payment_statuses',
          childId,
          schedule: false,
        );
      }
    }
    final result = await _sync.markDelete('employees', id, schedule: false);
    if (sync) {
      await _sync.syncNow(silent: true, throwOnServerError: true);
    }
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
    await _sync.syncNow(silent: true, throwOnServerError: true);
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
