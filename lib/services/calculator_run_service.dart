import 'dart:convert';

import '../database/database_helper.dart';
import '../models/calculator_run.dart';
import '../utils/business_validation.dart';
import 'sync_service.dart';

class CalculatorRunService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();

  Future<List<CalculatorRun>> getRecent({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      'calculator_runs',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(CalculatorRun.fromMap).toList();
  }

  Future<List<CalculatorRun>> getByCalculator(
    String calculatorId, {
    int limit = 50,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'calculator_runs',
      where: 'calculator_id = ? AND deleted_at IS NULL',
      whereArgs: [calculatorId],
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(CalculatorRun.fromMap).toList();
  }

  Future<int> insert(CalculatorRun run) async {
    _validate(run);
    final db = await _db.database;
    final map = run.toMap()
      ..remove('id')
      ..remove('server_updated_at');
    final id = await db.insert('calculator_runs', map);
    await _sync.markUpsert('calculator_runs', id);
    return id;
  }

  Future<int> delete(int id) async {
    return _sync.markDelete('calculator_runs', id);
  }

  void _validate(CalculatorRun run) {
    if (run.calculatorId.trim().isEmpty ||
        run.year < 1200 ||
        run.year > 1700 ||
        (run.month != null && (run.month! < 1 || run.month! > 12))) {
      throw const BusinessValidationException(
        'اطلاعات محاسبه معتبر نیست. سال، ماه و نوع محاسبه را بررسی کنید.',
      );
    }
    for (final value in [run.inputsJson, run.outputsJson, run.sourceUrlsJson]) {
      try {
        jsonDecode(value);
      } catch (_) {
        throw const BusinessValidationException(
          'جزئیات محاسبه معتبر نیست و ذخیره نشد.',
        );
      }
    }
  }
}
