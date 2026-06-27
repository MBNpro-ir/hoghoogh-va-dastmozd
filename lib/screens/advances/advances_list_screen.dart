import 'package:flutter/material.dart';

import '../../models/advance_payment.dart';
import '../../models/employee.dart';
import '../../services/advance_service.dart';
import '../../services/employee_service.dart';
import '../../services/table_sort_preferences.dart';
import '../../utils/app_error_message.dart';
import '../../utils/period_filter_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/floating_nav_safe_area.dart';
import '../../widgets/period_filter_bar.dart';
import '../../widgets/responsive_data_view.dart';
import 'advance_form_screen.dart';

class AdvancesListScreen extends StatefulWidget {
  const AdvancesListScreen({super.key});

  @override
  State<AdvancesListScreen> createState() => _AdvancesListScreenState();
}

class _AdvancesListScreenState extends State<AdvancesListScreen> {
  static const _sortPreferenceKey = 'advances_v2';
  static const _defaultSortColumnIndex = 2;
  static const _defaultSortAscending = false;

  final _advanceService = AdvanceService();
  final _employeeService = EmployeeService();
  final _searchController = TextEditingController();
  final _searchUndoController = UndoHistoryController();

  List<AdvancePayment> _advances = [];
  Map<int, Employee> _employeesMap = {};
  bool _loading = true;
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
    final advances = await _advanceService.getAll();
    final employees = await _employeeService.getAll();
    if (!mounted) return;
    setState(() {
      _advances = advances;
      _employeesMap = {
        for (final employee in employees) employee.id!: employee,
      };
      _loading = false;
    });
  }

  List<AdvancePayment> get _filtered {
    final selected = _selectedPeriod;
    var list = _advances;
    if (selected != null) {
      list = list
          .where(
            (advance) => PeriodFilterHelper.dateIsInPeriod(
              advance.paymentDate,
              selected,
            ),
          )
          .toList();
    }
    final filter = _filter.trim();
    if (filter.isEmpty) return list;
    final english = PersianNumberFormatter.toEnglish(filter);
    return list.where((advance) {
      final employee = _employeesMap[advance.employeeId];
      return (employee?.fullName.contains(filter) ?? false) ||
          (employee?.personnelCode.toString().contains(english) ?? false) ||
          advance.paymentDate.contains(english) ||
          (advance.notes?.contains(filter) ?? false);
    }).toList();
  }

  (int, int)? get _selectedPeriod {
    if (_filterYear == null || _filterMonth == null) return null;
    final period = (_filterYear!, _filterMonth!);
    return _availablePeriods.contains(period) ? period : null;
  }

  List<(int, int)> get _availablePeriods => PeriodFilterHelper.periodsFromDates(
    _advances.map((advance) => advance.paymentDate),
  );

  void _onPeriodChanged((int, int)? value) {
    setState(() {
      _filterYear = value?.$1;
      _filterMonth = value?.$2;
    });
  }

  Future<void> _openForm({AdvancePayment? advance}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdvanceFormScreen(advance: advance)),
    );
    if (changed == true) await _load();
  }

  Future<void> _delete(AdvancePayment advance) async {
    final employee = _employeesMap[advance.employeeId];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مساعده'),
        content: Text(
          'آیا از حذف مساعده ${employee?.fullName ?? ''} به مبلغ '
          '${PersianNumberFormatter.formatRial(advance.amount)} ریال مطمئن هستید؟',
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
    if (confirm == true && advance.id != null) {
      try {
        await _advanceService.delete(advance.id!);
        await _load();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'حذف مساعده انجام نشد. فهرست را تازه کنید.',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
              title: const Text('مساعده کارکنان'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'بازخوانی',
                  onPressed: _load,
                ),
              ],
            ),
      floatingActionButton: FloatingNavSafeArea.padFloatingActionButton(
        context,
        FloatingActionButton.extended(
          heroTag: 'advances-new-fab',
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('مساعده جدید'),
        ),
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const _EmptyAdvances()
                : _buildTable(scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(ColorScheme scheme) {
    final columns = _columns(scheme);
    final items = sortResponsiveItems(
      _filtered,
      columns,
      _sortColumnIndex,
      _sortAscending,
    );
    return ResponsiveDataView<AdvancePayment>(
      items: items,
      columns: columns,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      accentColor: scheme.tertiary,
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
      mobileCardBuilder: (context, advance, index) =>
          _advanceCard(advance, scheme),
    );
  }

  List<ResponsiveTableColumn<AdvancePayment>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'ردیف',
      sortValue: (advance) => _filtered.indexOf(advance),
      cellBuilder: (advance) => Text(
        PersianNumberFormatter.toPersian(
          (_filtered.indexOf(advance) + 1).toString(),
        ),
      ),
    ),
    ResponsiveTableColumn(
      label: 'کد',
      sortValue: (advance) =>
          _employeesMap[advance.employeeId]?.personnelCode ?? 0,
      cellBuilder: (advance) {
        final employee = _employeesMap[advance.employeeId];
        return Text(
          employee != null
              ? PersianNumberFormatter.toPersian(
                  employee.personnelCode.toString(),
                )
              : '—',
        );
      },
    ),
    ResponsiveTableColumn(
      label: 'نام کارمند',
      sortValue: (advance) => _employeesMap[advance.employeeId]?.fullName ?? '',
      cellBuilder: (advance) {
        final employee = _employeesMap[advance.employeeId];
        return Text(employee?.fullName ?? '—');
      },
    ),
    ResponsiveTableColumn(
      label: 'تاریخ',
      sortValue: (advance) => advance.paymentDate,
      cellBuilder: (advance) =>
          Text(PersianNumberFormatter.toPersian(advance.paymentDate)),
    ),
    ResponsiveTableColumn(
      label: 'مبلغ',
      numeric: true,
      sortValue: (advance) => advance.amount,
      cellBuilder: (advance) => CurrencyText(advance.amount),
    ),
    ResponsiveTableColumn(
      label: 'توضیحات',
      sortValue: (advance) => advance.notes ?? '',
      cellBuilder: (advance) => Text(
        advance.notes?.trim().isNotEmpty == true ? advance.notes! : '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    ResponsiveTableColumn(
      label: 'عملیات',
      cellBuilder: (advance) => _actions(advance, scheme),
    ),
  ];

  String _employeeLabel(Employee? employee, {String fallback = '—'}) {
    if (employee == null) return fallback;
    final code = PersianNumberFormatter.toPersian(
      employee.personnelCode.toString(),
    );
    return '${employee.fullName} ($code)';
  }

  Widget _actions(AdvancePayment advance, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_rounded, size: 20, color: scheme.primary),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(advance: advance),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(advance),
        ),
      ],
    );
  }

  Widget _advanceCard(AdvancePayment advance, ColorScheme scheme) {
    final employee = _employeesMap[advance.employeeId];
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
        child: const Icon(Icons.payments_rounded),
      ),
      title: _employeeLabel(employee, fallback: 'کارمند نامشخص'),
      subtitle:
          'تاریخ ${PersianNumberFormatter.toPersian(advance.paymentDate)}',
      metrics: [
        MobileMetric(label: 'مبلغ', value: CurrencyText(advance.amount)),
        if (advance.notes?.trim().isNotEmpty == true)
          MobileMetric(label: 'توضیحات', value: Text(advance.notes!)),
      ],
      actions: [
        IconButton(
          icon: Icon(Icons.edit_rounded, color: scheme.primary),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(advance: advance),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(advance),
        ),
      ],
    );
  }
}

class _EmptyAdvances extends StatelessWidget {
  const _EmptyAdvances();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined, size: 96, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'هنوز مساعده‌ای ثبت نشده است',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          const Text('برای ثبت مساعده جدید روی دکمه «مساعده جدید» کلیک کنید'),
        ],
      ),
    );
  }
}
