import '../database/database_helper.dart';
import '../models/salary_draft.dart';
import 'sync_service.dart';

class SalaryDraftService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<SalaryDraft?> getForPeriod(int employeeId, int year, int month) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_drafts',
      where:
          'employee_id = ? AND year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [employeeId, year, month],
      limit: 1,
    );
    return rows.isEmpty ? null : SalaryDraft.fromMap(rows.first);
  }

  Future<SalaryDraft?> getLatestBefore(
    int employeeId,
    int year,
    int month,
  ) async {
    final db = await _db.database;
    final period = year * 100 + month;
    final rows = await db.query(
      'salary_drafts',
      where:
          'employee_id = ? AND (year * 100 + month) < ? AND deleted_at IS NULL',
      whereArgs: [employeeId, period],
      orderBy: 'year DESC, month DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : SalaryDraft.fromMap(rows.first);
  }

  Future<int> upsert(SalaryDraft draft) async {
    final db = await _db.database;
    final existing = await getForPeriod(
      draft.employeeId,
      draft.year,
      draft.month,
    );
    final values = draft.toMap()..remove('id');
    final id = existing?.id;
    if (id == null) {
      final insertedId = await db.insert('salary_drafts', values);
      await _sync.markUpsert('salary_drafts', insertedId);
      return insertedId;
    }
    await db.update('salary_drafts', values, where: 'id = ?', whereArgs: [id]);
    await _sync.markUpsert('salary_drafts', id);
    return id;
  }

  Future<void> markEmployeeDraftsDeleted(int employeeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'salary_drafts',
      columns: ['id'],
      where: 'employee_id = ? AND deleted_at IS NULL',
      whereArgs: [employeeId],
    );
    for (final row in rows) {
      final id = row['id'] as int?;
      if (id != null) {
        await _sync.markDelete('salary_drafts', id, schedule: false);
      }
    }
  }
}
