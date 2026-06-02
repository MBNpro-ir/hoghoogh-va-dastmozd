import '../database/database_helper.dart';
import '../models/employee.dart';

/// سرویس مدیریت کارمندان
class EmployeeService {
  final _db = DatabaseHelper.instance;

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
    return await db.insert('employees', employee.toMap()..remove('id'));
  }

  Future<int> update(Employee employee) async {
    final db = await _db.database;
    return await db.update(
      'employees',
      employee.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
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
