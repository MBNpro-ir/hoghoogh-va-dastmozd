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
      where: onlyActive ? 'is_active = ?' : null,
      whereArgs: onlyActive ? [1] : null,
      orderBy: 'personnel_code ASC',
    );
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'employees',
      where: 'id = ?',
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
      where: 'personnel_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<int> insert(Employee employee) async {
    final db = await _db.database;
    final id = await db.insert('employees', employee.toMap()..remove('id'));
    await _sync.enqueue(
      entity: 'employees',
      payload: employee.copyWith(id: id).toMap(),
    );
    return id;
  }

  Future<int> update(Employee employee) async {
    final db = await _db.database;
    final result = await db.update(
      'employees',
      employee.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
    await _sync.enqueue(entity: 'employees', payload: employee.toMap());
    return result;
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _sync.enqueue(
      entity: 'employees',
      payload: {'id': id, 'local_id': id},
      operation: 'delete',
    );
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
