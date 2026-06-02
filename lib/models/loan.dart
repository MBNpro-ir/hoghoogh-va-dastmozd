/// مدل وام
class Loan {
  final int? id;
  final int employeeId;
  final int loanNumber; // شماره وام (وام چندم برای این کارمند)
  final double amount; // مبلغ وام
  final double installmentAmount; // مبلغ هر قسط
  final int totalInstallments; // تعداد کل اقساط
  final int paidInstallments; // تعداد اقساط پرداخت شده
  final String startDate; // تاریخ شروع (یا تاریخ اولین قسط) - شمسی
  final String? endDate; // تاریخ اتمام واقعی
  final String? notes; // توضیحات
  final bool isActive; // فعال (در حال کسر)

  Loan({
    this.id,
    required this.employeeId,
    required this.loanNumber,
    required this.amount,
    required this.installmentAmount,
    required this.totalInstallments,
    this.paidInstallments = 0,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
  });

  /// تعداد اقساط باقیمانده
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// مبلغ کسر شده
  double get deductedAmount => installmentAmount * paidInstallments;

  /// مبلغ باقیمانده جهت کسر از حقوق
  double get remainingAmount =>
      (amount - deductedAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'loan_number': loanNumber,
    'amount': amount,
    'installment_amount': installmentAmount,
    'total_installments': totalInstallments,
    'paid_installments': paidInstallments,
    'start_date': startDate,
    'end_date': endDate,
    'notes': notes,
    'is_active': isActive ? 1 : 0,
  };

  factory Loan.fromMap(Map<String, dynamic> map) => Loan(
    id: map['id'] as int?,
    employeeId: map['employee_id'] as int,
    loanNumber: map['loan_number'] as int? ?? 1,
    amount: (map['amount'] as num).toDouble(),
    installmentAmount: (map['installment_amount'] as num).toDouble(),
    totalInstallments: map['total_installments'] as int,
    paidInstallments: map['paid_installments'] as int? ?? 0,
    startDate: map['start_date'] as String,
    endDate: map['end_date'] as String?,
    notes: map['notes'] as String?,
    isActive: (map['is_active'] as int? ?? 1) == 1,
  );

  Loan copyWith({
    int? id,
    int? employeeId,
    int? loanNumber,
    double? amount,
    double? installmentAmount,
    int? totalInstallments,
    int? paidInstallments,
    String? startDate,
    String? endDate,
    String? notes,
    bool? isActive,
  }) => Loan(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    loanNumber: loanNumber ?? this.loanNumber,
    amount: amount ?? this.amount,
    installmentAmount: installmentAmount ?? this.installmentAmount,
    totalInstallments: totalInstallments ?? this.totalInstallments,
    paidInstallments: paidInstallments ?? this.paidInstallments,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
  );
}
