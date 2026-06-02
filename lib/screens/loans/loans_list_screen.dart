import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
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
            emp.personnelCode.toString().contains(PersianNumberFormatter.toEnglish(f));
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(scheme.tertiaryContainer),
              headingTextStyle: TextStyle(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(fontSize: 13),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('کارمند')),
                DataColumn(label: Text('شماره وام')),
                DataColumn(label: Text('مبلغ وام'), numeric: true),
                DataColumn(label: Text('مبلغ هر قسط'), numeric: true),
                DataColumn(label: Text('تعداد اقساط'), numeric: true),
                DataColumn(label: Text('پرداخت شده'), numeric: true),
                DataColumn(label: Text('باقیمانده'), numeric: true),
                DataColumn(label: Text('مبلغ باقیمانده'), numeric: true),
                DataColumn(label: Text('تاریخ شروع')),
                DataColumn(label: Text('وضعیت')),
                DataColumn(label: Text('عملیات')),
              ],
              rows: _filtered.map((loan) {
                final emp = _employeesMap[loan.employeeId];
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        emp != null
                            ? '${emp.fullName} (${PersianNumberFormatter.toPersian(emp.personnelCode.toString())})'
                            : '—',
                      ),
                    ),
                    DataCell(Text(PersianNumberFormatter.toPersian(loan.loanNumber.toString()))),
                    DataCell(CurrencyText(loan.amount)),
                    DataCell(CurrencyText(loan.installmentAmount)),
                    DataCell(Text(PersianNumberFormatter.toPersian(loan.totalInstallments.toString()))),
                    DataCell(Text(PersianNumberFormatter.toPersian(loan.paidInstallments.toString()))),
                    DataCell(
                      Text(
                        PersianNumberFormatter.toPersian(loan.remainingInstallments.toString()),
                        style: TextStyle(
                          color: loan.remainingInstallments == 0 ? Colors.green : null,
                          fontWeight:
                              loan.remainingInstallments == 0 ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                    DataCell(CurrencyText(loan.remainingAmount)),
                    DataCell(Text(PersianNumberFormatter.toPersian(loan.startDate))),
                    DataCell(
                      Container(
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
                      ),
                    ),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loan.isActive)
                          IconButton(
                            icon: const Icon(Icons.payment_rounded, size: 20, color: Colors.green),
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
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
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
          Icon(Icons.account_balance_wallet_outlined, size: 96, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'هنوز وامی ثبت نشده است',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('برای ثبت وام جدید روی دکمه «وام جدید» کلیک کنید'),
        ],
      ),
    );
  }
}
