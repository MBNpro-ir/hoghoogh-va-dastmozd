import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/loan.dart';
import '../models/salary_record.dart';
import 'api_client.dart';

enum SyncPhase { idle, syncing, synced, offline, error }

class SyncSnapshot {
  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final DateTime? lastUnsentAt;
  final String? message;

  const SyncSnapshot({
    required this.phase,
    required this.pendingCount,
    this.lastSyncedAt,
    this.lastUnsentAt,
    this.message,
  });

  factory SyncSnapshot.initial() =>
      const SyncSnapshot(phase: SyncPhase.idle, pendingCount: 0);

  SyncSnapshot copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    DateTime? lastUnsentAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncSnapshot(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastUnsentAt: lastUnsentAt ?? this.lastUnsentAt,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class SyncService {
  SyncService._();
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;

  static const _cursorKey = 'hvm_sync_cursor_v2';
  static const _lastSyncedKey = 'hvm_sync_last_synced_v2';
  static const _bootstrapImportedKey = 'hvm_bootstrap_imported_v2';
  static const _autoSyncInterval = Duration(seconds: 5);
  static const _uuid = Uuid();

  static const trackedTables = <String>[
    'employees',
    'loans',
    'salary_records',
    'app_settings',
  ];

  static const _upsertOrder = <String>[
    'employees',
    'app_settings',
    'loans',
    'salary_records',
  ];

  static const _deleteOrder = <String>[
    'salary_records',
    'loans',
    'employees',
    'app_settings',
  ];

  final ValueNotifier<SyncSnapshot> status = ValueNotifier<SyncSnapshot>(
    SyncSnapshot.initial(),
  );
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);
  final _api = ApiClient();
  final _db = DatabaseHelper.instance;
  bool _syncing = false;
  Timer? _debounce;
  Timer? _pollTimer;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_lastSyncedKey) ?? '');
    status.value = status.value.copyWith(
      pendingCount: await pendingCount(),
      lastSyncedAt: last,
      clearMessage: true,
    );
    await startAutoSync();
  }

  Future<void> startAutoSync() async {
    if (_pollTimer != null) return;
    if (!await _api.hasSession()) return;
    _pollTimer = Timer.periodic(_autoSyncInterval, (_) {
      unawaited(syncNow(silent: true));
    });
    unawaited(syncNow(silent: true));
  }

  void stopAutoSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> shouldShowBootstrapWizard() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_bootstrapImportedKey) == true) return false;
    return hasLocalBusinessData();
  }

  Future<void> skipBootstrapImport() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bootstrapImportedKey, true);
  }

  Future<bool> hasLocalBusinessData() async {
    final db = await _db.database;
    for (final table in ['employees', 'loans', 'salary_records']) {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM $table WHERE deleted_at IS NULL',
      );
      if ((rows.first['count'] as int? ?? 0) > 0) return true;
    }
    return false;
  }

  Future<int> pendingCount() async {
    final db = await _db.database;
    var count = 0;
    for (final table in trackedTables) {
      final rows = await db.rawQuery(
        "SELECT COUNT(*) AS count FROM $table WHERE sync_state IN ('pending', 'deleting')",
      );
      count += rows.first['count'] as int? ?? 0;
    }
    return count;
  }

  Future<void> markUpsert(String table, int id, {bool schedule = true}) async {
    await _ensureTrackedTable(table);
    final db = await _db.database;
    final now = _nowIso();
    await db.update(
      table,
      {
        'sync_id': await _syncIdFor(db, table, id),
        'updated_at': now,
        'deleted_at': null,
        'sync_state': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _refreshStatus(lastUnsentAt: DateTime.now().toUtc());
    if (schedule) scheduleSync();
  }

  Future<int> markDelete(String table, int id, {bool schedule = true}) async {
    await _ensureTrackedTable(table);
    final db = await _db.database;
    final now = _nowIso();
    final result = await db.update(
      table,
      {
        'sync_id': await _syncIdFor(db, table, id),
        'updated_at': now,
        'deleted_at': now,
        'sync_state': 'deleting',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _refreshStatus(lastUnsentAt: DateTime.now().toUtc());
    if (schedule) scheduleSync();
    return result;
  }

  void scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(syncNow(silent: true));
    });
  }

  Future<void> syncNow({bool silent = false}) async {
    if (_syncing) return;
    if (!await _api.hasSession()) {
      stopAutoSync();
      await _refreshStatus(phase: SyncPhase.idle);
      return;
    }
    _syncing = true;
    final previous = status.value;
    if (!silent) {
      status.value = previous.copyWith(phase: SyncPhase.syncing);
    } else {
      status.value = previous.copyWith(
        phase: previous.pendingCount > 0 ? SyncPhase.syncing : previous.phase,
      );
    }
    try {
      await _pushPending();
      final applied = await _pullRemote();
      if (applied > 0) _bumpDataVersion();
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.now().toUtc();
      await prefs.setString(_lastSyncedKey, last.toIso8601String());
      await _refreshStatus(phase: SyncPhase.synced, lastSyncedAt: last);
    } on ApiException catch (e) {
      final phase = e.statusCode == 0 ? SyncPhase.offline : SyncPhase.error;
      await _refreshStatus(phase: phase, message: e.message);
    } catch (e) {
      await _refreshStatus(phase: SyncPhase.offline, message: e.toString());
    } finally {
      _syncing = false;
    }
  }

  Future<void> pullLatest({bool silent = true}) async {
    if (_syncing) return;
    if (!await _api.hasSession()) {
      stopAutoSync();
      await _refreshStatus(phase: SyncPhase.idle);
      return;
    }
    _syncing = true;
    final previous = status.value;
    if (!silent) {
      status.value = previous.copyWith(phase: SyncPhase.syncing);
    }
    try {
      final applied = await _pullRemote();
      if (applied > 0) _bumpDataVersion();
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.now().toUtc();
      await prefs.setString(_lastSyncedKey, last.toIso8601String());
      await _refreshStatus(phase: SyncPhase.synced, lastSyncedAt: last);
    } on ApiException catch (e) {
      final phase = e.statusCode == 0 ? SyncPhase.offline : SyncPhase.error;
      await _refreshStatus(phase: phase, message: e.message);
    } catch (e) {
      await _refreshStatus(
        phase: SyncPhase.error,
        message: _friendlyLocalError(e),
      );
    } finally {
      _syncing = false;
    }
  }

  Future<void> bootstrapImport() async {
    if (!await _api.hasSession()) throw ApiException('Session required', 401);
    final db = await _db.database;
    final body = <String, dynamic>{};
    for (final table in trackedTables) {
      final rows = await db.query(
        table,
        where: 'deleted_at IS NULL',
        orderBy: table == 'employees'
            ? 'id ASC'
            : table == 'app_settings'
            ? 'year ASC'
            : 'id ASC',
      );
      final prepared = <Map<String, dynamic>>[];
      for (final row in rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        final syncId = await _syncIdFor(db, table, id);
        final payload = await _payloadFor(db, table, {
          ...row,
          'sync_id': syncId,
          'sync_state': 'pending',
        });
        prepared.add(payload);
        await db.update(
          table,
          {
            'sync_id': syncId,
            'sync_state': 'pending',
            'updated_at': row['updated_at'] ?? _nowIso(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      body[table] = prepared;
    }

    status.value = status.value.copyWith(phase: SyncPhase.syncing);
    final response = await _api.post('/api/sync/bootstrap-import', body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorFrom(response), response.statusCode);
    }
    for (final table in trackedTables) {
      await db.update(table, {
        'sync_state': 'synced',
      }, where: "sync_state = 'pending'");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bootstrapImportedKey, true);
    final applied = await _pullRemote();
    if (applied > 0) _bumpDataVersion();
    final last = DateTime.now().toUtc();
    await prefs.setString(_lastSyncedKey, last.toIso8601String());
    await _refreshStatus(phase: SyncPhase.synced, lastSyncedAt: last);
    await startAutoSync();
  }

  Future<void> _pushPending() async {
    final db = await _db.database;
    final operations = <Map<String, dynamic>>[];
    final localRefs = <({String table, String syncId, String operation})>[];

    for (final table in _upsertOrder) {
      final rows = await db.query(
        table,
        where: "sync_state = 'pending' AND deleted_at IS NULL",
        orderBy: 'id ASC',
      );
      for (final row in rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        final syncId = await _syncIdFor(db, table, id);
        operations.add({
          'entity': table,
          'operation': 'upsert',
          'payload': await _payloadFor(db, table, {...row, 'sync_id': syncId}),
        });
        localRefs.add((table: table, syncId: syncId, operation: 'upsert'));
      }
    }

    for (final table in _deleteOrder) {
      final rows = await db.query(
        table,
        where: "sync_state = 'deleting'",
        orderBy: 'id ASC',
      );
      for (final row in rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        final syncId = await _syncIdFor(db, table, id);
        operations.add({
          'entity': table,
          'operation': 'delete',
          'payload': {
            'id': id,
            'local_id': id,
            'sync_id': syncId,
            'deleted_at': row['deleted_at'] ?? _nowIso(),
          },
        });
        localRefs.add((table: table, syncId: syncId, operation: 'delete'));
      }
    }

    if (operations.isEmpty) return;
    final response = await _api.post('/api/sync/push', {
      'operations': operations,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorFrom(response), response.statusCode);
    }

    await db.transaction((tx) async {
      for (final ref in localRefs) {
        if (ref.operation == 'delete') {
          await tx.delete(
            ref.table,
            where: 'sync_id = ?',
            whereArgs: [ref.syncId],
          );
        } else {
          await tx.update(
            ref.table,
            {'sync_state': 'synced'},
            where: "sync_id = ? AND sync_state = 'pending'",
            whereArgs: [ref.syncId],
          );
        }
      }
    });
  }

  Future<int> _pullRemote() async {
    final prefs = await SharedPreferences.getInstance();
    var cursor = prefs.getInt(_cursorKey) ?? 0;
    var applied = 0;
    while (true) {
      final response = await _api.get('/api/sync/pull?cursor=$cursor');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorFrom(response), response.statusCode);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final events = List<Map<String, dynamic>>.from(
        body['events'] as List? ?? const [],
      );
      if (events.isEmpty) {
        await prefs.setInt(
          _cursorKey,
          (body['next_cursor'] as num?)?.toInt() ?? cursor,
        );
        return applied;
      }
      for (final event in events) {
        if (await _applyEvent(event)) applied++;
        cursor = (event['cursor'] as num?)?.toInt() ?? cursor;
        await prefs.setInt(_cursorKey, cursor);
      }
      if (events.length < 500) return applied;
    }
  }

  Future<bool> _applyEvent(Map<String, dynamic> event) async {
    final entity = event['entity']?.toString();
    if (entity == null || !trackedTables.contains(entity)) return false;
    final payload = Map<String, dynamic>.from(
      event['payload'] as Map? ?? const {},
    );
    final syncId =
        payload['sync_id']?.toString() ?? event['entity_id']?.toString();
    if (syncId == null || syncId.isEmpty) return false;

    final db = await _db.database;
    if (event['operation'] == 'delete' || payload['deleted_at'] != null) {
      await db.delete(entity, where: 'sync_id = ?', whereArgs: [syncId]);
      return true;
    }

    final localPayload = await _localPayloadForRemote(db, entity, payload);
    if (localPayload == null) return false;
    localPayload
      ..['sync_id'] = syncId
      ..['server_updated_at'] = payload['updated_at']?.toString()
      ..['updated_at'] = payload['updated_at']?.toString() ?? _nowIso()
      ..['deleted_at'] = null
      ..['sync_state'] = 'synced';

    final existing = await db.query(
      entity,
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );
    if (existing.isEmpty && entity == 'app_settings') {
      final year = localPayload['year'];
      final byYear = await db.query(
        entity,
        where: 'year = ?',
        whereArgs: [year],
        limit: 1,
      );
      if (byYear.isNotEmpty) {
        await db.update(
          entity,
          localPayload..remove('id'),
          where: 'id = ?',
          whereArgs: [byYear.first['id']],
        );
        return true;
      }
    }
    try {
      if (existing.isEmpty) {
        localPayload.remove('id');
        await db.insert(entity, localPayload);
      } else {
        localPayload.remove('id');
        await db.update(
          entity,
          localPayload,
          where: 'sync_id = ?',
          whereArgs: [syncId],
        );
      }
    } on DatabaseException catch (e) {
      if (_isUniqueConstraintError(e)) {
        throw ApiException(_localConflictMessage(entity), 409);
      }
      rethrow;
    }
    return true;
  }

  Future<Map<String, dynamic>> _payloadFor(
    Database db,
    String table,
    Map<String, dynamic> row,
  ) async {
    final payload = Map<String, dynamic>.from(row)
      ..remove('sync_state')
      ..remove('server_updated_at')
      ..remove('deleted_at');
    final id = payload['id'];
    if (id != null) payload['local_id'] = id;
    final baseUpdatedAt = row['server_updated_at']?.toString();
    if (baseUpdatedAt != null && baseUpdatedAt.trim().isNotEmpty) {
      payload['base_updated_at'] = baseUpdatedAt;
    }
    if (table == 'loans' || table == 'salary_records') {
      final employeeId = payload['employee_id'];
      if (employeeId != null) {
        final employeeRows = await db.query(
          'employees',
          columns: ['sync_id'],
          where: 'id = ?',
          whereArgs: [employeeId],
          limit: 1,
        );
        final employeeSyncId = employeeRows.isEmpty
            ? null
            : employeeRows.first['sync_id']?.toString();
        if (employeeSyncId != null && employeeSyncId.isNotEmpty) {
          payload['employee_sync_id'] = employeeSyncId;
        }
      }
    }
    return payload;
  }

  Future<Map<String, dynamic>?> _localPayloadForRemote(
    Database db,
    String table,
    Map<String, dynamic> payload,
  ) async {
    return switch (table) {
      'employees' => Employee.fromMap(
        _boolsToInts(payload, const {
          'has_prior_experience',
          'is_married',
          'is_active',
          'hard_and_harmful_job',
        }),
      ).toMap()..remove('id'),
      'loans' => await _remoteLoanPayload(db, payload),
      'salary_records' => await _remoteSalaryPayload(db, payload),
      'app_settings' => AppSettings.fromMap(payload).toMap()..remove('id'),
      _ => null,
    };
  }

  Future<Map<String, dynamic>?> _remoteLoanPayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeId = await _localEmployeeId(db, payload);
    if (employeeId == null) return null;
    return Loan.fromMap({
      ..._boolsToInts(payload, const {'is_active'}),
      'employee_id': employeeId,
    }).toMap()..remove('id');
  }

  Future<Map<String, dynamic>?> _remoteSalaryPayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeId = await _localEmployeeId(db, payload);
    if (employeeId == null) return null;
    return SalaryRecord.fromMap({
      ..._boolsToInts(payload, const {'include_leave_in_payslip'}),
      'employee_id': employeeId,
      'created_at': payload['created_at']?.toString() ?? _nowIso(),
    }).toMap()..remove('id');
  }

  Future<int?> _localEmployeeId(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeSyncId =
        payload['employee_sync_id']?.toString() ??
        payload['employee_id']?.toString();
    if (employeeSyncId == null || employeeSyncId.isEmpty) return null;
    final rows = await db.query(
      'employees',
      columns: ['id'],
      where: 'sync_id = ?',
      whereArgs: [employeeSyncId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  Map<String, dynamic> _boolsToInts(
    Map<String, dynamic> payload,
    Set<String> columns,
  ) {
    final map = Map<String, dynamic>.from(payload);
    for (final column in columns) {
      final value = map[column];
      if (value is bool) map[column] = value ? 1 : 0;
    }
    return map;
  }

  Future<String> _syncIdFor(Database db, String table, int id) async {
    final rows = await db.query(
      table,
      columns: ['sync_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final existing = rows.isEmpty ? null : rows.first['sync_id']?.toString();
    if (existing != null && existing.trim().isNotEmpty) return existing;
    final generated = _uuid.v4();
    await db.update(
      table,
      {'sync_id': generated},
      where: 'id = ?',
      whereArgs: [id],
    );
    return generated;
  }

  Future<void> _refreshStatus({
    SyncPhase? phase,
    DateTime? lastSyncedAt,
    DateTime? lastUnsentAt,
    String? message,
  }) async {
    final pending = await pendingCount();
    status.value = status.value.copyWith(
      phase: phase ?? (pending == 0 ? SyncPhase.synced : status.value.phase),
      pendingCount: pending,
      lastSyncedAt: lastSyncedAt,
      lastUnsentAt: lastUnsentAt,
      message: message,
      clearMessage: message == null,
    );
  }

  Future<void> _ensureTrackedTable(String table) async {
    if (!trackedTables.contains(table)) {
      throw ArgumentError('Unknown sync table: $table');
    }
  }

  String _errorFrom(dynamic response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _friendlyServerError(body);
    } catch (_) {
      return 'خطا در همگام‌سازی با سرور';
    }
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  void _bumpDataVersion() {
    dataVersion.value++;
  }

  String _friendlyServerError(Map<String, dynamic> body) {
    final code = body['code']?.toString();
    return switch (code) {
      'duplicate_personnel_code' =>
        'کد پرسنلی تکراری است. اطلاعات سرور را تازه کنید و برای کارمند کد جدید انتخاب کنید.',
      'duplicate_salary_record' =>
        'برای این کارمند و این ماه قبلا فیش حقوقی ثبت شده است. اطلاعات را تازه کنید و دوباره بررسی کنید.',
      'stale_update' =>
        'این بخش همزمان توسط کاربر دیگری تغییر کرده است. اگر می‌خواهید تغییرات خودتان را اعمال کنید، از کاربر دیگر بخواهید برنامه را ببندد، اطلاعات را تازه کنید و دوباره ذخیره کنید.',
      'sync_conflict' || 'duplicate_settings_year' =>
        'تغییر شما با اطلاعات ذخیره‌شده روی سرور تداخل دارد. اطلاعات را تازه کنید و دوباره ذخیره کنید.',
      _ =>
        body['error']?.toString().trim().isNotEmpty == true
            ? body['error'].toString()
            : 'خطا در همگام‌سازی با سرور',
    };
  }

  String _friendlyLocalError(Object error) {
    if (error is DatabaseException && _isUniqueConstraintError(error)) {
      return 'اطلاعات دریافت‌شده از سرور با یک رکورد ذخیره‌نشده روی این دستگاه تداخل دارد. رکورد محلی را ویرایش کنید یا اطلاعات را تازه کنید.';
    }
    return error.toString();
  }

  bool _isUniqueConstraintError(DatabaseException error) {
    final text = error.toString().toLowerCase();
    return text.contains('unique constraint') ||
        text.contains('unique failed') ||
        text.contains('sqlite_constraint_unique');
  }

  String _localConflictMessage(String entity) {
    return switch (entity) {
      'employees' =>
        'کد پرسنلی روی این دستگاه با اطلاعات سرور تداخل دارد. کد کارمند را تغییر دهید و دوباره sync کنید.',
      'salary_records' =>
        'فیش حقوقی این ماه با اطلاعات سرور تداخل دارد. اطلاعات را تازه کنید و دوباره ذخیره کنید.',
      _ =>
        'اطلاعات محلی با داده‌های سرور تداخل دارد. اطلاعات را تازه کنید و دوباره تلاش کنید.',
    };
  }
}
