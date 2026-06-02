import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

/// سرویس تنظیمات برنامه
class SettingsService {
  final _db = DatabaseHelper.instance;

  /// دریافت تنظیمات سال جاری (یا 1405 پیش‌فرض)
  Future<AppSettings> getCurrentSettings({int? year}) async {
    final db = await _db.database;
    final targetYear = year ?? AppConstants.currentYear;
    final rows = await db.query(
      'app_settings',
      where: 'year = ?',
      whereArgs: [targetYear],
      limit: 1,
    );
    if (rows.isEmpty) {
      // اگر هنوز ایجاد نشده، ایجاد کنیم
      final defaultSettings = AppSettings(year: targetYear);
      await db.insert('app_settings', defaultSettings.toMap()..remove('id'));
      return defaultSettings;
    }
    return AppSettings.fromMap(rows.first);
  }

  Future<int> update(AppSettings settings) async {
    final db = await _db.database;
    final map = settings.toMap()..remove('id');
    if (settings.id != null) {
      return await db.update(
        'app_settings',
        map,
        where: 'id = ?',
        whereArgs: [settings.id],
      );
    } else {
      return await db.update(
        'app_settings',
        map,
        where: 'year = ?',
        whereArgs: [settings.year],
      );
    }
  }

  Future<void> resetToDefaults({int? year}) async {
    final db = await _db.database;
    final targetYear = year ?? AppConstants.currentYear;
    await db.delete('app_settings', where: 'year = ?', whereArgs: [targetYear]);
    await db.insert(
      'app_settings',
      AppSettings(year: targetYear).toMap()..remove('id'),
    );
  }
}
