class EmployeeLeave {
  static const typeAnnual = 'annual';
  static const typeSick = 'sick';
  static const statusApproved = 'approved';
  static const statusPending = 'pending';

  final int? id;
  final int employeeId;
  final String fromDate;
  final String toDate;
  final double days;
  final String type;
  final String status;
  final String? notes;

  const EmployeeLeave({
    this.id,
    required this.employeeId,
    required this.fromDate,
    required this.toDate,
    required this.days,
    this.type = typeAnnual,
    this.status = statusApproved,
    this.notes,
  });

  bool get isSick => _normalizeType(type) == typeSick;

  bool get isApproved => _normalizeStatus(status) == statusApproved;

  String get normalizedType => _normalizeType(type);

  String get normalizedStatus => _normalizeStatus(status);

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'from_date': fromDate,
    'to_date': toDate,
    'days': days,
    'type': normalizedType,
    'status': normalizedStatus,
    'notes': notes,
  };

  factory EmployeeLeave.fromMap(Map<String, dynamic> map) => EmployeeLeave(
    id: map['id'] as int?,
    employeeId: (map['employee_id'] as num).toInt(),
    fromDate: map['from_date'] as String? ?? '',
    toDate: map['to_date'] as String? ?? map['from_date'] as String? ?? '',
    days: (map['days'] as num?)?.toDouble() ?? 0,
    type: _normalizeType(map['type']?.toString()),
    status: _normalizeStatus(map['status']?.toString()),
    notes: map['notes'] as String?,
  );

  EmployeeLeave copyWith({
    int? id,
    int? employeeId,
    String? fromDate,
    String? toDate,
    double? days,
    String? type,
    String? status,
    String? notes,
  }) => EmployeeLeave(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    days: days ?? this.days,
    type: type ?? this.type,
    status: status ?? this.status,
    notes: notes ?? this.notes,
  );

  static String _normalizeType(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      typeSick || 'sick_leave' || 'medical' || 'استعلاجی' => typeSick,
      _ => typeAnnual,
    };
  }

  static String _normalizeStatus(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      statusPending || 'در انتظار' || 'pending_review' => statusPending,
      _ => statusApproved,
    };
  }
}
