import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../services/employee_service.dart';
import '../../services/salary_record_update_service.dart';
import '../../services/salary_service.dart';
import '../../services/settings_service.dart';
import '../../services/table_sort_preferences.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/period_filter_helper.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/period_filter_bar.dart';
import '../../widgets/responsive_data_view.dart';
import 'salary_calculation_screen.dart';
import 'payslip_screen.dart';

class SalaryRecordsScreen extends StatefulWidget {
  const SalaryRecordsScreen({super.key});

  @override
  State<SalaryRecordsScreen> createState() => _SalaryRecordsScreenState();
}

class _SalaryRecordsScreenState extends State<SalaryRecordsScreen> {
  static const _sortPreferenceKey = 'salary_records';
  static const _defaultSortColumnIndex = 3;
  static const _defaultSortAscending = false;

  final _salaryService = SalaryService();
  final _recordUpdateService = SalaryRecordUpdateService();
  final _employeeService = EmployeeService();
  final _settingsService = SettingsService();
  final _searchController = TextEditingController();
  final _searchUndoController = UndoHistoryController();

  List<SalaryRecord> _records = [];
  Map<int, Employee> _employeesMap = {};
  AppSettings? _settings;
  bool _loading = true;
  final Set<int> _updatingRecordIds = {};

  int? _filterYear;
  int? _filterMonth;
  String _filter = '';
  List<(int, int)> _availableMonths = [];
  Map<int, SalaryRecordSourceSnapshot> _outdatedSnapshots = {};
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchUndoController.dispose();
    super.dispose();
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
    _settings = await _settingsService.getCurrentSettings();
    _availableMonths = {...await _salaryService.getRecordedMonths()}.toList();
    final employees = await _employeeService.getAll();
    _employeesMap = {for (var e in employees) e.id!: e};

    final resolvedPeriod = PeriodFilterHelper.resolveAvailablePeriod(
      selected: _selectedPeriod,
      available: _availableMonths,
      preferred: (
        PersianDateHelper.currentYear,
        PersianDateHelper.currentMonth,
      ),
    );
    _filterYear = resolvedPeriod?.$1;
    _filterMonth = resolvedPeriod?.$2;

    final records = _filterYear != null && _filterMonth != null
        ? await _salaryService.getByYearMonth(_filterYear!, _filterMonth!)
        : await _salaryService.getAll();
    final outdatedSnapshots = await _recordUpdateService.outdatedSnapshotsFor(
      records,
    );

