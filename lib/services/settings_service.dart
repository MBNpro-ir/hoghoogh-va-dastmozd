import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';
import 'sync_service.dart';

class SettingsService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<AppSettings> getCurrentSettings({int? year}) async {
    final db = await _db.database;
    final targetYear = year ?? AppConstants.currentYear;
    final rows = await db.query(
      'app_settings',
      where: 'year = ? AND deleted_at IS NULL',
      whereArgs: [targetYear],
      limit: 1,
    );
    if (rows.isEmpty) {
      final defaultSettings = AppSettings(year: targetYear);
      final id = await db.insert(
        'app_settings',
        defaultSettings.toMap()..remove('id'),
      );
      await _sync.markUpsert('app_settings', id);
      return defaultSettings;
    }
    return AppSettings.fromMap(rows.first);
  }

  Future<int> update(AppSettings settings) async {
    final db = await _db.database;
    final map = settings.toMap()..remove('id');
    final result = settings.id != null
        ? await db.update(
            'app_settings',
            map,
            where: 'id = ? AND deleted_at IS NULL',
            whereArgs: [settings.id],
          )
        : await db.update(
            'app_settings',
            map,
            where: 'year = ? AND deleted_at IS NULL',
            whereArgs: [settings.year],
          );
    final id = settings.id ?? await _idForYear(settings.year);
    if (id != null) await _sync.markUpsert('app_settings', id);
    return result;
  }

  Future<void> resetToDefaults({int? year}) async {
    final db = await _db.database;
    final targetYear = year ?? AppConstants.currentYear;
    final defaults = AppSettings(year: targetYear).toMap()..remove('id');
    final existingId = await _idForYear(targetYear);
    if (existingId == null) {
      final id = await db.insert('app_settings', defaults);
      await _sync.markUpsert('app_settings', id);
      return;
    }
    await db.update(
      'app_settings',
      defaults,
      where: 'id = ?',
      whereArgs: [existingId],
    );
    await _sync.markUpsert('app_settings', existingId);
  }

  Future<int?> _idForYear(int year) async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      columns: ['id'],
      where: 'year = ? AND deleted_at IS NULL',
      whereArgs: [year],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int?;
  }
}
