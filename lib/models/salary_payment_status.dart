class SalaryPaymentStatus {
  final int? id;
  final int employeeId;
  final int year;
  final int month;
  final bool isPaid;
  final String unpaidReason;
  final String updatedByUsername;
  final String updatedByRole;
  final DateTime statusChangedAt;
  final String changeLog;

  const SalaryPaymentStatus({
    this.id,
    required this.employeeId,
    required this.year,
    required this.month,
    required this.isPaid,
    this.unpaidReason = '',
    this.updatedByUsername = '',
    this.updatedByRole = '',
    required this.statusChangedAt,
    this.changeLog = '[]',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'year': year,
    'month': month,
    'is_paid': isPaid ? 1 : 0,
    'unpaid_reason': unpaidReason,
    'updated_by_username': updatedByUsername,
    'updated_by_role': updatedByRole,
    'status_changed_at': statusChangedAt.toUtc().toIso8601String(),
    'change_log': changeLog.trim().isEmpty ? '[]' : changeLog,
  };

  factory SalaryPaymentStatus.fromMap(Map<String, dynamic> map) {
    final changedAt =
        DateTime.tryParse(map['status_changed_at']?.toString() ?? '') ??
        DateTime.now().toUtc();
    return SalaryPaymentStatus(
      id: (map['id'] as num?)?.toInt(),
      employeeId: (map['employee_id'] as num).toInt(),
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      isPaid: (map['is_paid'] as num? ?? 0) != 0,
      unpaidReason: map['unpaid_reason']?.toString() ?? '',
      updatedByUsername: map['updated_by_username']?.toString() ?? '',
      updatedByRole: map['updated_by_role']?.toString() ?? '',
      statusChangedAt: changedAt,
      changeLog: map['change_log']?.toString().trim().isNotEmpty == true
          ? map['change_log'].toString()
          : '[]',
    );
  }
}
