import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/advance_payment.dart';
import '../models/app_settings.dart';
import '../models/calculator_run.dart';
import '../models/employee.dart';
import '../models/employee_leave.dart';
import '../models/loan.dart';
import '../models/salary_draft.dart';
import '../models/salary_payment_status.dart';
import '../models/salary_record.dart';
import '../utils/business_validation.dart';
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
  static const _serverHydratedSessionKey = 'hvm_sync_server_hydrated_v2';
  static const _activeSessionKey = 'hvm_sync_active_session_v2';
  static const _autoSyncInterval = Duration(seconds: 5);
  static const _uuid = Uuid();

  static const trackedTables = <String>[
    'employees',
    'loans',
    'advances',
    'leaves',
    'salary_records',
    'salary_payment_statuses',
    'salary_drafts',
    'calculator_runs',
    'app_settings',
  ];

  static const _upsertOrder = <String>[
    'employees',
    'app_settings',
    'loans',
    'advances',
    'leaves',
    'salary_drafts',
    'salary_records',
    'salary_payment_statuses',
    'calculator_runs',
  ];

  static const _deleteOrder = <String>[
    'salary_payment_statuses',
    'calculator_runs',
    'salary_records',
    'salary_drafts',
    'leaves',
    'advances',
    'loans',
    'employees',
    'app_settings',
  ];
  static const _paymentWritableTables = {'salary_payment_statuses'};

  final ValueNotifier<SyncSnapshot> status = ValueNotifier<SyncSnapshot>(
    SyncSnapshot.initial(),
  );
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);
  final _api = ApiClient();
  final _db = DatabaseHelper.instance;
  bool _syncing = false;
  Timer? _debounce;
  Timer? _pollTimer;
  DateTime? _pushBlockedUntil;
  String? _syncConflictMessage;

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

  Future<void> registerLoginSession(Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_activeSessionKey);
    final next = _sessionFingerprint(user);
    final changed =
        previous != null && next != null && previous.trim() != next.trim();
    await prefs.remove(_cursorKey);
    await prefs.remove(_lastSyncedKey);
    await prefs.remove(_serverHydratedSessionKey);
    if (changed) {
      await prefs.remove(_bootstrapImportedKey);
    }
    if (next != null) {
      await prefs.setString(_activeSessionKey, next);
    }
    _clearSyncConflict();
    await _refreshStatus(phase: SyncPhase.idle);
  }

  Future<void> ensureServerHydrated({
    bool markBootstrapComplete = false,
  }) async {
    if (!await _api.hasSession()) return;
    final prefs = await SharedPreferences.getInstance();
    final fingerprint = await _currentSessionFingerprint();
    if (fingerprint != null &&
        prefs.getString(_serverHydratedSessionKey) == fingerprint) {
      return;
    }
    await bootstrapFromServer(
      silent: true,
      markBootstrapComplete: markBootstrapComplete,
    );
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
    for (final table in [
      'employees',
      'loans',
      'advances',
      'salary_records',
      'calculator_runs',
    ]) {
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
    final writableTables = await _writableTablesForCurrentUser();
    for (final table in trackedTables.where(writableTables.contains)) {
      final rows = await db.rawQuery(
        "SELECT COUNT(*) AS count FROM $table WHERE sync_state IN ('pending', 'deleting')",
      );
      count += rows.first['count'] as int? ?? 0;
    }
    return count;
  }

  Future<void> markUpsert(String table, int id, {bool schedule = true}) async {
    await _ensureTrackedTable(table);
    _clearSyncConflict();
    final db = await _db.database;
    final now = _nowIso();
    final changed = await db.update(
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
    if (changed == 0) {
      throw const BusinessValidationException(
        'این رکورد دیگر وجود ندارد. صفحه را تازه کنید.',
      );
    }
    await _refreshStatus(lastUnsentAt: DateTime.now().toUtc());
    if (schedule) scheduleSync();
  }

  Future<int> markDelete(String table, int id, {bool schedule = true}) async {
    await _ensureTrackedTable(table);
    _clearSyncConflict();
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
    if (result == 0) {
      throw const BusinessValidationException(
        'این رکورد قبلاً حذف شده است. صفحه را تازه کنید.',
      );
    }
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

  Future<void> syncNow({
    bool silent = false,
    bool forcePush = false,
    bool throwOnServerError = false,
  }) async {
    if (_syncing) return;
    if (!await _api.hasSession()) {
      stopAutoSync();
      await _refreshStatus(phase: SyncPhase.idle);
      return;
    }
    if (forcePush) _clearSyncConflict();
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
      final stillBlocked = _isPushBlocked && await pendingCount() > 0;
      await _refreshStatus(
        phase: stillBlocked ? SyncPhase.error : SyncPhase.synced,
        lastSyncedAt: last,
        message: stillBlocked ? _syncConflictMessage : null,
      );
    } on ApiException catch (e) {
      final phase = e.statusCode == 0 ? SyncPhase.offline : SyncPhase.error;
      if (e.statusCode == 409) {
        _syncConflictMessage = e.message;
        _pushBlockedUntil = DateTime.now().toUtc().add(
          const Duration(minutes: 2),
        );
      }
      await _refreshStatus(phase: phase, message: e.message);
      final rejectedChange =
          e.statusCode >= 400 && e.statusCode < 500 || e.statusCode == 502;
      if (throwOnServerError && rejectedChange) {
        throw ApiException(
          'اطلاعات روی این دستگاه ذخیره شد، اما سرور نپذیرفت: ${e.message}',
          e.statusCode,
        );
      }
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
    final fingerprint = await _currentSessionFingerprint();
    if (fingerprint != null) {
      await prefs.setString(_serverHydratedSessionKey, fingerprint);
      await prefs.setString(_activeSessionKey, fingerprint);
    }
    await _refreshStatus(phase: SyncPhase.synced, lastSyncedAt: last);
    await startAutoSync();
  }

  Future<void> bootstrapFromServer({
    bool silent = false,
    bool markBootstrapComplete = false,
  }) async {
    if (!await _api.hasSession()) throw ApiException('Session required', 401);
    final ready = await _waitForIdle();
    if (!ready) return;
    _syncing = true;
    final previous = status.value;
    if (!silent) {
      status.value = previous.copyWith(phase: SyncPhase.syncing);
    }
    try {
      final response = await _api.get('/api/sync/bootstrap-export');
      if (response.statusCode == 404) {
        final applied = await _pullRemote();
        if (applied > 0) _bumpDataVersion();
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorFrom(response), response.statusCode);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final events = List<Map<String, dynamic>>.from(
        body['events'] as List? ?? const [],
      );
      final keepIds = <String, Set<String>>{
        for (final table in trackedTables) table: <String>{},
      };
      var applied = 0;
      for (final event in events) {
        final entity = event['entity']?.toString();
        final payload = Map<String, dynamic>.from(
          event['payload'] as Map? ?? const {},
        );
        final syncId =
            payload['sync_id']?.toString() ?? event['entity_id']?.toString();
        if (entity != null &&
            trackedTables.contains(entity) &&
            syncId != null &&
            syncId.isNotEmpty) {
          keepIds[entity]!.add(syncId);
        }
        if (await _applyEvent(event)) applied++;
      }
      applied += await _pruneMissingSnapshotRows(keepIds);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cursorKey, _intFromJson(body['next_cursor']));
      if (markBootstrapComplete) {
        await prefs.setBool(_bootstrapImportedKey, true);
      }
      final fingerprint = await _currentSessionFingerprint();
      if (fingerprint != null) {
        await prefs.setString(_serverHydratedSessionKey, fingerprint);
        await prefs.setString(_activeSessionKey, fingerprint);
      }
      final last = DateTime.now().toUtc();
      await prefs.setString(_lastSyncedKey, last.toIso8601String());
      if (applied > 0) _bumpDataVersion();
      await _refreshStatus(phase: SyncPhase.synced, lastSyncedAt: last);
    } on ApiException catch (e) {
      final phase = e.statusCode == 0 ? SyncPhase.offline : SyncPhase.error;
      await _refreshStatus(phase: phase, message: e.message);
      rethrow;
    } catch (e) {
      await _refreshStatus(
        phase: SyncPhase.error,
        message: _friendlyLocalError(e),
      );
      rethrow;
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pushPending() async {
    if (_isPushBlocked) return;
    final db = await _db.database;
    final writableTables = await _writableTablesForCurrentUser();
    final deleteOperations = <Map<String, dynamic>>[];
    final deleteRefs = <({String table, String syncId, String operation})>[];
    for (final table in _deleteOrder.where(writableTables.contains)) {
      final rows = await db.query(
        table,
        where: "sync_state = 'deleting'",
        orderBy: 'id ASC',
      );
      for (final row in rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        final syncId = await _syncIdFor(db, table, id);
        deleteOperations.add({
          'entity': table,
          'operation': 'delete',
          'payload': {
            'id': id,
            'local_id': id,
            'sync_id': syncId,
            'deleted_at': row['deleted_at'] ?? _nowIso(),
          },
        });
        deleteRefs.add((table: table, syncId: syncId, operation: 'delete'));
      }
    }
    await _pushBatch(db, deleteOperations, deleteRefs);

    final upsertOperations = <Map<String, dynamic>>[];
    final upsertRefs = <({String table, String syncId, String operation})>[];
    for (final table in _upsertOrder.where(writableTables.contains)) {
      final rows = await db.query(
        table,
        where: "sync_state = 'pending' AND deleted_at IS NULL",
        orderBy: 'id ASC',
      );
      for (final row in rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        final syncId = await _syncIdFor(db, table, id);
        upsertOperations.add({
          'entity': table,
          'operation': 'upsert',
          'payload': await _payloadFor(db, table, {...row, 'sync_id': syncId}),
        });
        upsertRefs.add((table: table, syncId: syncId, operation: 'upsert'));
      }
    }
    await _pushBatch(db, upsertOperations, upsertRefs);
  }

  Future<void> _pushBatch(
    Database db,
    List<Map<String, dynamic>> operations,
    List<({String table, String syncId, String operation})> localRefs,
  ) async {
    if (operations.isEmpty) return;
    final response = await _api.post('/api/sync/push', {
      'operations': operations,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorFrom(response), response.statusCode);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accepted = List<Map<String, dynamic>>.from(
      body['operations'] as List? ?? const [],
    );
    final acceptedKeys = accepted
        .map(
          (item) =>
              '${item['entity']}|${item['entity_id']}|${item['operation']}',
        )
        .toSet();
    final allAccepted = localRefs.every(
      (ref) =>
          acceptedKeys.contains('${ref.table}|${ref.syncId}|${ref.operation}'),
    );
    if (!allAccepted || accepted.length != localRefs.length) {
      throw ApiException(
        'سرور همه تغییرات را نپذیرفت. هیچ داده محلی حذف نشد؛ اطلاعات را تازه کنید و دوباره تلاش کنید.',
        502,
      );
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
          _intFromJson(body['next_cursor'], fallback: cursor),
        );
        return applied;
      }
      for (final event in events) {
        if (await _applyEvent(event)) applied++;
        cursor = _intFromJson(event['cursor'], fallback: cursor);
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
    if (existing.isEmpty) {
      final naturalKeyId = await _naturalKeyLocalId(db, entity, localPayload);
      if (naturalKeyId != null) {
        await db.update(
          entity,
          localPayload..remove('id'),
          where: 'id = ?',
          whereArgs: [naturalKeyId],
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
    if (table == 'loans' ||
        table == 'advances' ||
        table == 'leaves' ||
        table == 'salary_records' ||
        table == 'salary_payment_statuses' ||
        table == 'salary_drafts' ||
        table == 'calculator_runs') {
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
          'has_shift_work',
          'use_custom_overtime_base',
        }),
      ).toMap()..remove('id'),
      'loans' => await _remoteLoanPayload(db, payload),
      'advances' => await _remoteAdvancePayload(db, payload),
      'leaves' => await _remoteLeavePayload(db, payload),
      'salary_records' => await _remoteSalaryPayload(db, payload),
      'salary_payment_statuses' => await _remotePaymentStatusPayload(
        db,
        payload,
      ),
      'salary_drafts' => await _remoteSalaryDraftPayload(db, payload),
      'calculator_runs' => await _remoteCalculatorRunPayload(db, payload),
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

  Future<Map<String, dynamic>?> _remoteAdvancePayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeId = await _localEmployeeId(db, payload);
    if (employeeId == null) return null;
    return AdvancePayment.fromMap({
      ...payload,
      'employee_id': employeeId,
    }).toMap()..remove('id');
  }

  Future<Map<String, dynamic>?> _remoteLeavePayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeId = await _localEmployeeId(db, payload);
    if (employeeId == null) return null;
    return EmployeeLeave.fromMap({
      ...payload,
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
      ..._boolsToInts(payload, const {
        'include_leave_in_payslip',
        'use_custom_overtime_base',
        'housing_exempt',
        'food_exempt',
        'seniority_exempt',
      }),
      'employee_id': employeeId,
      'created_at': payload['created_at']?.toString() ?? _nowIso(),
    }).toMap()..remove('id');
  }

  Future<Map<String, dynamic>?> _remoteSalaryDraftPayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeId = await _localEmployeeId(db, payload);
    if (employeeId == null) return null;
    return SalaryDraft.fromMap({
      ..._boolsToInts(payload, const {
        'use_custom_overtime_base',
        'auto_shift_work',
        'auto_hourly_benefits',
        'auto_other_benefits',
        'auto_seniority',
        'auto_loan_installment',
        'skip_loan_installment',
        'auto_advances',
        'include_leave_in_payslip',
        'insurance_exempt',
        'tax_exempt',
        'housing_exempt',
        'food_exempt',
        'seniority_exempt',
      }),
      'employee_id': employeeId,
    }).toMap()..remove('id');
  }

  Future<Map<String, dynamic>?> _remoteCalculatorRunPayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    int? employeeId;
    final hasEmployeeRef =
        payload['employee_sync_id'] != null || payload['employee_id'] != null;
    if (hasEmployeeRef) {
      employeeId = await _localEmployeeId(db, payload);
      if (employeeId == null) return null;
    }
    return CalculatorRun.fromMap({
      ...payload,
      'employee_id': employeeId,
      'created_at': payload['created_at']?.toString() ?? _nowIso(),
    }).toMap()..remove('id');
  }

  Future<Map<String, dynamic>?> _remotePaymentStatusPayload(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final employeeId = await _localEmployeeId(db, payload);
    if (employeeId == null) return null;
    return SalaryPaymentStatus.fromMap({
      ..._boolsToInts(payload, const {
        'is_paid',
        'status_set',
        'payment_unlocked',
      }),
      'employee_id': employeeId,
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

  Future<int?> _naturalKeyLocalId(
    Database db,
    String table,
    Map<String, dynamic> payload,
  ) async {
    final List<Map<String, Object?>> rows;
    if (table == 'employees') {
      rows = await db.query(
        table,
        columns: ['id', 'sync_state'],
        where: 'personnel_code = ?',
        whereArgs: [payload['personnel_code']],
        limit: 1,
      );
    } else if (table == 'salary_records') {
      rows = await db.query(
        table,
        columns: ['id', 'sync_state'],
        where: 'employee_id = ? AND year = ? AND month = ?',
        whereArgs: [payload['employee_id'], payload['year'], payload['month']],
        limit: 1,
      );
    } else if (table == 'salary_drafts') {
      rows = await db.query(
        table,
        columns: ['id', 'sync_state'],
        where: 'employee_id = ? AND year = ? AND month = ?',
        whereArgs: [payload['employee_id'], payload['year'], payload['month']],
        limit: 1,
      );
    } else if (table == 'salary_payment_statuses') {
      rows = await db.query(
        table,
        columns: ['id', 'sync_state'],
        where: 'employee_id = ? AND year = ? AND month = ?',
        whereArgs: [payload['employee_id'], payload['year'], payload['month']],
        limit: 1,
      );
    } else if (table == 'leaves') {
      rows = await db.query(
        table,
        columns: ['id', 'sync_state', 'notes', 'server_updated_at'],
        where: '''
          employee_id = ?
          AND from_date = ?
          AND to_date = ?
          AND type = ?
          AND deleted_at IS NULL
        ''',
        whereArgs: [
          payload['employee_id'],
          payload['from_date'],
          payload['to_date'],
          payload['type'],
        ],
        limit: 1,
      );
    } else if (table == 'app_settings') {
      rows = await db.query(
        table,
        columns: ['id', 'sync_state'],
        where: 'year = ?',
        whereArgs: [payload['year']],
        limit: 1,
      );
    } else {
      return null;
    }
    if (rows.isEmpty) return null;
    final state = rows.first['sync_state']?.toString();
    if (state == 'pending' || state == 'deleting') {
      final isLegacyLeave =
          table == 'leaves' &&
          rows.first['notes']?.toString().startsWith('انتقال خودکار') == true &&
          payload['notes']?.toString().startsWith('انتقال خودکار') == true;
      if (isLegacyLeave) return rows.first['id'] as int?;
      throw ApiException(_localConflictMessage(table), 409);
    }
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
    if (rows.isEmpty) {
      throw const BusinessValidationException(
        'رکورد موردنظر برای همگام‌سازی پیدا نشد. صفحه را تازه کنید.',
      );
    }
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

  Future<int> _pruneMissingSnapshotRows(
    Map<String, Set<String>> keepIds,
  ) async {
    final db = await _db.database;
    var deleted = 0;
    for (final table in _deleteOrder) {
      final keep = keepIds[table] ?? const <String>{};
      final rows = await db.query(
        table,
        columns: ['id', 'sync_id'],
        where: "sync_state = 'synced' AND sync_id IS NOT NULL",
      );
      for (final row in rows) {
        final syncId = row['sync_id']?.toString();
        final id = row['id'] as int?;
        if (id == null || syncId == null || keep.contains(syncId)) continue;
        deleted += await db.delete(table, where: 'id = ?', whereArgs: [id]);
      }
    }
    return deleted;
  }

  Future<bool> _waitForIdle() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (_syncing && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return !_syncing;
  }

  Future<String?> _currentSessionFingerprint() async {
    return _sessionFingerprint(await _api.getUser());
  }

  String? _sessionFingerprint(Map<String, dynamic>? user) {
    final companyId = user?['company_id']?.toString().trim();
    final userId =
        user?['id']?.toString().trim() ?? user?['username']?.toString().trim();
    if (companyId == null ||
        companyId.isEmpty ||
        companyId == 'null' ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }
    return '$companyId:$userId';
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

  Future<Set<String>> _writableTablesForCurrentUser() async {
    final role = (await _api.getUser())?['role']?.toString();
    if (role == 'payment') return _paymentWritableTables;
    return trackedTables.toSet();
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

  int _intFromJson(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void _bumpDataVersion() {
    dataVersion.value++;
  }

  bool get _isPushBlocked {
    final until = _pushBlockedUntil;
    return until != null && until.isAfter(DateTime.now().toUtc());
  }

  void _clearSyncConflict() {
    _pushBlockedUntil = null;
    _syncConflictMessage = null;
  }

  String _friendlyServerError(Map<String, dynamic> body) {
    final code = body['code']?.toString();
    return switch (code) {
      'duplicate_personnel_code' =>
        'کد پرسنلی تکراری است. اطلاعات سرور را تازه کنید و برای کارمند کد جدید انتخاب کنید.',
      'duplicate_national_id' =>
        'این کد ملی قبلاً برای کارمند دیگری ثبت شده است. اطلاعات را تازه کنید.',
      'duplicate_salary_record' =>
        'برای این کارمند و این ماه قبلا فیش حقوقی ثبت شده است. اطلاعات را تازه کنید و دوباره بررسی کنید.',
      'duplicate_salary_draft' =>
        'پیش‌نویس این کارمند و ماه همزمان در دستگاه دیگری تغییر کرده است. اطلاعات را تازه کنید.',
      'duplicate_payment_status' =>
        'وضعیت پرداخت این فیش همزمان در دستگاه دیگری تغییر کرده است. اطلاعات را تازه کنید.',
      'duplicate_leave' =>
        'برای این کارمند، نوع و بازه زمانی یک مرخصی یکسان قبلاً ثبت شده است. اطلاعات را تازه کنید.',
      'stale_update' =>
        'این بخش همزمان توسط کاربر دیگری تغییر کرده است. اگر می‌خواهید تغییرات خودتان را اعمال کنید، از کاربر دیگر بخواهید برنامه را ببندد، اطلاعات را تازه کنید و دوباره ذخیره کنید.',
      'invalid_prior_experience' =>
        'برای فعال کردن «دارای سابقه»، تاریخ شروع به کار باید تا پایان سال مالی حداقل یک سال سابقه داشته باشد.',
      'invalid_attendance_days' =>
        'جمع روزهای مرخصی و استعلاجی نمی‌تواند از کل روزهای کارکرد بیشتر باشد.',
      'invalid_leave' =>
        'اطلاعات مرخصی معتبر نیست. مدت مرخصی، نوع و وضعیت را بررسی کنید.',
      'invalid_employee' ||
      'invalid_employee_date' ||
      'invalid_employee_amount' =>
        'اطلاعات کارمند معتبر نیست. مشخصات، تاریخ‌ها و مبالغ را بررسی کنید.',
      'invalid_loan' =>
        'اطلاعات وام معتبر نیست. مبلغ، اقساط و تاریخ شروع را بررسی کنید.',
      'invalid_advance' =>
        'اطلاعات مساعده معتبر نیست. مبلغ و تاریخ پرداخت را بررسی کنید.',
      'invalid_payroll_period' =>
        'دوره حقوق معتبر نیست. سال، ماه و تعداد روزها را بررسی کنید.',
      'invalid_payment_period' =>
        'دوره پرداخت معتبر نیست. سال و ماه را بررسی کنید.',
      'invalid_payment_reason' =>
        'برای وضعیت پرداخت‌نشده باید دلیل معتبر وارد شود.',
      'payment_status_locked' =>
        'این فیش برای ثبت وضعیت پرداخت باز نشده است. ادمین باید ابتدا قفل پرداخت را فعال کند.',
      'invalid_salary_amount' =>
        'یکی از مقادیر حقوق یا ساعات نامعتبر است و امکان ذخیره وجود ندارد.',
      'invalid_settings' =>
        'مقادیر تنظیمات معتبر نیست. مبالغ و درصدها را بررسی کنید.',
      'invalid_employee_reference' =>
        'کارمند مرتبط حذف شده یا در دسترس نیست. اطلاعات را تازه کنید.',
      'invalid_sync_batch' || 'invalid_sync_operation' =>
        'نسخه اطلاعات با سرور سازگار نیست. برنامه را به‌روزرسانی و دوباره همگام کنید.',
      'invalid_payload' =>
        'یک یا چند مقدار خارج از محدوده مجاز است. اطلاعات را بررسی کنید.',
      'invalid_overtime_base' =>
        'وقتی مبنای دستی اضافه‌کاری فعال است، مبلغ مبنای روزانه باید بیشتر از صفر باشد.',
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
      'salary_drafts' =>
        'پیش‌نویس این ماه با اطلاعات سرور تداخل دارد. اطلاعات را تازه کنید و دوباره ادامه دهید.',
      'salary_payment_statuses' =>
        'وضعیت پرداخت این ماه با اطلاعات سرور تداخل دارد. اطلاعات را تازه کنید و دوباره ذخیره کنید.',
      _ =>
        'اطلاعات محلی با داده‌های سرور تداخل دارد. اطلاعات را تازه کنید و دوباره تلاش کنید.',
    };
  }
}
