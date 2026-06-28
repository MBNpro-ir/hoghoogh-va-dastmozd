import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/employee_leave.dart';
import '../../services/employee_leave_service.dart';
import '../../services/employee_service.dart';
import '../../services/table_sort_preferences.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/period_filter_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/floating_nav_safe_area.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/period_filter_bar.dart';
import '../../widgets/responsive_data_view.dart';
import 'employee_leave_form_screen.dart';

class EmployeeLeavesScreen extends StatefulWidget {
  const EmployeeLeavesScreen({super.key});

  @override
  State<EmployeeLeavesScreen> createState() => _EmployeeLeavesScreenState();
}

class _EmployeeLeavesScreenState extends State<EmployeeLeavesScreen> {
  static const _sortPreferenceKey = 'employee_leaves_v2';
  static const _defaultSortColumnIndex = 3;
  static const _defaultSortAscending = false;

  final _leaveService = EmployeeLeaveService();
  final _employeeService = EmployeeService();
  final _searchController = TextEditingController();
  final _searchUndoController = UndoHistoryController();

  List<EmployeeLeave> _leaves = [];
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
    final leaves = await _leaveService.getAll();
    final employees = await _employeeService.getAll();
    if (!mounted) return;
    setState(() {
      _leaves = leaves;
      _employeesMap = {
        for (final employee in employees) employee.id!: employee,
      };
      _loading = false;
    });
  }

  List<EmployeeLeave> get _filtered {
    final selected = _selectedPeriod;
    var list = _leaves;
    if (selected != null) {
      list = list
          .where(
            (leave) =>
                PeriodFilterHelper.dateIsInPeriod(leave.fromDate, selected),
          )
          .toList();
    }
    final filter = _filter.trim();
    if (filter.isEmpty) return list;
    final english = PersianNumberFormatter.toEnglish(filter);
    return list.where((leave) {
      final employee = _employeesMap[leave.employeeId];
      return (employee?.fullName.contains(filter) ?? false) ||
          (employee?.personnelCode.toString().contains(english) ?? false) ||
          leave.fromDate.contains(english) ||
          leave.toDate.contains(english) ||
          (leave.notes?.contains(filter) ?? false);
    }).toList();
  }

  (int, int)? get _selectedPeriod {
    if (_filterYear == null || _filterMonth == null) return null;
    final period = (_filterYear!, _filterMonth!);
    return _availablePeriods.contains(period) ? period : null;
  }

  List<(int, int)> get _availablePeriods => PeriodFilterHelper.periodsFromDates(
    _leaves.map((leave) => leave.fromDate),
  );

  void _onPeriodChanged((int, int)? value) {
    setState(() {
      _filterYear = value?.$1;
      _filterMonth = value?.$2;
    });
  }

  double get _annualTotal =>
      _filtered.fold(0, (sum, leave) => leave.isSick ? sum : sum + leave.days);

  double get _sickTotal =>
      _filtered.fold(0, (sum, leave) => leave.isSick ? sum + leave.days : sum);

  double get _approvedTotal => _filtered.fold(
    0,
    (sum, leave) => leave.isApproved ? sum + leave.days : sum,
  );

  Future<void> _openForm({EmployeeLeave? leave}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeeLeaveFormScreen(leave: leave)),
    );
    if (changed == true) await _load();
  }

  Future<void> _delete(EmployeeLeave leave) async {
    final employee = _employeesMap[leave.employeeId];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مرخصی'),
        content: Text(
          'آیا از حذف مرخصی ${employee?.fullName ?? ''} به مدت '
          '${_formatDays(leave.days)} روز مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && leave.id != null) {
      try {
        await _leaveService.delete(leave.id!);
        await _load();
      } catch (error) {
        if (!mounted) return;
        AppNotification.error(
          context,
          AppErrorMessage.from(
            error,
            fallback: 'حذف مرخصی انجام نشد. فهرست را تازه کنید.',
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
              title: const Text('مرخصی کارکنان'),
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
          heroTag: 'leaves-new-fab',
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('مرخصی جدید'),
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
          if (!compactShell) _summary(scheme),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const _EmptyLeaves()
                : _buildTable(
                    scheme,
                    mobileHeader: compactShell ? _summary(scheme) : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summary(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryCard(
            'کل مرخصی استحقاقی',
            '${_formatDays(_annualTotal)} روز',
            scheme.secondary,
          ),
          _summaryCard(
            'کل استعلاجی',
            '${_formatDays(_sickTotal)} روز',
            scheme.primary,
          ),
          _summaryCard(
            'قابل لحاظ در حقوق',
            '${_formatDays(_approvedTotal)} روز',
            AppTheme.successColor,
          ),
          _summaryCard(
            'دوره انتخابی',
            _selectedPeriod == null
                ? 'همه دوره‌ها'
                : PeriodFilterHelper.label(_selectedPeriod!),
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      width: 190,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(ColorScheme scheme, {Widget? mobileHeader}) {
    final columns = _columns(scheme);
    final items = sortResponsiveItems(
      _filtered,
      columns,
      _sortColumnIndex,
      _sortAscending,
    );
    return ResponsiveDataView<EmployeeLeave>(
      items: items,
      columns: columns,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      accentColor: AppTheme.warningColor,
      mobileHeader: mobileHeader,
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
      mobileCardBuilder: (context, leave, index) => _leaveCard(leave, scheme),
    );
  }

  List<ResponsiveTableColumn<EmployeeLeave>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'ردیف',
      sortValue: (leave) => _filtered.indexOf(leave),
      cellBuilder: (leave) => Text(
        PersianNumberFormatter.toPersian(
          (_filtered.indexOf(leave) + 1).toString(),
        ),
      ),
    ),
    ResponsiveTableColumn(
      label: 'کد',
      sortValue: (leave) => _employeesMap[leave.employeeId]?.personnelCode ?? 0,
      cellBuilder: (leave) {
        final employee = _employeesMap[leave.employeeId];
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
      sortValue: (leave) => _employeesMap[leave.employeeId]?.fullName ?? '',
      cellBuilder: (leave) =>
          Text(_employeesMap[leave.employeeId]?.fullName ?? '—'),
    ),
    ResponsiveTableColumn(
      label: 'نوع',
      sortValue: (leave) => leave.normalizedType,
      cellBuilder: (leave) => _typePill(leave, scheme),
    ),
    ResponsiveTableColumn(
      label: 'از تاریخ',
      sortValue: (leave) => leave.fromDate,
      cellBuilder: (leave) =>
          Text(PersianNumberFormatter.toPersian(leave.fromDate)),
    ),
    ResponsiveTableColumn(
      label: 'تا تاریخ',
      sortValue: (leave) => leave.toDate,
      cellBuilder: (leave) =>
          Text(PersianNumberFormatter.toPersian(leave.toDate)),
    ),
    ResponsiveTableColumn(
      label: 'مدت',
      numeric: true,
      sortValue: (leave) => leave.days,
      cellBuilder: (leave) => Text('${_formatDays(leave.days)} روز'),
    ),
    ResponsiveTableColumn(
      label: 'وضعیت',
      sortValue: (leave) => leave.normalizedStatus,
      cellBuilder: (leave) => _statusPill(leave, scheme),
    ),
    ResponsiveTableColumn(
      label: 'توضیحات',
      sortValue: (leave) => leave.notes ?? '',
      cellBuilder: (leave) => Text(
        leave.notes?.trim().isNotEmpty == true ? leave.notes! : '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    ResponsiveTableColumn(
      label: 'عملیات',
      cellBuilder: (leave) => _actions(leave, scheme),
    ),
  ];

  String _employeeLabel(Employee? employee, {String fallback = '—'}) {
    if (employee == null) return fallback;
    final code = PersianNumberFormatter.toPersian(
      employee.personnelCode.toString(),
    );
    return '${employee.fullName} ($code)';
  }

  Widget _actions(EmployeeLeave leave, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_calendar_rounded,
            size: 20,
            color: scheme.primary,
          ),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(leave: leave),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(leave),
        ),
      ],
    );
  }

  Widget _leaveCard(EmployeeLeave leave, ColorScheme scheme) {
    final employee = _employeesMap[leave.employeeId];
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: leave.isSick
            ? scheme.primaryContainer
            : AppTheme.warningColor.withValues(alpha: 0.16),
        foregroundColor: leave.isSick
            ? scheme.onPrimaryContainer
            : AppTheme.warningColor,
        child: Icon(
          leave.isSick
              ? Icons.medical_services_rounded
              : Icons.beach_access_rounded,
        ),
      ),
      title: _employeeLabel(employee, fallback: 'کارمند نامشخص'),
      subtitle:
          '${PersianNumberFormatter.toPersian(leave.fromDate)} تا ${PersianNumberFormatter.toPersian(leave.toDate)}',
      trailing: _statusPill(leave, scheme),
      metrics: [
        MobileMetric(label: 'نوع', value: _typePill(leave, scheme)),
        MobileMetric(
          label: 'مدت',
          value: Text('${_formatDays(leave.days)} روز'),
          color: leave.isSick ? scheme.primary : AppTheme.warningColor,
        ),
        if (leave.notes?.trim().isNotEmpty == true)
          MobileMetric(label: 'توضیحات', value: Text(leave.notes!)),
      ],
      actions: [
        IconButton(
          icon: Icon(Icons.edit_calendar_rounded, color: scheme.primary),
          tooltip: 'ویرایش',
          onPressed: () => _openForm(leave: leave),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(leave),
        ),
      ],
    );
  }

  Widget _typePill(EmployeeLeave leave, ColorScheme scheme) {
    final color = leave.isSick ? scheme.primary : AppTheme.warningColor;
    return _pill(
      leave.isSick ? 'استعلاجی' : 'استحقاقی',
      color,
      icon: leave.isSick
          ? Icons.medical_services_rounded
          : Icons.beach_access_rounded,
    );
  }

  Widget _statusPill(EmployeeLeave leave, ColorScheme scheme) {
    final approved = leave.isApproved;
    return _pill(
      approved ? 'لحاظ می‌شود' : 'در انتظار',
      approved ? AppTheme.successColor : scheme.outline,
      icon: approved ? Icons.check_circle_rounded : Icons.pending_rounded,
    );
  }

  Widget _pill(String label, Color color, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDays(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return PersianNumberFormatter.toPersian(text);
  }
}

class _EmptyLeaves extends StatelessWidget {
  const _EmptyLeaves();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.beach_access_outlined,
            size: 96,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'هنوز مرخصی ثبت نشده است',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          const Text('برای ثبت مرخصی جدید روی دکمه «مرخصی جدید» کلیک کنید'),
        ],
      ),
    );
  }
}
