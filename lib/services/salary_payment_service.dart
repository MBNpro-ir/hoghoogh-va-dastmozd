import 'dart:convert';

import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/salary_payment_status.dart';
import '../models/salary_record.dart';
import '../utils/business_validation.dart';
import 'api_client.dart';
import 'settings_service.dart';
import 'sync_service.dart';

class PaymentSlipRow {
  final int salaryRecordId;
  final int employeeId;
  final int personnelCode;
  final String employeeName;
  final String nationalId;
  final int year;
  final int month;
  final double finalPayment;
  final int? statusId;
  final bool? isPaid;
  final bool statusSet;
  final bool paymentUnlocked;
  final String unpaidReason;
  final String updatedByUsername;
  final String updatedByRole;
  final String? serverUpdatedAt;
  final DateTime? statusChangedAt;
  final List<PaymentStatusLogEntry> history;

  const PaymentSlipRow({
    required this.salaryRecordId,
    required this.employeeId,
    required this.personnelCode,
    required this.employeeName,
    required this.nationalId,
    required this.year,
    required this.month,
    required this.finalPayment,
    required this.statusId,
    required this.isPaid,
    required this.statusSet,
    required this.paymentUnlocked,
    required this.unpaidReason,
    required this.updatedByUsername,
    required this.updatedByRole,
    required this.serverUpdatedAt,
    required this.statusChangedAt,
    required this.history,
  });

  bool get hasStatus => statusSet;

  factory PaymentSlipRow.fromMap(Map<String, Object?> map) {
    final snapshotName = map['employee_full_name_snapshot']?.toString().trim();
    final employeeName = snapshotName != null && snapshotName.isNotEmpty
        ? snapshotName
        : '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim();
    return PaymentSlipRow(
      salaryRecordId: (map['salary_record_id'] as num).toInt(),
      employeeId: (map['employee_id'] as num).toInt(),
      personnelCode:
          (map['employee_personnel_code_snapshot'] as num?)?.toInt() ??
          (map['personnel_code'] as num?)?.toInt() ??
          0,
      employeeName: employeeName,
      nationalId:
          map['employee_national_id_snapshot']?.toString() ??
          map['national_id']?.toString() ??
          '',
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      finalPayment: (map['final_payment'] as num).toDouble(),
      statusId: (map['status_id'] as num?)?.toInt(),
      statusSet: (map['status_set'] as num? ?? 0) != 0,
      paymentUnlocked: (map['payment_unlocked'] as num? ?? 0) != 0,
      isPaid: (map['status_set'] as num? ?? 0) == 0 || map['is_paid'] == null
          ? null
          : ((map['is_paid'] as num?)?.toInt() ?? 0) != 0,
      unpaidReason: map['unpaid_reason']?.toString() ?? '',
      updatedByUsername: map['updated_by_username']?.toString() ?? '',
      updatedByRole: map['updated_by_role']?.toString() ?? '',
      serverUpdatedAt: map['payment_server_updated_at']?.toString(),
      statusChangedAt: DateTime.tryParse(
        map['status_changed_at']?.toString() ?? '',
      ),
      history: PaymentStatusLogEntry.listFromJson(
        (map['status_set'] as num? ?? 0) == 0
            ? null
            : map['change_log']?.toString(),
      ),
    );
  }
}

class PaymentStatusLogEntry {
  final bool isPaid;
  final String reason;
  final String actor;
  final String role;
  final DateTime changedAt;