    if (mounted) {
      setState(() {
        _records = records;
        _outdatedSnapshots = outdatedSnapshots;
        _loading = false;
      });
    }
  }

  (int, int)? get _selectedPeriod => _filterYear != null && _filterMonth != null
      ? (_filterYear!, _filterMonth!)
      : null;

  List<SalaryRecord> get _filteredRecords {
    final filter = _filter.trim();
    if (filter.isEmpty) return _records;

    final englishFilter = PersianNumberFormatter.toEnglish(filter);
    return _records.where((record) {
      final employeeName = _employeeNameForRecord(record);
      final employeeCode = _employeeCodeForRecord(record)?.toString() ?? '';
      final periodLabel =
          '${PersianDateHelper.monthName(record.month)} ${record.year}';
      final numericPeriod = '${record.year}/${record.month}';
      return employeeName.contains(filter) ||
          employeeCode.contains(englishFilter) ||
          PersianNumberFormatter.toEnglish(
            periodLabel,
          ).contains(englishFilter) ||
          numericPeriod.contains(englishFilter);
    }).toList();
  }

  Future<void> _onPeriodChanged((int, int)? value) async {
    setState(() {
      _filterYear = value?.$1;
      _filterMonth = value?.$2;
      _loading = true;
    });
    final records = value == null
        ? await _salaryService.getAll()
        : await _salaryService.getByYearMonth(value.$1, value.$2);
    final outdatedSnapshots = await _recordUpdateService.outdatedSnapshotsFor(
      records,
    );
    if (mounted) {
      setState(() {
        _records = records;
        _outdatedSnapshots = outdatedSnapshots;
        _loading = false;
      });
    }
  }

  Future<void> _openPayslip(SalaryRecord record) async {
    final emp = _employeesMap[record.employeeId];
    if (emp == null || _settings == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PayslipScreen(employee: emp, settings: _settings!, record: record),
      ),
    );
  }

  Future<void> _editPayslip(SalaryRecord record) async {
    final emp = _employeesMap[record.employeeId];
    if (emp == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SalaryCalculationScreen(initialEmployee: emp, editRecord: record),
      ),
    );
    if (!mounted) return;
    if (changed == true || changed == null) await _load();
  }

  Future<void> _updatePayslip(SalaryRecord record) async {
    final id = record.id;
    final employee = _employeesMap[record.employeeId];
    final snapshot = id == null ? null : _outdatedSnapshots[id];
    if (id == null || employee == null || snapshot == null) return;

    final labels = snapshot.changedLabelsComparedTo(record).join('، ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آپدیت فیش حقوق'),
        content: Text(
          'وضعیت $labels تغییر کرده است. فیش ذخیره‌شده با وضعیت جدید جایگزین شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.update_rounded),
            label: const Text('آپدیت فیش'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _updatingRecordIds.add(id));
    try {
      final latestSnapshot = await _recordUpdateService.currentSnapshotFor(
        record,
      );
      if (!latestSnapshot.hasChangesComparedTo(record)) {
        await _load();
        return;
      }
      final settings = await _settingsService.getCurrentSettings(
        year: record.year,
      );
      final updatedRecord = _recordUpdateService.rebuildRecord(
        record: record,
        employee: employee,
        settings: settings,
        snapshot: latestSnapshot,
      );
      await _salaryService.update(updatedRecord);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فیش حقوق با وضعیت جدید آپدیت شد'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMessage.from(
              error,
              fallback:
                  'آپدیت فیش انجام نشد. اطلاعات مرخصی، وام و مساعده را بررسی کنید.',
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingRecordIds.remove(id));
    }
  }

  Future<void> _delete(SalaryRecord record) async {
    final scheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف فیش حقوق'),
        content: const Text('آیا از حذف این فیش حقوق مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && record.id != null) {
      try {
        await _salaryService.delete(record.id!);
        await _load();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'حذف فیش انجام نشد. فهرست را تازه کنید.',
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
    final filteredRecords = _filteredRecords;
    return Scaffold(
      appBar: compactShell
          ? null
          : AppBar(
              title: const Text('فیش‌های حقوق ثبت‌شده'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                  tooltip: 'بازخوانی',
                ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilter(),
                if (filteredRecords.isNotEmpty && !compactShell)
                  _buildSummary(filteredRecords),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? const _EmptyRecords()
                      : _buildTable(
                          filteredRecords,
                          mobileHeader: compactShell
                              ? _buildSummary(filteredRecords)
                              : null,
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilter() {
    return PeriodFilterBar(
      selectedPeriod: _selectedPeriod,
      availablePeriods: _availableMonths,
      onPeriodChanged: _onPeriodChanged,
      searchController: _searchController,
      searchUndoController: _searchUndoController,
      onSearchChanged: (value) => setState(() => _filter = value),
      searchHint: 'جستجو بر اساس نام، کد پرسنلی یا دوره...',
    );
  }

  Widget _buildSummary(List<SalaryRecord> records) {
    final scheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    double totalEarnings = 0, totalDeductions = 0, totalNet = 0;
    double totalInsurance = 0, totalTax = 0;
    for (final r in records) {
      totalEarnings += r.totalEarnings;
      totalDeductions += r.totalDeductions;
      totalNet += r.finalPayment;
      totalInsurance += r.insurance;
      totalTax += r.tax;
    }

    final cards = [
      _summaryCard(
        'تعداد فیش',
        PersianNumberFormatter.toPersian(records.length.toString()),
        scheme.primary,
        isMobile,
      ),
      _summaryCard(
        'جمع حقوق و مزایا',
        PersianNumberFormatter.formatNumber(totalEarnings),
        scheme.tertiary,
        isMobile,
      ),
      _summaryCard(
        'جمع کسورات',
        PersianNumberFormatter.formatNumber(totalDeductions),
        scheme.error,
        isMobile,
      ),
      _summaryCard(
        'جمع مالیات',
        PersianNumberFormatter.formatNumber(totalTax),
        scheme.secondary,
        isMobile,
      ),
      _summaryCard(
        'جمع بیمه (۷٪)',
        PersianNumberFormatter.formatNumber(totalInsurance),
        scheme.tertiary,
        isMobile,
      ),
      _summaryCard(
        'جمع پرداختی',
        PersianNumberFormatter.formatNumber(totalNet),
        AppTheme.successColor,
        isMobile,
      ),
    ];

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: cards,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: cards),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, bool isMobile) {
    return Container(
      width: isMobile ? null : 200,
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: isMobile ? 10 : 11, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<SalaryRecord> records, {Widget? mobileHeader}) {
    final scheme = Theme.of(context).colorScheme;
    final columns = _columns(scheme);
    final items = sortResponsiveItems(
      records,
      columns,
      _sortColumnIndex,
      _sortAscending,
    );
    return ResponsiveDataView<SalaryRecord>(
      items: items,
      columns: columns,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      accentColor: scheme.secondary,
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
      mobileCardBuilder: (context, record, index) =>
          _recordCard(record, index, scheme),
    );
  }

  String _employeeNameForRecord(SalaryRecord record) {
    final snapshot = record.employeeFullNameSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return _employeesMap[record.employeeId]?.fullName ?? '—';
  }

  int? _employeeCodeForRecord(SalaryRecord record) =>
      record.employeePersonnelCodeSnapshot ??
      _employeesMap[record.employeeId]?.personnelCode;

  List<ResponsiveTableColumn<SalaryRecord>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'ردیف',
      sortValue: (r) => _records.indexOf(r),
      cellBuilder: (r) => Text(
        PersianNumberFormatter.toPersian((_records.indexOf(r) + 1).toString()),
      ),
    ),
    ResponsiveTableColumn(
      label: 'کد',
      sortValue: (r) => _employeeCodeForRecord(r) ?? 0,
      cellBuilder: (r) => Text(
        _employeeCodeForRecord(r) != null
            ? PersianNumberFormatter.toPersian(
                _employeeCodeForRecord(r)!.toString(),
              )
            : '—',
      ),
    ),
    ResponsiveTableColumn(
      label: 'نام کارمند',
      sortValue: _employeeNameForRecord,
      cellBuilder: (r) => Text(_employeeNameForRecord(r)),
    ),
    ResponsiveTableColumn(
      label: 'دوره',
      sortValue: (r) => r.year * 100 + r.month,
      cellBuilder: (r) => Text(
        '${PersianDateHelper.monthName(r.month)} ${PersianNumberFormatter.toPersian(r.year.toString())}',
      ),
    ),
    ResponsiveTableColumn(
      label: 'کارکرد',
      numeric: true,
      sortValue: (r) => r.workDays,
      cellBuilder: (r) => Text(_formatDays(r.workDays)),
    ),
    ResponsiveTableColumn(
      label: 'استعلاجی',
      numeric: true,
      sortValue: (r) => r.sickLeaveDays,
      cellBuilder: (r) => Text(_formatDays(r.sickLeaveDays)),
    ),
    ResponsiveTableColumn(
      label: 'جمع حقوق و مزایا',
      numeric: true,
      sortValue: (r) => r.totalEarnings,
      cellBuilder: (r) => CurrencyText(r.totalEarnings),
    ),
    ResponsiveTableColumn(
      label: 'مالیات',
      numeric: true,
      sortValue: (r) => r.tax,
      cellBuilder: (r) => CurrencyText(r.tax),
    ),
    ResponsiveTableColumn(
      label: 'بیمه ۷٪',
      numeric: true,
      sortValue: (r) => r.insurance,
      cellBuilder: (r) => CurrencyText(r.insurance),
    ),
    ResponsiveTableColumn(
      label: 'قسط وام',
      numeric: true,
      sortValue: (r) => r.loanInstallment,
      cellBuilder: (r) => CurrencyText(r.loanInstallment),
    ),
    ResponsiveTableColumn(
      label: 'جمع کسورات',
      numeric: true,
      sortValue: (r) => r.totalDeductions,
      cellBuilder: (r) => CurrencyText(r.totalDeductions),
    ),
    ResponsiveTableColumn(
      label: 'خالص دریافتی',
      numeric: true,
      sortValue: (r) => r.finalPayment,
      cellBuilder: (r) => CurrencyText(
        r.finalPayment,
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
      ),
    ),
    ResponsiveTableColumn(
      label: 'وضعیت فیش',
      width: 150,
      sortValue: (r) => _outdatedSnapshots.containsKey(r.id) ? 0 : 1,
      cellBuilder: (r) => _payslipStatus(r, scheme),
    ),
    ResponsiveTableColumn(
      label: 'عملیات',
      width: 150,
      cellBuilder: (r) => _recordActions(r, scheme),
    ),
  ];

  Widget _payslipStatus(SalaryRecord record, ColorScheme scheme) {
    final id = record.id;
    final snapshot = id == null ? null : _outdatedSnapshots[id];
    final updating = id != null && _updatingRecordIds.contains(id);
    if (snapshot == null) {
      return Tooltip(
        message: 'فیش با وضعیت فعلی هماهنگ است',
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 6),
              Text(
                'به‌روز',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Tooltip(
      message:
          'تغییر در ${snapshot.changedLabelsComparedTo(record).join('، ')}',
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: updating ? null : () => _updatePayslip(record),
        icon: updating
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            : const Icon(Icons.update_rounded, size: 18),
        label: const Text('آپدیت فیش'),
      ),
    );
  }

  Widget _recordActions(SalaryRecord record, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(
            Icons.edit_rounded,
            size: 20,
            color: AppTheme.warningColor,
          ),
          tooltip: 'ویرایش فیش',
          onPressed: () => _editPayslip(record),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(Icons.print_rounded, size: 20, color: scheme.primary),
          tooltip: 'مشاهده / چاپ',
          onPressed: () => _openPayslip(record),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(record),
        ),
      ],
    );
  }

  Widget _recordCard(SalaryRecord record, int index, ColorScheme scheme) {
    final snapshot = record.id == null ? null : _outdatedSnapshots[record.id];
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Text(PersianNumberFormatter.toPersian((index + 1).toString())),
      ),
      title: _employeeNameForRecord(record),
      subtitle:
          '${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())} • کارکرد ${_formatDays(record.workDays)} روز • استعلاجی ${_formatDays(record.sickLeaveDays)} روز',
      metrics: [
        MobileMetric(
          label: 'حقوق و مزایا',
          value: CurrencyText(record.totalEarnings),
        ),
        MobileMetric(
          label: 'کسورات',
          value: CurrencyText(record.totalDeductions),
          color: scheme.error,
        ),
        MobileMetric(
          label: 'مالیات',
          value: CurrencyText(record.tax),
          color: scheme.secondary,
        ),
        MobileMetric(
          label: 'خالص',
          value: CurrencyText(record.finalPayment),
          color: AppTheme.successColor,
        ),
        if (snapshot != null)
          MobileMetric(
            label: 'وضعیت فیش',
            value: const Text('نیاز به آپدیت'),
            color: AppTheme.warningColor,
          ),
      ],
      actions: [
        if (snapshot != null) _payslipStatus(record, scheme),
        IconButton(
          icon: Icon(Icons.edit_rounded, color: AppTheme.warningColor),
          tooltip: 'ویرایش فیش',
          onPressed: () => _editPayslip(record),
        ),
        IconButton(
          icon: Icon(Icons.print_rounded, color: scheme.primary),
          tooltip: 'مشاهده / چاپ',
          onPressed: () => _openPayslip(record),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(record),
        ),
      ],
    );
  }

  String _formatDays(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return PersianNumberFormatter.toPersian(text);
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 96,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'هنوز فیش حقوقی ثبت نشده است',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          const Text('برای محاسبه فیش حقوق به منوی «محاسبه حقوق ماهانه» بروید'),
        ],
      ),
    );
  }
}
