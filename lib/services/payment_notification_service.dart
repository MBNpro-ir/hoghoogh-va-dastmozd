import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../utils/persian_date_helper.dart';
import '../utils/persian_number_formatter.dart';

class PaymentStatusNotification {
  final String key;
  final String employeeName;
  final int personnelCode;
  final int year;
  final int month;
  final bool isPaid;
  final String reason;
  final String actor;

  const PaymentStatusNotification({
    required this.key,
    required this.employeeName,
    required this.personnelCode,
    required this.year,
    required this.month,
    required this.isPaid,
    required this.reason,
    required this.actor,
  });

  String get message {
    final period =
        '${PersianDateHelper.monthName(month)} ${PersianNumberFormatter.toPersian(year.toString())}';
    final code = PersianNumberFormatter.toPersian(personnelCode.toString());
    final status = isPaid ? 'پرداخت شد' : 'پرداخت نشد';
    final suffix = !isPaid && reason.trim().isNotEmpty
        ? ' - دلیل: $reason'
        : '';
    final actorText = actor.trim().isEmpty ? '' : ' توسط $actor';
    return '$employeeName ($code) برای $period $status$actorText$suffix';
  }
}

class PaymentNotificationService {
  static const _seenKey = 'hvm_seen_payment_notifications_v1';
  final _db = DatabaseHelper.instance;

  Future<List<PaymentStatusNotification>> unseenForAdmin() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        ps.sync_id,
        ps.server_updated_at,
        ps.updated_at,
        ps.year,
        ps.month,
        ps.is_paid,
        ps.unpaid_reason,
        ps.updated_by_username,
        e.first_name,
        e.last_name,
        e.personnel_code
      FROM salary_payment_statuses ps
      JOIN employees e ON e.id = ps.employee_id
      WHERE ps.deleted_at IS NULL
        AND ps.updated_by_role = 'payment'
        AND ps.status_set = 1
        AND ps.sync_id IS NOT NULL
      ORDER BY COALESCE(ps.server_updated_at, ps.updated_at) DESC
      LIMIT 20
    ''');
    if (rows.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey) ?? const <String>[]).toSet();
    final notifications = <PaymentStatusNotification>[];
    for (final row in rows) {
      final syncId = row['sync_id']?.toString();
      if (syncId == null || syncId.isEmpty) continue;
      final stamp =
          row['server_updated_at']?.toString() ??
          row['updated_at']?.toString() ??
          '';
      final key = '$syncId|$stamp|${row['is_paid']}|${row['unpaid_reason']}';
      if (seen.contains(key)) continue;
      notifications.add(
        PaymentStatusNotification(
          key: key,
          employeeName: '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'
              .trim(),
          personnelCode: (row['personnel_code'] as num?)?.toInt() ?? 0,
          year: (row['year'] as num?)?.toInt() ?? 0,
          month: (row['month'] as num?)?.toInt() ?? 0,
          isPaid: (row['is_paid'] as num? ?? 0) != 0,
          reason: row['unpaid_reason']?.toString() ?? '',
          actor: row['updated_by_username']?.toString() ?? '',
        ),
      );
    }
    return notifications;
  }

  Future<void> markSeen(
    Iterable<PaymentStatusNotification> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey) ?? const <String>[]).toList();
    final next = <String>{
      ...seen,
      for (final notification in notifications) notification.key,
    }.toList();
    if (next.length > 200) {
      next.removeRange(0, next.length - 200);
    }
    await prefs.setStringList(_seenKey, next);
  }
}
