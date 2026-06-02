import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/responsive_data_view.dart';
import 'employee_form_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final _service = EmployeeService();
  List<Employee> _employees = [];
  String _filter = '';
  bool _loading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _employees = list;
      _loading = false;
    });
  }

  List<Employee> get _filteredEmployees {
    if (_filter.trim().isEmpty) return _employees;
    final f = PersianNumberFormatter.toEnglish(_filter.trim());
    return _employees.where((e) {
      return e.firstName.contains(_filter) ||
          e.lastName.contains(_filter) ||
          e.nationalId.contains(f) ||
          e.personnelCode.toString().contains(f);
    }).toList();
  }

  Future<void> _openForm({Employee? employee}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کارمند'),
        content: Text(
          'آیا از حذف کارمند «${employee.fullName}» مطمئن هستید؟\n'
          'تمام وام‌ها و فیش‌های حقوق این کارمند نیز حذف خواهد شد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && employee.id != null) {
      await _service.delete(employee.id!);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کارمند با موفقیت حذف شد')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کارمندان'),
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
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('کارمند جدید'),
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
                      hintText: 'جستجو بر اساس نام، کد ملی یا کد پرسنلی...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تعداد: ${PersianNumberFormatter.toPersian(_filteredEmployees.length.toString())} نفر',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                ? const _EmptyState()
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
      _filteredEmployees,
      columns,
      _sortColumnIndex,
      _sortAscending,
    );
    return ResponsiveDataView<Employee>(
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
      mobileCardBuilder: (context, e, index) => _employeeCard(e, scheme),
    );
  }

  List<ResponsiveTableColumn<Employee>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'کد پرسنلی',
      sortValue: (e) => e.personnelCode,
      cellBuilder: (e) =>
          Text(PersianNumberFormatter.toPersian(e.personnelCode.toString())),
    ),
    ResponsiveTableColumn(
      label: 'نام',
      sortValue: (e) => e.firstName,
      cellBuilder: (e) => Text(e.firstName),
    ),
    ResponsiveTableColumn(
      label: 'نام خانوادگی',
      sortValue: (e) => e.lastName,
      cellBuilder: (e) => Text(e.lastName),
    ),
    ResponsiveTableColumn(
      label: 'کد ملی',
      sortValue: (e) => e.nationalId,
      cellBuilder: (e) => Text(PersianNumberFormatter.toPersian(e.nationalId)),
    ),
    ResponsiveTableColumn(
      label: 'تاهل',
      sortValue: (e) => e.isMarried ? 1 : 0,
      cellBuilder: (e) => Icon(
        e.isMarried ? Icons.check_circle : Icons.cancel,
        color: e.isMarried ? Colors.green : Colors.grey,
        size: 20,
      ),
    ),
    ResponsiveTableColumn(
      label: 'فرزند',
      numeric: true,
      sortValue: (e) => e.childrenCount,
      cellBuilder: (e) =>
          Text(PersianNumberFormatter.toPersian(e.childrenCount.toString())),
    ),
    ResponsiveTableColumn(
      label: 'دستمزد روزانه ۱۴۰۵',
      numeric: true,
      sortValue: (e) => e.dailyWage1405,
      cellBuilder: (e) => CurrencyText(e.dailyWage1405),
    ),
    ResponsiveTableColumn(
      label: 'حقوق پایه (۳۰روز)',
      numeric: true,
      sortValue: (e) => e.baseSalary30Days,
      cellBuilder: (e) => CurrencyText(e.baseSalary30Days),
    ),
    ResponsiveTableColumn(
      label: 'تاریخ استخدام',
      sortValue: (e) => e.startDate,
      cellBuilder: (e) => Text(PersianNumberFormatter.toPersian(e.startDate)),
    ),
    ResponsiveTableColumn(
      label: 'عملیات',
      cellBuilder: (e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_rounded, size: 20, color: scheme.primary),
            tooltip: 'ویرایش',
            onPressed: () => _openForm(employee: e),
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
            tooltip: 'حذف',
            onPressed: () => _delete(e),
          ),
        ],
      ),
    ),
  ];

  Widget _employeeCard(Employee e, ColorScheme scheme) {
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
        child: Text(
          PersianNumberFormatter.toPersian(e.personnelCode.toString()),
        ),
      ),
      title: e.fullName,
      subtitle:
          'کد ملی ${PersianNumberFormatter.toPersian(e.nationalId)} • شروع ${PersianNumberFormatter.toPersian(e.startDate)}',
      trailing: Icon(
        e.isMarried ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: e.isMarried ? AppTheme.errorColor : scheme.outline,
      ),
      metrics: [
        MobileMetric(
          label: 'فرزند',
          value: Text(
            PersianNumberFormatter.toPersian(e.childrenCount.toString()),
          ),
        ),
        MobileMetric(
          label: 'دستمزد روزانه',
          value: CurrencyText(e.dailyWage1405),
        ),
        MobileMetric(
          label: 'حقوق ۳۰ روز',
          value: CurrencyText(e.baseSalary30Days),
        ),
      ],
      actions: [
        IconButton(
          icon: Icon(Icons.edit_rounded, color: scheme.primary),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(employee: e),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(e),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 96, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'هنوز کارمندی ثبت نشده است',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('برای شروع روی دکمه «کارمند جدید» کلیک کنید'),
        ],
      ),
    );
  }
}
