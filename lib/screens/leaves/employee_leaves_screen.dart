import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../services/employee_service.dart';
import '../../services/salary_calculator.dart';
import '../../services/salary_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/persian_number_field.dart';
import '../../widgets/responsive_data_view.dart';

class EmployeeLeavesScreen extends StatefulWidget {
  const EmployeeLeavesScreen({super.key});

  @override
  State<EmployeeLeavesScreen> createState() => _EmployeeLeavesScreenState();
}

class _EmployeeLeavesScreenState extends State<EmployeeLeavesScreen> {
  final _salaryService = SalaryService();
  final _employeeService = EmployeeService();
  final _settingsService = SettingsService();

  List<SalaryRecord> _records = [];
  Map<int, Employee> _employees = {};
  AppSettings? _settings;
  bool _loading = true;

  int _sortColumnIndex = 3;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final employees = await _employeeService.getAll();
    _employees = {for (final e in employees) e.id!: e};
    _settings = await _settingsService.getCurrentSettings();
    _records = await _salaryService.getAll();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مرخصی کارکنان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بازخوانی',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    _summary(),
                    Expanded(
                      child: _records.isEmpty ? const _EmptyLeaves() : _table(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summary() {
    final scheme = Theme.of(context).colorScheme;
    final totalLeave = _records.fold<double>(0, (s, r) => s + r.leaveDays);
    final totalExcess = _records.fold<double>(
      0,
      (s, r) => s + r.excessLeaveDays,
    );
    final totalDeduction = _records.fold<double>(
      0,
      (s, r) => s + r.leaveDeduction,
    );
    final monthly = _settings?.monthlyLeaveAllowance ?? 2.5;
    final annual = _settings?.annualLeaveAllowance ?? 30;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryCard(
            'سقف ماهانه',
            '${_formatDays(monthly)} روز',
            scheme.primary,
          ),
          _summaryCard(
            'سقف سالانه',
            '${_formatDays(annual)} روز',
            scheme.tertiary,
          ),
          _summaryCard(
            'کل مرخصی ثبت‌شده',
            '${_formatDays(totalLeave)} روز',
            scheme.secondary,
          ),
          _summaryCard(
            'مرخصی مازاد',
            '${_formatDays(totalExcess)} روز',
            scheme.error,
          ),
          _summaryCard(
            'کسر مرخصی',
            PersianNumberFormatter.formatRial(totalDeduction),
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      width: 190,
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

  Widget _table() {
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
      accentColor: AppTheme.warningColor,
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
          _mobileCard(record, index, scheme),
    );
  }

  String _employeeNameForRecord(SalaryRecord record) {
    final snapshot = record.employeeFullNameSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return _employees[record.employeeId]?.fullName ?? '—';
  }

  List<ResponsiveTableColumn<SalaryRecord>> _columns(ColorScheme scheme) => [
    ResponsiveTableColumn(
      label: 'کارمند',
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
      label: 'مرخصی',
      numeric: true,
      sortValue: (r) => r.leaveDays,
      cellBuilder: (r) => Text('${_formatDays(r.leaveDays)} روز'),
    ),
    ResponsiveTableColumn(
      label: 'مجاز',
      numeric: true,
      sortValue: (r) => r.leaveAllowanceDays,
      cellBuilder: (r) => Text('${_formatDays(r.leaveAllowanceDays)} روز'),
    ),
    ResponsiveTableColumn(
      label: 'مازاد',
      numeric: true,
      sortValue: (r) => r.excessLeaveDays,
      cellBuilder: (r) => Text('${_formatDays(r.excessLeaveDays)} روز'),
    ),
    ResponsiveTableColumn(
      label: 'کسر',
      numeric: true,
      sortValue: (r) => r.leaveDeduction,
      cellBuilder: (r) => CurrencyText(r.leaveDeduction),
    ),
    ResponsiveTableColumn(
      label: 'عملیات',
      cellBuilder: (r) => IconButton(
        icon: Icon(Icons.edit_calendar_rounded, color: scheme.primary),
        tooltip: 'ویرایش مرخصی',
        onPressed: () => _editLeave(r),
      ),
    ),
  ];

  Widget _mobileCard(SalaryRecord record, int index, ColorScheme scheme) {
    return MobileDataCard(
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Text(PersianNumberFormatter.toPersian((index + 1).toString())),
      ),
      title: _employeeNameForRecord(record),
      subtitle:
          '${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())}',
      metrics: [
        MobileMetric(
          label: 'مرخصی',
          value: Text('${_formatDays(record.leaveDays)} روز'),
        ),
        MobileMetric(
          label: 'مازاد',
          value: Text('${_formatDays(record.excessLeaveDays)} روز'),
          color: scheme.error,
        ),
        MobileMetric(
          label: 'کسر',
          value: CurrencyText(record.leaveDeduction),
          color: AppTheme.warningColor,
        ),
      ],
      actions: [
        IconButton(
          icon: Icon(Icons.edit_calendar_rounded, color: scheme.primary),
          tooltip: 'ویرایش مرخصی',
          onPressed: () => _editLeave(record),
        ),
      ],
    );
  }

  Future<void> _editLeave(SalaryRecord record) async {
    if (_settings == null) return;
    final employee = _employees[record.employeeId];
    if (employee == null) return;
    var leaveDays = record.leaveDays;
    var includeLeave = record.includeLeaveInPayslip;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش مرخصی'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersianNumberField(
              label: 'مرخصی',
              suffix: 'روز',
              prefixIcon: Icons.beach_access_rounded,
              initialValue: leaveDays,
              onChanged: (v) => leaveDays = v?.toDouble() ?? 0,
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setLocalState) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('محاسبه در فیش حقوقی'),
                value: includeLeave,
                onChanged: (v) => setLocalState(() => includeLeave = v),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final workDays = (record.totalDays - leaveDays)
        .clamp(0.0, record.totalDays.toDouble())
        .toDouble();
    final recalculated = SalaryCalculator.calculate(
      employee: employee,
      settings: _settings!,
      input: SalaryCalculationInput(
        totalDays: record.totalDays,
        leaveDays: leaveDays,
        overtimeHours: record.overtimeHours,
        shiftWork: record.shiftWork,
        hourlyBenefitsAmount: record.hourlyBenefitsAmount,
        hourlyBenefitHours: record.hourlyBenefitHours,
        autoShiftWork: false,
        autoHourlyBenefits: record.hourlyBenefitHours > 0,
        includeLeaveInPayslip: includeLeave,
        insuranceExempt: record.insuranceBase == 0 && record.totalEarnings > 0,
        taxExempt: record.tax == 0 && record.totalEarnings > 400000000,
        otherBenefitsOverride: record.workDays > 0
            ? record.otherBenefits / record.workDays
            : record.otherBenefits,
        loanInstallment: record.loanInstallment,
        advance: record.advance,
        otherDeductions: record.otherDeductions,
      ),
    );
    final updated = recalculated
        .toRecord(
          employeeId: record.employeeId,
          employeeFullNameSnapshot:
              record.employeeFullNameSnapshot ?? employee.fullName,
          employeePersonnelCodeSnapshot:
              record.employeePersonnelCodeSnapshot ?? employee.personnelCode,
          employeeNationalIdSnapshot:
              record.employeeNationalIdSnapshot ?? employee.nationalId,
          year: record.year,
          month: record.month,
          totalDays: record.totalDays,
          leaveDays: leaveDays,
          workDays: workDays,
          overtimeHours: record.overtimeHours,
          hourlyBenefitHours: record.hourlyBenefitHours,
          includeLeaveInPayslip: includeLeave,
          notes: record.notes,
        )
        .copyWithId(record.id!);
    await _salaryService.update(updated);
    await _load();
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
            size: 88,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'هنوز فیشی ثبت نشده است',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          const Text(
            'پس از ثبت فیش حقوقی، مرخصی کارکنان در این بخش نمایش داده می‌شود.',
          ),
        ],
      ),
    );
  }
}
