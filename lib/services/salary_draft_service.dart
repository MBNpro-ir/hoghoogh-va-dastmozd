import '../database/database_helper.dart';
import '../models/salary_draft.dart';
import '../utils/business_validation.dart';
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

  Future<int> upsert(SalaryDraft draft, {bool scheduleSync = true}) async {
    BusinessValidation.salaryDraft(draft);
    final db = await _db.database;
    final matchingRows = await db.query(
      'salary_drafts',
      columns: ['id'],
      where: 'employee_id = ? AND year = ? AND month = ?',
      whereArgs: [draft.employeeId, draft.year, draft.month],
      limit: 1,
    );
    final values = draft.toMap()..remove('id');
    final id = matchingRows.isEmpty
        ? null
        : (matchingRows.first['id'] as num?)?.toInt();
    if (id == null) {
      final insertedId = await db.insert('salary_drafts', values);
      await _sync.markUpsert(
        'salary_drafts',
        insertedId,
        schedule: scheduleSync,
      );
      return insertedId;
    }
    await db.update('salary_drafts', values, where: 'id = ?', whereArgs: [id]);
    await _sync.markUpsert('salary_drafts', id, schedule: scheduleSync);
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
