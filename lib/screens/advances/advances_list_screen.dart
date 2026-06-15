import 'package:flutter/material.dart';

import '../../models/advance_payment.dart';
import '../../models/employee.dart';
import '../../services/advance_service.dart';
import '../../services/employee_service.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/responsive_data_view.dart';
import 'advance_form_screen.dart';

class AdvancesListScreen extends StatefulWidget {
  const AdvancesListScreen({super.key});

  @override
  State<AdvancesListScreen> createState() => _AdvancesListScreenState();
}

class _AdvancesListScreenState extends State<AdvancesListScreen> {
  final _advanceService = AdvanceService();
  final _employeeService = EmployeeService();

  List<AdvancePayment> _advances = [];
  Map<int, Employee> _employeesMap = {};
  bool _loading = true;
  String _filter = '';
  int _sortColumnIndex = 1;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _load();
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
    final filter = _filter.trim();
    if (filter.isEmpty) return _advances;
    final english = PersianNumberFormatter.toEnglish(filter);
    return _advances.where((advance) {
      final employee = _employeesMap[advance.employeeId];
      return (employee?.fullName.contains(filter) ?? false) ||
          (employee?.personnelCode.toString().contains(english) ?? false) ||
          advance.paymentDate.contains(english);
    }).toList();
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
      await _advanceService.delete(advance.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مساعده کارکنان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بازخوانی',
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('مساعده جدید'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _filter = value),
              decoration: const InputDecoration(
                hintText: 'جستجو بر اساس نام، کد پرسنلی یا تاریخ...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
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
      mobileCardBuilder: (context, advance, index) =>
          _advanceCard(advance, scheme),
    );
  }

  List<ResponsiveTableColumn<AdvancePayment>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'کارمند',
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
      title: employee?.fullName ?? 'کارمند نامشخص',
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
