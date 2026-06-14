class AdvancePayment {
  final int? id;
  final int employeeId;
  final double amount;
  final String paymentDate;
  final String? notes;

  AdvancePayment({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'amount': amount,
    'payment_date': paymentDate,
    'notes': notes,
  };

  factory AdvancePayment.fromMap(Map<String, dynamic> map) => AdvancePayment(
    id: map['id'] as int?,
    employeeId: map['employee_id'] as int,
    amount: (map['amount'] as num).toDouble(),
    paymentDate: map['payment_date'] as String? ?? '',
    notes: map['notes'] as String?,
  );

  AdvancePayment copyWith({
    int? id,
    int? employeeId,
    double? amount,
    String? paymentDate,
    String? notes,
  }) => AdvancePayment(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    amount: amount ?? this.amount,
    paymentDate: paymentDate ?? this.paymentDate,
    notes: notes ?? this.notes,
  );
}
