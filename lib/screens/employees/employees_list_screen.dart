import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../services/sync_service.dart';
import '../../services/table_sort_preferences.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/floating_nav_safe_area.dart';
import '../../widgets/mobile_collapsible_panel.dart';
import '../../widgets/responsive_data_view.dart';
import 'employee_form_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  static const _sortPreferenceKey = 'employees';
  static const _defaultSortColumnIndex = 0;
  static const _defaultSortAscending = true;

  final _service = EmployeeService();
  final _sync = SyncService();
  List<Employee> _employees = [];
  String _filter = '';
  bool _loading = true;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    await _sync.pullLatest(silent: true);
    final list = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _employees = list;
      _loading = false;
    });
  }

  List<Employee> get _filteredEmployees {
    if (_filter.trim().isEmpty) return _employees;
    final rawFilter = _filter.trim();
    final englishFilter = PersianNumberFormatter.toEnglish(rawFilter);
    final persianFilter = PersianNumberFormatter.toPersian(rawFilter);
    bool containsVisible(String value) =>
        PersianNumberFormatter.toPersian(value).contains(persianFilter);
    return _employees.where((e) {
      return containsVisible(e.firstName) ||
          containsVisible(e.lastName) ||
          containsVisible(e.fatherName) ||
          containsVisible(e.jobTitle) ||
          containsVisible(e.position) ||
          e.nationalId.contains(englishFilter) ||
          e.personnelCode.toString().contains(englishFilter);
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
          'تمام فیش‌ها، پیش‌نویس‌ها، وام‌ها، مساعده‌ها و مرخصی‌های این کارمند نیز حذف خواهد شد.',
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
      try {
        await _service.delete(employee.id!);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کارمند با موفقیت حذف شد')),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'حذف کارمند انجام نشد. فهرست را تازه کنید.',
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
    final compactShell = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: compactShell
          ? null
          : AppBar(
              title: const Text('مدیریت کارمندان'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                  tooltip: 'بازخوانی',
                ),
              ],
            ),
      floatingActionButton: FloatingNavSafeArea.padFloatingActionButton(
        context,
        FloatingActionButton.extended(
          heroTag: 'employees-new-fab',
          onPressed: () => _openForm(),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('کارمند جدید'),
        ),
      ),
      body: Column(
        children: [
          _buildFilterArea(compactShell),
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

  Widget _buildFilterArea(bool compact) {
    final search = TextField(
      onChanged: (v) => setState(() => _filter = v),
      inputFormatters: const [PersianDigitsInputFormatter()],
      decoration: const InputDecoration(
        hintText: 'جستجو بر اساس نام، کد ملی یا کد پرسنلی...',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
    final count = _buildEmployeeCount();

    if (compact) {
      return MobileCollapsiblePanel(
        title: 'جستجو و فیلتر',
        icon: Icons.search_rounded,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: search,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          count,
        ],
      ),
    );
  }

  Widget _buildEmployeeCount() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_rounded, color: scheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'تعداد: ${PersianNumberFormatter.toPersian(_filteredEmployees.length.toString())} نفر',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
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
      mobileHeader: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Center(child: _buildEmployeeCount()),
      ),
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
      cellBuilder: (e) => Text(PersianNumberFormatter.toPersian(e.firstName)),
    ),
    ResponsiveTableColumn(
      label: 'نام خانوادگی',
      sortValue: (e) => e.lastName,
      cellBuilder: (e) => Text(PersianNumberFormatter.toPersian(e.lastName)),
    ),
    ResponsiveTableColumn(
      label: 'کد ملی',
      sortValue: (e) => e.nationalId,
      cellBuilder: (e) => Text(PersianNumberFormatter.toPersian(e.nationalId)),
    ),
    ResponsiveTableColumn(
      label: 'وضعیت',
      sortValue: (e) => e.isActive ? 0 : 1,
      cellBuilder: (e) => Chip(
        label: Text(e.isActive ? 'مشغول به کار' : 'ترک کار'),
        avatar: Icon(
          e.isActive ? Icons.work_rounded : Icons.work_off_rounded,
          size: 16,
        ),
      ),
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
        e.isActive ? Icons.work_rounded : Icons.work_off_rounded,
        color: e.isActive ? AppTheme.successColor : scheme.error,
      ),
      metrics: [
        MobileMetric(
          label: 'وضعیت',
          value: Text(e.isActive ? 'مشغول' : 'ترک کار'),
        ),
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
