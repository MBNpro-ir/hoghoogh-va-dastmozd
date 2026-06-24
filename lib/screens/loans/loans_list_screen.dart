import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../services/table_sort_preferences.dart';
import '../../utils/app_error_message.dart';
import '../../utils/period_filter_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/period_filter_bar.dart';
import '../../widgets/responsive_data_view.dart';
import 'loan_form_screen.dart';

class LoansListScreen extends StatefulWidget {
  const LoansListScreen({super.key});

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends State<LoansListScreen> {
  static const _sortPreferenceKey = 'loans_v2';
  static const _defaultSortColumnIndex = 1;
  static const _defaultSortAscending = true;

  final _loanService = LoanService();
  final _employeeService = EmployeeService();
  final _searchController = TextEditingController();
  final _searchUndoController = UndoHistoryController();
  List<Loan> _loans = [];
  Map<int, Employee> _employeesMap = {};
  bool _loading = true;
  bool _onlyActive = false;
  String _filter = '';
  int? _filterYear;
  int? _filterMonth;
  int _sortColumnIndex = _defaultSortColumnIndex;
  bool _sortAscending = _defaultSortAscending;

  @override
  void initState() {
    super.initState();
    final cachedSort = TableSortPreferences.cached(
      _sortPreferenceKey,
      defaultColumnIndex: _defaultSortColumnIndex,
      defaultAscending: _defaultSortAscending,
    );
    _sortColumnIndex = cachedSort.columnIndex;
    _sortAscending = cachedSort.ascending;
    _restoreSortState();
    _load();
  }

  Future<void> _restoreSortState() async {
    final sort = await TableSortPreferences.load(
      _sortPreferenceKey,
      defaultColumnIndex: _defaultSortColumnIndex,
      defaultAscending: _defaultSortAscending,
    );
    if (!mounted) return;
    setState(() {
      _sortColumnIndex = sort.columnIndex;
      _sortAscending = sort.ascending;
    });
  }

  void _saveSortState() {
    TableSortPreferences.save(
      _sortPreferenceKey,
      columnIndex: _sortColumnIndex,
      ascending: _sortAscending,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchUndoController.dispose();
    super.dispose();
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
    final selected = _selectedPeriod;
    if (selected != null) {
      list = list
          .where((loan) => _loanAppliesToPeriod(loan, selected))
          .toList();
    }
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
            ) ||
            l.startDate.contains(PersianNumberFormatter.toEnglish(f)) ||
            (l.notes?.contains(f) ?? false);
      }).toList();
    }
    return list;
  }

  (int, int)? get _selectedPeriod {
    if (_filterYear == null || _filterMonth == null) return null;
    final period = (_filterYear!, _filterMonth!);
    return _availablePeriods.contains(period) ? period : null;
  }

  List<(int, int)> get _availablePeriods {
    final periods = <(int, int)>{};
    for (final loan in _loans) {
      final start = PeriodFilterHelper.parsePeriod(loan.startDate);
      if (start == null) continue;
      final startIndex = PeriodFilterHelper.periodIndex(start);
      final months = loan.totalInstallments.ceil().clamp(1, 240).toInt();
      for (var offset = 0; offset < months; offset++) {
        periods.add(PeriodFilterHelper.periodFromIndex(startIndex + offset));
      }
    }
    final sorted = periods.toList();
    sorted.sort(
      (a, b) => PeriodFilterHelper.periodIndex(
        b,
      ).compareTo(PeriodFilterHelper.periodIndex(a)),
    );
    return sorted;
  }

  void _onPeriodChanged((int, int)? value) {
    setState(() {
      _filterYear = value?.$1;
      _filterMonth = value?.$2;
    });
  }

  bool _loanAppliesToPeriod(Loan loan, (int, int) period) {
    final start = PeriodFilterHelper.parsePeriod(loan.startDate);
    if (start == null) return false;
    final selectedIndex = PeriodFilterHelper.periodIndex(period);
    final startIndex = PeriodFilterHelper.periodIndex(start);
    final installmentMonths = loan.totalInstallments
        .ceil()
        .clamp(1, 10000)
        .toInt();
    return selectedIndex >= startIndex &&
        selectedIndex < startIndex + installmentMonths;
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
      try {
        await _loanService.delete(loan.id!);
        await _load();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'حذف وام انجام نشد. فهرست را تازه کنید.',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _payInstallment(Loan loan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت قسط'),
        content: Text(
          'آیا قسط شماره ${PersianNumberFormatter.formatDecimal(loan.paidInstallments + loan.nextInstallmentStep)} '
          'از ${PersianNumberFormatter.formatDecimal(loan.totalInstallments)} '
          'به مبلغ ${PersianNumberFormatter.formatRial(loan.nextInstallmentAmount)} ریال پرداخت شد؟',
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
    final compactShell = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: compactShell
          ? null
          : AppBar(
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
        heroTag: 'loans-new-fab',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('وام جدید'),
      ),
      body: Column(
        children: [
          PeriodFilterBar(
            selectedPeriod: _selectedPeriod,
            availablePeriods: _availablePeriods,
            onPeriodChanged: _onPeriodChanged,
            searchController: _searchController,
            searchUndoController: _searchUndoController,
            onSearchChanged: (value) => setState(() => _filter = value),
            searchHint: 'جستجو بر اساس نام، کد پرسنلی، تاریخ یا توضیحات...',
            trailing: FilterChip(
              label: Text(_onlyActive ? 'فقط وام‌های فعال' : 'همه وام‌ها'),
              labelStyle: TextStyle(
                color: _onlyActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              selected: _onlyActive,
              onSelected: (v) => setState(() => _onlyActive = v),
              selectedColor: scheme.primaryContainer,
              backgroundColor: scheme.surfaceContainerLowest,
              checkmarkColor: scheme.onPrimaryContainer,
              side: BorderSide(color: scheme.outlineVariant),
              showCheckmark: true,
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
      onSortColumnChanged: (index) {
        setState(() {
          if (_sortColumnIndex == index) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumnIndex = index;
            _sortAscending = true;
          }
        });
        _saveSortState();
      },
      onSortDirectionChanged: (ascending) {
        setState(() => _sortAscending = ascending);
        _saveSortState();
      },
      mobileCardBuilder: (context, loan, index) => _loanCard(loan, scheme),
    );
  }

  List<ResponsiveTableColumn<Loan>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'ردیف',
      sortValue: (loan) => _filtered.indexOf(loan),
      cellBuilder: (loan) => Text(
        PersianNumberFormatter.toPersian(
          (_filtered.indexOf(loan) + 1).toString(),
        ),
      ),
    ),
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
      cellBuilder: (loan) =>
          Text(PersianNumberFormatter.formatDecimal(loan.totalInstallments)),
    ),
    ResponsiveTableColumn(
      label: 'پرداخت شده',
      numeric: true,
      sortValue: (loan) => loan.paidInstallments,
      cellBuilder: (loan) =>
          Text(PersianNumberFormatter.formatDecimal(loan.paidInstallments)),
    ),
    ResponsiveTableColumn(
      label: 'باقیمانده',
      numeric: true,
      sortValue: (loan) => loan.remainingInstallments,
      cellBuilder: (loan) => Text(
        PersianNumberFormatter.formatDecimal(loan.remainingInstallments),
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
            PersianNumberFormatter.formatDecimal(loan.remainingInstallments),
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
