import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/loan.dart';
import '../models/salary_record.dart';
import 'api_client.dart';

class SyncService {
  static const _pendingKey = 'hvm_sync_pending_v1';
  static const _cursorKey = 'hvm_sync_cursor_v1';
  final _api = ApiClient();
  final _db = DatabaseHelper.instance;

  Future<void> enqueue({
    required String entity,
    required Map<String, dynamic> payload,
    String operation = 'upsert',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _pending(prefs);
    pending.add({
      'entity': entity,
      'operation': operation,
      'payload': payload,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_pendingKey, jsonEncode(pending));
    unawaitedFlush();
  }

  Future<void> unawaitedFlush() async {
    try {
      await flush();
    } catch (_) {}
  }

  Future<void> flush() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _pending(prefs);
    if (pending.isEmpty) return;
    final response = await _api.post('/api/sync/push', {'operations': pending});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await prefs.setString(_pendingKey, '[]');
    }
  }

  Future<void> pull() async {
    final prefs = await SharedPreferences.getInstance();
    var cursor = prefs.getInt(_cursorKey) ?? 0;
    final response = await _api.get('/api/sync/pull?cursor=$cursor');
    if (response.statusCode < 200 || response.statusCode >= 300) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final events = List<Map<String, dynamic>>.from(
      body['events'] as List? ?? const [],
    );
    if (events.isEmpty) return;
    final db = await _db.database;
    for (final event in events) {
      final payload = Map<String, dynamic>.from(
        event['payload'] as Map? ?? const {},
      );
      final operation = event['operation'] as String? ?? 'upsert';
      switch (event['entity']) {
        case 'employees':
          if (operation == 'delete') {
            await db.delete(
              'employees',
              where: 'id = ?',
              whereArgs: [_localId(payload)],
            );
          } else {
            await _upsert(db, 'employees', _employeePayload(payload));
          }
          break;
        case 'loans':
          if (operation == 'delete') {
            await db.delete(
              'loans',
              where: 'id = ?',
              whereArgs: [_localId(payload)],
            );
          } else {
            await _upsert(db, 'loans', _loanPayload(payload));
          }
          break;
        case 'salary_records':
          if (operation == 'delete') {
            await db.delete(
              'salary_records',
              where: 'id = ?',
              whereArgs: [_localId(payload)],
            );
          } else {
            await _upsert(db, 'salary_records', _salaryPayload(payload));
          }
          break;
        case 'app_settings':
          await _upsert(db, 'app_settings', _settingsPayload(payload));
          break;
      }
      cursor = event['cursor'] as int? ?? cursor;
    }
    await prefs.setInt(_cursorKey, cursor);
  }

  List<Map<String, dynamic>> _pending(SharedPreferences prefs) {
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _upsert(
    dynamic db,
    String table,
    Map<String, dynamic> payload,
  ) async {
    final id = payload.remove('id') as int?;
    if (id == null) {
      await db.insert(table, payload);
    } else {
      final exists = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (exists.isEmpty) {
        await db.insert(table, payload);
      } else {
        await db.update(table, payload, where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  int _localId(Map<String, dynamic> payload) =>
      (payload['local_id'] as num?)?.toInt() ??
      (payload['id'] as num?)?.toInt() ??
      0;

  Map<String, dynamic> _employeePayload(Map<String, dynamic> payload) =>
      Employee.fromMap({
        ...payload,
        'id': _localId(payload),
        'has_prior_experience': payload['has_prior_experience'] is bool
            ? (payload['has_prior_experience'] as bool ? 1 : 0)
            : payload['has_prior_experience'],
        'is_married': payload['is_married'] is bool
            ? (payload['is_married'] as bool ? 1 : 0)
            : payload['is_married'],
        'is_active': payload['is_active'] is bool
            ? (payload['is_active'] as bool ? 1 : 0)
            : payload['is_active'],
        'hard_and_harmful_job': payload['hard_and_harmful_job'] is bool
            ? (payload['hard_and_harmful_job'] as bool ? 1 : 0)
            : payload['hard_and_harmful_job'],
      }).toMap()..remove('id');

  Map<String, dynamic> _loanPayload(Map<String, dynamic> payload) =>
      Loan.fromMap({
        ...payload,
        'id': _localId(payload),
        'is_active': payload['is_active'] is bool
            ? (payload['is_active'] as bool ? 1 : 0)
            : payload['is_active'],
      }).toMap()..remove('id');

  Map<String, dynamic> _salaryPayload(Map<String, dynamic> payload) =>
      SalaryRecord.fromMap({
        ...payload,
        'id': _localId(payload),
        'include_leave_in_payslip': payload['include_leave_in_payslip'] is bool
            ? (payload['include_leave_in_payslip'] as bool ? 1 : 0)
            : payload['include_leave_in_payslip'],
      }).toMap()..remove('id');

  Map<String, dynamic> _settingsPayload(Map<String, dynamic> payload) =>
      AppSettings.fromMap(payload).toMap()..remove('id');
}

void unawaited(Future<void> future) {}
