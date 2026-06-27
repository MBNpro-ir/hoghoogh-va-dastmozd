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
  final String unpaidReason;
  final String updatedByUsername;
  final String updatedByRole;
  final String? serverUpdatedAt;
  final DateTime? statusChangedAt;

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
    required this.unpaidReason,
    required this.updatedByUsername,
    required this.updatedByRole,
    required this.serverUpdatedAt,
    required this.statusChangedAt,
  });

  bool get hasStatus => statusId != null;

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
      isPaid: map['is_paid'] == null
          ? null
          : ((map['is_paid'] as num?)?.toInt() ?? 0) != 0,
      unpaidReason: map['unpaid_reason']?.toString() ?? '',
      updatedByUsername: map['updated_by_username']?.toString() ?? '',
      updatedByRole: map['updated_by_role']?.toString() ?? '',
      serverUpdatedAt: map['payment_server_updated_at']?.toString(),
      statusChangedAt: DateTime.tryParse(
        map['status_changed_at']?.toString() ?? '',
      ),
    );
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
        ps.unpaid_reason,
        ps.updated_by_username,
        ps.updated_by_role,
        ps.status_changed_at,
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
    final user = await _api.getUser();
    final username = user?['full_name']?.toString().trim().isNotEmpty == true
        ? user!['full_name'].toString().trim()
        : user?['username']?.toString().trim() ?? '';
    final role = user?['role']?.toString() ?? '';
    final status = SalaryPaymentStatus(
      employeeId: employeeId,
      year: year,
      month: month,
      isPaid: isPaid,
      unpaidReason: isPaid ? '' : reason,
      updatedByUsername: username,
      updatedByRole: role,
      statusChangedAt: DateTime.now().toUtc(),
    );
    final existing = await db.query(
      'salary_payment_statuses',
      columns: ['id'],
      where: 'employee_id = ? AND year = ? AND month = ?',
      whereArgs: [employeeId, year, month],
      limit: 1,
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
}
