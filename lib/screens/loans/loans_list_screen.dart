import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/responsive_data_view.dart';
import 'loan_form_screen.dart';

class LoansListScreen extends StatefulWidget {
  const LoansListScreen({super.key});

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends State<LoansListScreen> {
  final _loanService = LoanService();
  final _employeeService = EmployeeService();
  List<Loan> _loans = [];
  Map<int, Employee> _employeesMap = {};
  bool _loading = true;
  bool _onlyActive = false;
  String _filter = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loans = await _loanService.getAll();
    final employees = await _employeeService.getAll();
    if (!mounted) return;
    setState(() {
      _loans = loans;
      _employeesMap = {for (var e in employees) e.id!: e};
      _loading = false;
    });
  }

  List<Loan> get _filtered {
    var list = _loans;
    if (_onlyActive) {
      list = list.where((l) => l.isActive).toList();
    }
    if (_filter.trim().isNotEmpty) {
      final f = _filter.trim();
      list = list.where((l) {
        final emp = _employeesMap[l.employeeId];
        if (emp == null) return false;
        return emp.fullName.contains(f) ||
            emp.personnelCode.toString().contains(
              PersianNumberFormatter.toEnglish(f),
            );
      }).toList();
    }
    return list;
  }

  Future<void> _openForm({Loan? loan}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoanFormScreen(loan: loan)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Loan loan) async {
    final emp = _employeesMap[loan.employeeId];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف وام'),
        content: Text(
          'آیا از حذف وام شماره ${PersianNumberFormatter.toPersian(loan.loanNumber.toString())} '
          '${emp != null ? "کارمند ${emp.fullName}" : ""} مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && loan.id != null) {
      await _loanService.delete(loan.id!);
      await _load();
    }
  }

