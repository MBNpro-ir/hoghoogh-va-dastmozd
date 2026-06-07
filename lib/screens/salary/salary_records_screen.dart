import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../services/employee_service.dart';
import '../../services/salary_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/responsive_data_view.dart';
import 'salary_calculation_screen.dart';
import 'payslip_screen.dart';

class SalaryRecordsScreen extends StatefulWidget {
  const SalaryRecordsScreen({super.key});

  @override
  State<SalaryRecordsScreen> createState() => _SalaryRecordsScreenState();
}

class _SalaryRecordsScreenState extends State<SalaryRecordsScreen> {
  final _salaryService = SalaryService();
  final _employeeService = EmployeeService();
  final _settingsService = SettingsService();

  List<SalaryRecord> _records = [];
  Map<int, Employee> _employeesMap = {};
  AppSettings? _settings;
  bool _loading = true;

  int? _filterYear;
  int? _filterMonth;
  List<(int, int)> _availableMonths = [];
  int _sortColumnIndex = 3;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _settings = await _settingsService.getCurrentSettings();
    _availableMonths = await _salaryService.getRecordedMonths();
    final employees = await _employeeService.getAll();
    _employeesMap = {for (var e in employees) e.id!: e};

    if (_availableMonths.isNotEmpty && _filterYear == null) {
      _filterYear = _availableMonths.first.$1;
      _filterMonth = _availableMonths.first.$2;
    }

    if (_filterYear != null && _filterMonth != null) {
      _records = await _salaryService.getByYearMonth(
        _filterYear!,
        _filterMonth!,
      );
    } else {
      _records = await _salaryService.getAll();
    }

    if (mounted) setState(() => _loading = false);
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
      await _salaryService.delete(record.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                if (_records.isNotEmpty) _buildSummary(),
                Expanded(
                  child: _records.isEmpty
                      ? const _EmptyRecords()
                      : _buildTable(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilter() {
    final scheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          color: scheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'فیلتر دوره',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<(int, int)?>(
                      initialValue:
                          (_filterYear != null && _filterMonth != null)
                          ? (_filterYear!, _filterMonth!)
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'دوره',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<(int, int)?>(
                          value: null,
                          child: Text('همه دوره‌ها'),
                        ),
                        ..._availableMonths.map(
                          (ym) => DropdownMenuItem(
                            value: ym,
                            child: Text(
                              '${PersianDateHelper.monthName(ym.$2)} ${PersianNumberFormatter.toPersian(ym.$1.toString())}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) async {
                        setState(() {
                          _filterYear = v?.$1;
                          _filterMonth = v?.$2;
                        });
                        if (v != null) {
                          final list = await _salaryService.getByYearMonth(
                            v.$1,
                            v.$2,
                          );
                          setState(() => _records = list);
                        } else {
                          final list = await _salaryService.getAll();
                          setState(() => _records = list);
                        }
                      },
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.filter_alt_rounded, color: scheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'فیلتر دوره: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<(int, int)?>(
                        initialValue:
                            (_filterYear != null && _filterMonth != null)
                            ? (_filterYear!, _filterMonth!)
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'دوره',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<(int, int)?>(
                            value: null,
                            child: Text('همه دوره‌ها'),
                          ),
                          ..._availableMonths.map(
                            (ym) => DropdownMenuItem(
                              value: ym,
                              child: Text(
                                '${PersianDateHelper.monthName(ym.$2)} ${PersianNumberFormatter.toPersian(ym.$1.toString())}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) async {
                          setState(() {
                            _filterYear = v?.$1;
                            _filterMonth = v?.$2;
                          });
                          if (v != null) {
                            final list = await _salaryService.getByYearMonth(
                              v.$1,
                              v.$2,
                            );
                            setState(() => _records = list);
                          } else {
                            final list = await _salaryService.getAll();
                            setState(() => _records = list);
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final scheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    double totalEarnings = 0, totalDeductions = 0, totalNet = 0;
    double totalInsurance = 0, totalTax = 0;
    for (final r in _records) {
      totalEarnings += r.totalEarnings;
      totalDeductions += r.totalDeductions;
      totalNet += r.finalPayment;
      totalInsurance += r.insurance;
      totalTax += r.tax;
    }

    final cards = [
      _summaryCard(
        'تعداد فیش',
        PersianNumberFormatter.toPersian(_records.length.toString()),
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
        child: Wrap(spacing: 8, runSpacing: 8, children: cards),
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

  Widget _buildTable() {
    final scheme = Theme.of(context).colorScheme;
    final columns = _columns(scheme);
    final items = sortResponsiveItems(
      _records,
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
      label: 'عملیات',
      cellBuilder: (r) => _recordActions(r, scheme),
    ),
  ];

  Widget _recordActions(SalaryRecord record, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_rounded,
            size: 20,
            color: AppTheme.warningColor,
          ),
          tooltip: 'ویرایش فیش',
          onPressed: () => _editPayslip(record),
        ),
        IconButton(
          icon: Icon(Icons.print_rounded, size: 20, color: scheme.primary),
          tooltip: 'مشاهده / چاپ',
          onPressed: () => _openPayslip(record),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
          tooltip: 'حذف',
          onPressed: () => _delete(record),
        ),
      ],
    );
  }

  Widget _recordCard(SalaryRecord record, int index, ColorScheme scheme) {
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Text(PersianNumberFormatter.toPersian((index + 1).toString())),
      ),
      title: _employeeNameForRecord(record),
      subtitle:
          '${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())} • کارکرد ${_formatDays(record.workDays)} روز',
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
      ],
      actions: [
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
