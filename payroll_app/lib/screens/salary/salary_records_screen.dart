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
      _records = await _salaryService.getByYearMonth(_filterYear!, _filterMonth!);
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
        builder: (_) => PayslipScreen(
          employee: emp,
          settings: _settings!,
          record: record,
        ),
      ),
    );
  }

  Future<void> _delete(SalaryRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف فیش حقوق'),
        content: const Text('آیا از حذف این فیش حقوق مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'بازخوانی'),
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.filter_alt, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('فیلتر دوره: ', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<(int, int)?>(
                  initialValue: (_filterYear != null && _filterMonth != null)
                      ? (_filterYear!, _filterMonth!)
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'دوره',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<(int, int)?>(
                      value: null,
                      child: Text('همه دوره‌ها'),
                    ),
                    ..._availableMonths.map((ym) => DropdownMenuItem(
                          value: ym,
                          child: Text(
                            '${PersianDateHelper.monthName(ym.$2)} ${PersianNumberFormatter.toPersian(ym.$1.toString())}',
                          ),
                        )),
                  ],
                  onChanged: (v) async {
                    setState(() {
                      _filterYear = v?.$1;
                      _filterMonth = v?.$2;
                    });
                    if (v != null) {
                      final list = await _salaryService.getByYearMonth(v.$1, v.$2);
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
    double totalEarnings = 0;
    double totalDeductions = 0;
    double totalNet = 0;
    double totalInsurance = 0;
    double totalTax = 0;
    for (final r in _records) {
      totalEarnings += r.totalEarnings;
      totalDeductions += r.totalDeductions;
      totalNet += r.finalPayment;
      totalInsurance += r.insurance;
      totalTax += r.tax;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryCard('تعداد فیش', PersianNumberFormatter.toPersian(_records.length.toString()), Colors.indigo),
            _summaryCard('جمع حقوق و مزایا', PersianNumberFormatter.formatNumber(totalEarnings), Colors.green),
            _summaryCard('جمع کسورات', PersianNumberFormatter.formatNumber(totalDeductions), Colors.red),
            _summaryCard('جمع مالیات', PersianNumberFormatter.formatNumber(totalTax), Colors.orange),
            _summaryCard('جمع بیمه (۷٪)', PersianNumberFormatter.formatNumber(totalInsurance), Colors.purple),
            _summaryCard('جمع پرداختی', PersianNumberFormatter.formatNumber(totalNet), AppTheme.successColor),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.tableHeaderBlue),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(fontSize: 13),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('ردیف')),
                DataColumn(label: Text('کد')),
                DataColumn(label: Text('نام کارمند')),
                DataColumn(label: Text('دوره')),
                DataColumn(label: Text('کارکرد'), numeric: true),
                DataColumn(label: Text('جمع حقوق و مزایا'), numeric: true),
                DataColumn(label: Text('مالیات'), numeric: true),
                DataColumn(label: Text('بیمه ۷٪'), numeric: true),
                DataColumn(label: Text('قسط وام'), numeric: true),
                DataColumn(label: Text('جمع کسورات'), numeric: true),
                DataColumn(label: Text('خالص دریافتی'), numeric: true),
                DataColumn(label: Text('عملیات')),
              ],
              rows: _records.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final emp = _employeesMap[r.employeeId];
                return DataRow(
                  cells: [
                    DataCell(Text(PersianNumberFormatter.toPersian((i + 1).toString()))),
                    DataCell(Text(emp != null
                        ? PersianNumberFormatter.toPersian(emp.personnelCode.toString())
                        : '—')),
                    DataCell(Text(emp?.fullName ?? '—')),
                    DataCell(Text(
                        '${PersianDateHelper.monthName(r.month)} ${PersianNumberFormatter.toPersian(r.year.toString())}')),
                    DataCell(Text(PersianNumberFormatter.toPersian(r.workDays.toString()))),
                    DataCell(CurrencyText(r.totalEarnings)),
                    DataCell(CurrencyText(r.tax)),
                    DataCell(CurrencyText(r.insurance)),
                    DataCell(CurrencyText(r.loanInstallment)),
                    DataCell(CurrencyText(r.totalDeductions)),
                    DataCell(CurrencyText(r.finalPayment,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppTheme.successColor))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print, size: 20, color: AppTheme.primaryColor),
                          tooltip: 'مشاهده / چاپ',
                          onPressed: () => _openPayslip(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                          tooltip: 'حذف',
                          onPressed: () => _delete(r),
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

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 96, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'هنوز فیش حقوقی ثبت نشده است',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('برای محاسبه فیش حقوق به منوی «محاسبه حقوق ماهانه» بروید'),
        ],
      ),
    );
  }
}