  Future<void> _payInstallment(Loan loan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت قسط'),
        content: Text(
          'آیا قسط شماره ${PersianNumberFormatter.toPersian((loan.paidInstallments + 1).toString())} '
          'به مبلغ ${PersianNumberFormatter.formatRial(loan.installmentAmount)} ریال پرداخت شد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ثبت قسط'),
          ),
        ],
      ),
    );
    if (confirm == true && loan.id != null) {
      await _loanService.recordInstallmentPayment(loan.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت وام و اقساط'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'بازخوانی',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('وام جدید'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    decoration: const InputDecoration(
                      hintText: 'جستجو بر اساس نام یا کد پرسنلی...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(_onlyActive ? 'فقط وام‌های فعال' : 'همه وام‌ها'),
                  selected: _onlyActive,
                  onSelected: (v) => setState(() => _onlyActive = v),
                  selectedColor: scheme.primaryContainer,
                  showCheckmark: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const _EmptyLoans()
                : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final scheme = Theme.of(context).colorScheme;
    final columns = _columns(scheme);
    final items = sortResponsiveItems(
      _filtered,
      columns,
      _sortColumnIndex,
      _sortAscending,
    );
    return ResponsiveDataView<Loan>(
      items: items,
      columns: columns,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      accentColor: scheme.primary,
      onSortColumnChanged: (index) => setState(() {
        if (_sortColumnIndex == index) {
          _sortAscending = !_sortAscending;
        } else {
          _sortColumnIndex = index;
          _sortAscending = true;
        }
      }),
      onSortDirectionChanged: (ascending) =>
          setState(() => _sortAscending = ascending),
      mobileCardBuilder: (context, loan, index) => _loanCard(loan, scheme),
    );
  }

  List<ResponsiveTableColumn<Loan>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'کارمند',
      sortValue: (loan) => _employeesMap[loan.employeeId]?.fullName ?? '',
      cellBuilder: (loan) {
        final emp = _employeesMap[loan.employeeId];
        return Text(
          emp != null
              ? '${emp.fullName} (${PersianNumberFormatter.toPersian(emp.personnelCode.toString())})'
              : '—',
        );
      },
    ),
    ResponsiveTableColumn(
      label: 'شماره وام',
      numeric: true,
      sortValue: (loan) => loan.loanNumber,
      cellBuilder: (loan) =>
          Text(PersianNumberFormatter.toPersian(loan.loanNumber.toString())),
    ),
    ResponsiveTableColumn(
      label: 'مبلغ وام',
      numeric: true,
      sortValue: (loan) => loan.amount,
      cellBuilder: (loan) => CurrencyText(loan.amount),
    ),
    ResponsiveTableColumn(
      label: 'مبلغ هر قسط',
      numeric: true,
      sortValue: (loan) => loan.installmentAmount,
      cellBuilder: (loan) => CurrencyText(loan.installmentAmount),
    ),
    ResponsiveTableColumn(
      label: 'تعداد اقساط',
      numeric: true,
      sortValue: (loan) => loan.totalInstallments,
      cellBuilder: (loan) => Text(
        PersianNumberFormatter.toPersian(loan.totalInstallments.toString()),
      ),
    ),
    ResponsiveTableColumn(
      label: 'پرداخت شده',
      numeric: true,
      sortValue: (loan) => loan.paidInstallments,
      cellBuilder: (loan) => Text(
        PersianNumberFormatter.toPersian(loan.paidInstallments.toString()),
      ),
    ),
    ResponsiveTableColumn(
      label: 'باقیمانده',
      numeric: true,
      sortValue: (loan) => loan.remainingInstallments,
      cellBuilder: (loan) => Text(
        PersianNumberFormatter.toPersian(loan.remainingInstallments.toString()),
        style: TextStyle(
          color: loan.remainingInstallments == 0 ? Colors.green : null,
          fontWeight: loan.remainingInstallments == 0 ? FontWeight.w700 : null,
        ),
      ),
    ),
    ResponsiveTableColumn(
      label: 'مبلغ باقیمانده',
      numeric: true,
      sortValue: (loan) => loan.remainingAmount,
      cellBuilder: (loan) => CurrencyText(loan.remainingAmount),
    ),
    ResponsiveTableColumn(
      label: 'تاریخ شروع',
      sortValue: (loan) => loan.startDate,
      cellBuilder: (loan) =>
          Text(PersianNumberFormatter.toPersian(loan.startDate)),
    ),
    ResponsiveTableColumn(
      label: 'وضعیت',
      sortValue: (loan) => loan.isActive ? 1 : 0,
      cellBuilder: (loan) => _statusPill(loan),
    ),
    ResponsiveTableColumn(
      label: 'عملیات',
      cellBuilder: (loan) => _loanActions(loan, scheme),
    ),
  ];

  Widget _statusPill(Loan loan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: loan.isActive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        loan.isActive ? 'فعال' : 'تسویه شده',
        style: TextStyle(
          color: loan.isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _loanActions(Loan loan, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loan.isActive)
          IconButton(
            icon: const Icon(
              Icons.payment_rounded,
              size: 20,
              color: Colors.green,
            ),
            tooltip: 'ثبت قسط بعدی',
            onPressed: () => _payInstallment(loan),
          ),
        IconButton(
          icon: Icon(Icons.edit_rounded, size: 20, color: scheme.primary),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(loan: loan),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(loan),
        ),
      ],
    );
  }

  Widget _loanCard(Loan loan, ColorScheme scheme) {
    final emp = _employeesMap[loan.employeeId];
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: loan.isActive
            ? Colors.green.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest,
        child: Icon(
          loan.isActive
              ? Icons.account_balance_wallet_rounded
              : Icons.done_all_rounded,
          color: loan.isActive
              ? Colors.green.shade700
              : scheme.onSurfaceVariant,
        ),
      ),
      title: emp?.fullName ?? 'کارمند نامشخص',
      subtitle:
          'وام ${PersianNumberFormatter.toPersian(loan.loanNumber.toString())} • شروع ${PersianNumberFormatter.toPersian(loan.startDate)}',
      trailing: _statusPill(loan),
      metrics: [
        MobileMetric(label: 'مبلغ وام', value: CurrencyText(loan.amount)),
        MobileMetric(
          label: 'هر قسط',
          value: CurrencyText(loan.installmentAmount),
        ),
        MobileMetric(
          label: 'باقیمانده',
          value: Text(
            PersianNumberFormatter.toPersian(
              loan.remainingInstallments.toString(),
            ),
          ),
          color: loan.remainingInstallments == 0
              ? Colors.green
              : scheme.primary,
        ),
        MobileMetric(
          label: 'مانده ریالی',
          value: CurrencyText(loan.remainingAmount),
        ),
      ],
      actions: [
        if (loan.isActive)
          IconButton(
            icon: const Icon(Icons.payment_rounded, color: Colors.green),
            tooltip: 'ثبت قسط بعدی',
            onPressed: () => _payInstallment(loan),
          ),
        IconButton(
          icon: Icon(Icons.edit_rounded, color: scheme.primary),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(loan: loan),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(loan),
        ),
      ],
    );
  }
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 96,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'هنوز وامی ثبت نشده است',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('برای ثبت وام جدید روی دکمه «وام جدید» کلیک کنید'),
        ],
      ),
    );
  }
}