  const PaymentStatusLogEntry({
    required this.isPaid,
    required this.reason,
    required this.actor,
    required this.role,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() => {
    'is_paid': isPaid,
    'reason': reason,
    'actor': actor,
    'role': role,
    'changed_at': changedAt.toUtc().toIso8601String(),
  };

  factory PaymentStatusLogEntry.fromJson(Map<String, dynamic> json) {
    return PaymentStatusLogEntry(
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      reason: json['reason']?.toString() ?? '',
      actor: json['actor']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      changedAt:
          DateTime.tryParse(json['changed_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  static List<PaymentStatusLogEntry> listFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                PaymentStatusLogEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class PaymentPayslipData {
  final Employee employee;
  final AppSettings settings;
  final SalaryRecord record;

  const PaymentPayslipData({
    required this.employee,
    required this.settings,
    required this.record,
  });
}

class SalaryPaymentService {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService();
  final _api = ApiClient();
  final _settings = SettingsService();

  Future<List<PaymentSlipRow>> getRows({(int, int)? period}) async {
    final db = await _db.database;
    final where = <String>['sr.deleted_at IS NULL', 'e.deleted_at IS NULL'];
    final args = <Object?>[];
    if (period != null) {
      where.add('sr.year = ? AND sr.month = ?');
      args.addAll([period.$1, period.$2]);
    }
    final rows = await db.rawQuery('''
      SELECT
        sr.id AS salary_record_id,
        sr.employee_id,
        sr.employee_full_name_snapshot,
        sr.employee_personnel_code_snapshot,
        sr.employee_national_id_snapshot,
        sr.year,
        sr.month,
        sr.final_payment,
        e.first_name,
        e.last_name,
        e.personnel_code,
        e.national_id,
        ps.id AS status_id,
        ps.is_paid,
        ps.status_set,
        ps.payment_unlocked,
        ps.unpaid_reason,
        ps.updated_by_username,
        ps.updated_by_role,
        ps.status_changed_at,
        ps.change_log,
        ps.server_updated_at AS payment_server_updated_at
      FROM salary_records sr
      JOIN employees e ON e.id = sr.employee_id
      LEFT JOIN salary_payment_statuses ps
        ON ps.employee_id = sr.employee_id
       AND ps.year = sr.year
       AND ps.month = sr.month
       AND ps.deleted_at IS NULL
      WHERE ${where.join(' AND ')}
      ORDER BY sr.year DESC, sr.month DESC, e.personnel_code ASC, sr.id ASC
    ''', args);
    return rows.map(PaymentSlipRow.fromMap).toList();
  }

  Future<List<(int, int)>> getAvailablePeriods() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT year, month
      FROM salary_records
      WHERE deleted_at IS NULL
      ORDER BY year DESC, month DESC
    ''');
    return rows
        .map(
          (row) =>
              ((row['year'] as num).toInt(), (row['month'] as num).toInt()),
        )
        .toList();
  }

  Future<void> saveStatus({
    required int employeeId,
    required int year,
    required int month,
    required bool isPaid,
    required String unpaidReason,
  }) async {
    final reason = unpaidReason.trim();
    if (!isPaid && reason.isEmpty) {
      throw const BusinessValidationException(
        'برای وضعیت پرداخت‌نشده باید دلیل وارد شود.',
      );
    }
    final db = await _db.database;
    final identity = await _currentUserIdentity();
    final now = DateTime.now().toUtc();
    final existing = await db.query(
      'salary_payment_statuses',
      columns: [
        'id',
        'is_paid',
        'status_set',
        'payment_unlocked',
        'unpaid_reason',
        'updated_by_username',
        'updated_by_role',
        'status_changed_at',
        'change_log',
      ],
      where: 'employee_id = ? AND year = ? AND month = ?',
      whereArgs: [employeeId, year, month],
      limit: 1,
    );
    final unlocked = existing.isNotEmpty
        ? (existing.first['payment_unlocked'] as num? ?? 0) != 0
        : false;
    if (identity.role == 'payment' && !unlocked) {
      throw const BusinessValidationException(
        'این فیش برای ثبت وضعیت پرداخت باز نشده است.',
      );
    }
    final history = existing.isEmpty
        ? <PaymentStatusLogEntry>[]
        : PaymentStatusLogEntry.listFromJson(
            existing.first['change_log']?.toString(),
          );
    if (existing.isNotEmpty && history.isEmpty) {
      final previousStatusSet =
          (existing.first['status_set'] as num? ?? 1) != 0;
      if (previousStatusSet) {
        history.add(
          PaymentStatusLogEntry(
            isPaid: (existing.first['is_paid'] as num? ?? 0) != 0,
            reason: existing.first['unpaid_reason']?.toString() ?? '',
            actor: existing.first['updated_by_username']?.toString() ?? '',
            role: existing.first['updated_by_role']?.toString() ?? '',
            changedAt:
                DateTime.tryParse(
                  existing.first['status_changed_at']?.toString() ?? '',
                ) ??
                now,
          ),
        );
      }
    }
    history.add(
      PaymentStatusLogEntry(
        isPaid: isPaid,
        reason: isPaid ? '' : reason,
        actor: identity.username,
        role: identity.role,
        changedAt: now,
      ),
    );
    final limitedHistory = history.length > 50
        ? history.sublist(history.length - 50)
        : history;
    final status = SalaryPaymentStatus(
      employeeId: employeeId,
      year: year,
      month: month,
      isPaid: isPaid,
      statusSet: true,
      paymentUnlocked: unlocked,
      unpaidReason: isPaid ? '' : reason,
      updatedByUsername: identity.username,
      updatedByRole: identity.role,
      statusChangedAt: now,
      changeLog: jsonEncode(
        limitedHistory.map((entry) => entry.toJson()).toList(),
      ),
    );
    final map = status.toMap()..remove('id');
    final id = existing.isEmpty
        ? await db.insert('salary_payment_statuses', map)
        : (existing.first['id'] as num).toInt();
    if (existing.isNotEmpty) {
      await db.update(
        'salary_payment_statuses',
        {...map, 'deleted_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await _sync.markUpsert('salary_payment_statuses', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
  }

  Future<void> setPaymentUnlocked({
    required int employeeId,
    required int year,
    required int month,
    required bool unlocked,
  }) async {
    final identity = await _currentUserIdentity();
    if (identity.role == 'payment') {
      throw const BusinessValidationException(
        'فقط ادمین می‌تواند قفل پرداخت فیش را تغییر دهد.',
      );
    }
    final db = await _db.database;
    final now = DateTime.now().toUtc();
    final existing = await db.query(
      'salary_payment_statuses',
      where: 'employee_id = ? AND year = ? AND month = ?',
      whereArgs: [employeeId, year, month],
      limit: 1,
    );
    int id;
    if (existing.isEmpty) {
      id = await db.insert('salary_payment_statuses', {
        'employee_id': employeeId,
        'year': year,
        'month': month,
        'is_paid': 0,
        'status_set': 0,
        'payment_unlocked': unlocked ? 1 : 0,
        'unpaid_reason': '',
        'updated_by_username': identity.username,
        'updated_by_role': identity.role,
        'status_changed_at': now.toIso8601String(),
        'change_log': '[]',
      });
    } else {
      id = (existing.first['id'] as num).toInt();
      await db.update(
        'salary_payment_statuses',
        {
          'payment_unlocked': unlocked ? 1 : 0,
          'updated_by_username': identity.username,
          'updated_by_role': identity.role,
          'deleted_at': null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await _sync.markUpsert('salary_payment_statuses', id, schedule: false);
    await _sync.syncNow(silent: true, throwOnServerError: true);
  }

  Future<void> setPaymentUnlockedForRows({
    required Iterable<PaymentSlipRow> rows,
    required bool unlocked,
  }) async {
    for (final row in rows) {
      await setPaymentUnlocked(
        employeeId: row.employeeId,
        year: row.year,
        month: row.month,
        unlocked: unlocked,
      );
    }
  }

  Future<void> deleteHistoryEntry({
    required PaymentSlipRow row,
    required int historyIndex,
  }) async {
    final identity = await _currentUserIdentity();
    if (identity.role == 'payment') {
      throw const BusinessValidationException(
        'فقط ادمین می‌تواند لاگ پرداخت را حذف کند.',
      );
    }
    if (row.statusId == null) return;
    final history = [...row.history];
    if (historyIndex < 0 || historyIndex >= history.length) return;
    history.removeAt(historyIndex);

    final db = await _db.database;
    final now = DateTime.now().toUtc();
    if (history.isEmpty) {
      await db.update(
        'salary_payment_statuses',
        {
          'status_set': 0,
          'is_paid': 0,
          'unpaid_reason': '',
          'updated_by_username': identity.username,
          'updated_by_role': identity.role,
          'status_changed_at': now.toIso8601String(),
          'change_log': '[]',
          'deleted_at': null,
        },
        where: 'id = ?',
        whereArgs: [row.statusId],
      );
    } else {
      final latest = history.last;
      await db.update(
        'salary_payment_statuses',
        {
          'status_set': 1,
          'is_paid': latest.isPaid ? 1 : 0,
          'unpaid_reason': latest.isPaid ? '' : latest.reason,
          'updated_by_username': latest.actor,
          'updated_by_role': latest.role,
          'status_changed_at': latest.changedAt.toUtc().toIso8601String(),
          'change_log': jsonEncode(
            history.map((entry) => entry.toJson()).toList(),
          ),
          'deleted_at': null,
        },
        where: 'id = ?',
        whereArgs: [row.statusId],
      );
    }
    await _sync.markUpsert(
      'salary_payment_statuses',
      row.statusId!,
      schedule: false,
    );
    await _sync.syncNow(silent: true, throwOnServerError: true);
  }

  Future<PaymentPayslipData?> payslipData(PaymentSlipRow row) async {
    final db = await _db.database;
    final recordRows = await db.query(
      'salary_records',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [row.salaryRecordId],
      limit: 1,
    );
    if (recordRows.isEmpty) return null;
    final employeeRows = await db.query(
      'employees',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [row.employeeId],
      limit: 1,
    );
    if (employeeRows.isEmpty) return null;
    final record = SalaryRecord.fromMap(recordRows.first);
    final settings = await _settings.getCurrentSettings(year: record.year);
    return PaymentPayslipData(
      employee: Employee.fromMap(employeeRows.first),
      settings: settings,
      record: record,
    );
  }

  Future<({String username, String role})> _currentUserIdentity() async {
    final user = await _api.getUser();
    final fullName = user?['full_name']?.toString().trim();
    final username = fullName != null && fullName.isNotEmpty
        ? fullName
        : user?['username']?.toString().trim() ?? '';
    return (username: username, role: user?['role']?.toString() ?? '');
  }
}
