import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../services/employee_service.dart';
import '../../services/salary_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/mouse_wheel_picker.dart';
import '../salary/salary_calculation_screen.dart';
import 'employee_batch_entry_view.dart';

class BatchOperationsScreen extends StatefulWidget {
  const BatchOperationsScreen({super.key});

  @override
  State<BatchOperationsScreen> createState() => _BatchOperationsScreenState();
}

class _BatchOperationsScreenState extends State<BatchOperationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDesktop => const {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }.contains(defaultTargetPlatform);

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.desktop_windows_rounded, size: 64),
              SizedBox(height: 16),
              Text(
                'بخش عملیات دسته‌ای هنوز برای گوشی آماده نشده است.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'لطفا از نسخه کامپیوتر استفاده کنید.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('عملیات دسته‌ای'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              icon: Icon(Icons.group_add_rounded),
              text: 'ورود دسته‌ای کارکنان',
            ),
            Tab(icon: Icon(Icons.calculate_rounded), text: 'محاسبه دستی حقوق'),
            Tab(icon: Icon(Icons.print_rounded), text: 'محاسبه و چاپ دسته‌ای'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EmployeeBatchEntryView(
            onSaved: () => setState(() => _dataRevision++),
          ),
          SalaryCalculationScreen(
            key: ValueKey('manual-salary-$_dataRevision'),
            embedded: true,
          ),
          _BatchPayslipView(key: ValueKey('batch-payslip-$_dataRevision')),
        ],
      ),
    );
  }
}

class _BatchPayslipView extends StatefulWidget {
  const _BatchPayslipView({super.key});

  @override
  State<_BatchPayslipView> createState() => _BatchPayslipViewState();
}

class _BatchPayslipViewState extends State<_BatchPayslipView> {
  final _employeeService = EmployeeService();
  final _salaryService = SalaryService();
  final _settingsService = SettingsService();

  List<Employee> _employees = [];
  List<SalaryRecord> _records = [];
  AppSettings? _settings;
  Set<int> _selectedEmployeeIds = {};
  bool _loading = true;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final today = PersianDateHelper.today();
    _year = today.year;
    _month = today.month;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final employees = await _employeeService.getAll();
    final records = await _salaryService.getByYearMonth(_year, _month);
    final settings = await _settingsService.getCurrentSettings(year: _year);
    if (!mounted) return;
    setState(() {
      _employees = employees;
      _records = records;
      _settings = settings;
      if (_selectedEmployeeIds.isEmpty) {
        _selectedEmployeeIds = {
          for (final employee in employees)
            if (employee.id != null && employee.isActive) employee.id!,
        };
      } else {
        _selectedEmployeeIds = _selectedEmployeeIds
            .where((id) => employees.any((employee) => employee.id == id))
            .toSet();
      }
      _loading = false;
    });
  }

  List<SalaryRecord> get _selectedRecords {
    final selected = _records
        .where((record) => _selectedEmployeeIds.contains(record.employeeId))
        .toList();
    selected.sort((a, b) {
      final ac = _employeeFor(a)?.personnelCode ?? 0;
      final bc = _employeeFor(b)?.personnelCode ?? 0;
      return ac.compareTo(bc);
    });
    return selected;
  }

  Employee? _employeeFor(SalaryRecord record) =>
      _employees.cast<Employee?>().firstWhere(
        (employee) => employee?.id == record.employeeId,
        orElse: () => null,
      );

  Future<void> _changePeriod({int? year, int? month}) async {
    setState(() {
      if (year != null) _year = year;
      if (month != null) _month = month;
    });
    await _load();
  }

  void _selectAll() {
    setState(() {
      _selectedEmployeeIds = {
        for (final employee in _employees)
          if (employee.id != null) employee.id!,
      };
    });
  }

  void _selectNone() {
    setState(() => _selectedEmployeeIds = {});
  }

  bool _validateSelection() {
    if (_selectedEmployeeIds.isEmpty) {
      _message('حداقل یک کارمند را انتخاب کنید', isError: true);
      return false;
    }
    if (_selectedRecords.isEmpty) {
      _message(
        'برای کارکنان انتخاب‌شده در این ماه فیش ثبت نشده است',
        isError: true,
      );
      return false;
    }
    return true;
  }

  void _message(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _printPayslips() async {
    if (!_validateSelection() || _settings == null) return;
    try {
      final bytes = await _buildPayslipsPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'فیش‌های حقوق ${PersianDateHelper.monthName(_month)} $_year',
      );
    } catch (e) {
      _message('خطا در چاپ دسته‌ای: $e', isError: true);
    }
  }

  Future<void> _exportFinancialCsv() =>
      _exportCsv('financial', _financialRows());

  Future<void> _exportTaxCsv() => _exportCsv('tax', _taxRows());

  Future<void> _exportInsuranceCsv() =>
      _exportCsv('insurance', _insuranceRows());

  Future<void> _exportCsv(String type, List<List<Object?>> rows) async {
    if (!_validateSelection()) return;
    final csv = const Utf8Encoder().convert(
      '\ufeff${rows.map(_csvLine).join('\r\n')}\r\n',
    );
    final fileName =
        'hvm-$type-$_year-${_month.toString().padLeft(2, '0')}.csv';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره خروجی دسته‌ای',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Uint8List.fromList(csv),
    );
    if (path != null) _message('خروجی ذخیره شد: $path');
  }

  String _csvLine(List<Object?> values) {
    return values
        .map((value) {
          final text = (value ?? '').toString();
          return '"${text.replaceAll('"', '""')}"';
        })
        .join(',');
  }

  List<List<Object?>> _financialRows() => [
    [
      'کد پرسنلی',
      'نام',
      'سال',
      'ماه',
      'مرخصی',
      'استعلاجی',
      'جمع حقوق و مزایا',
      'جمع کسورات',
      'مالیات',
      'بیمه کارمند',
      'قسط وام',
      'مساعده',
      'خالص پرداختی',
    ],
    for (final record in _selectedRecords)
      [
        _employeeFor(record)?.personnelCode ?? '',
        _employeeName(record),
        record.year,
        record.month,
        _formatDays(record.leaveDays, persian: false),
        _formatDays(record.sickLeaveDays, persian: false),
        record.totalEarnings.round(),
        record.totalDeductions.round(),
        record.tax.round(),
        record.insurance.round(),
        record.loanInstallment.round(),
        record.advance.round(),
        record.finalPayment.round(),
      ],
  ];

  List<List<Object?>> _taxRows() => [
    [
      'کد پرسنلی',
      'کد ملی',
      'نام',
      'سال',
      'ماه',
      'حقوق مشمول مالیات',
      'مالیات',
      'جمع حقوق و مزایا',
    ],
    for (final record in _selectedRecords)
      [
        _employeeFor(record)?.personnelCode ?? '',
        _employeeNationalId(record),
        _employeeName(record),
        record.year,
        record.month,
        record.taxBase.round(),
        record.tax.round(),
        record.totalEarnings.round(),
      ],
  ];

  List<List<Object?>> _insuranceRows() {
    final settings = _settings;
    return [
      [
        'کد پرسنلی',
        'کد ملی',
        'نام',
        'سال',
        'ماه',
        'روز قابل پرداخت کارفرما',
        'استعلاجی',
        'مبنای بیمه',
        'بیمه کارمند',
        'بیمه کارفرما',
        'بیمه بیکاری',
      ],
      for (final record in _selectedRecords)
        [
          _employeeFor(record)?.personnelCode ?? '',
          _employeeNationalId(record),
          _employeeName(record),
          record.year,
          record.month,
          _formatDays(record.payableDays, persian: false),
          _formatDays(record.sickLeaveDays, persian: false),
          record.insuranceBase.round(),
          record.insurance.round(),
          settings == null
              ? ''
              : (record.insuranceBase * settings.employerInsuranceRate).round(),
          settings == null
              ? ''
              : (record.insuranceBase * settings.unemploymentInsuranceRate)
                    .round(),
        ],
    ];
  }

  Future<Uint8List> _buildPayslipsPdf() async {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'),
    );
    final doc = pw.Document();
    for (final record in _selectedRecords) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5.landscape,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (_) => _pdfPayslip(record),
        ),
      );
    }
    return doc.save();
  }

  pw.Widget _pdfPayslip(SalaryRecord record) {
    final rows = [
      ('حقوق ثابت', record.baseSalary),
      ('حق مسکن', record.housing),
      ('حق خواروبار', record.food),
      ('حق تاهل', record.marriage),
      ('حق فرزند', record.childAllowance),
      ('اضافه کار', record.overtimeAmount),
      ('سایر مزایا', record.otherBenefits),
      ('بیمه', -record.insurance),
      ('مالیات', -record.tax),
      ('قسط وام', -record.loanInstallment),
      ('مساعده', -record.advance),
      ('سایر کسورات', -record.otherDeductions),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                _settings?.companyName ?? 'HvM',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              '${PersianDateHelper.monthName(record.month)} ${record.year}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text('نام: ${_employeeName(record)}')),
              pw.Expanded(
                child: pw.Text(
                  'کد: ${_employeeFor(record)?.personnelCode ?? ''}',
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'کارکرد: ${_formatDays(record.workDays, persian: false)}',
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'استعلاجی: ${_formatDays(record.sickLeaveDays, persian: false)}',
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: .5),
          children: [
            for (final row in rows)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      row.$1,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      row.$2.round().toString(),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.green700,
          child: pw.Row(
            children: [
              pw.Text(
                'خالص پرداختی',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                record.finalPayment.round().toString(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _employeeName(SalaryRecord record) {
    final snapshot = record.employeeFullNameSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return _employeeFor(record)?.fullName ?? '';
  }

  String _employeeNationalId(SalaryRecord record) {
    final snapshot = record.employeeNationalIdSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return _employeeFor(record)?.nationalId ?? '';
  }

  String _formatDays(double value, {bool persian = true}) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return persian ? PersianNumberFormatter.toPersian(text) : text;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هنوز کارمندی ثبت نشده است'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('بازخوانی'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _periodCard(scheme),
        _actionsCard(scheme),
        Expanded(child: _employeesList(scheme)),
      ],
    );
  }

  Widget _periodCard(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final controls = [
                MouseWheelPicker<int>(
                  value: _year,
                  options: PersianDateHelper.nearbyYearOptions(
                    selectedYear: _year,
                  ),
                  onChanged: (year) => _changePeriod(year: year),
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('batch-year-$_year'),
                    initialValue: _year,
                    decoration: const InputDecoration(
                      labelText: 'سال',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                    items:
                        PersianDateHelper.nearbyYearOptions(selectedYear: _year)
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(
                                  PersianNumberFormatter.toPersian(
                                    year.toString(),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) _changePeriod(year: value);
                    },
                  ),
                ),
                MouseWheelPicker<int>(
                  value: _month,
                  options: List.generate(12, (index) => index + 1),
                  onChanged: (month) => _changePeriod(month: month),
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('batch-month-$_month'),
                    initialValue: _month,
                    decoration: const InputDecoration(
                      labelText: 'ماه',
                      prefixIcon: Icon(Icons.calendar_view_month_rounded),
                    ),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(PersianDateHelper.monthName(month)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) _changePeriod(month: value);
                    },
                  ),
                ),
              ];
              if (constraints.maxWidth < 620) {
                return Column(
                  children: [
                    controls[0],
                    const SizedBox(height: 10),
                    controls[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: controls[0]),
                  const SizedBox(width: 12),
                  Expanded(child: controls[1]),
                  const SizedBox(width: 12),
                  _summaryPill(scheme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryPill(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        'فیش موجود: ${PersianNumberFormatter.toPersian(_records.length.toString())}',
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _actionsCard(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('بازخوانی'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.select_all_rounded),
                  label: const Text('انتخاب همه'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectNone,
                  icon: const Icon(Icons.deselect_rounded),
                  label: const Text('هیچکس'),
                ),
                FilledButton.icon(
                  onPressed: _printPayslips,
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('چاپ فیش‌ها'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _exportFinancialCsv,
                  icon: const Icon(Icons.table_view_rounded),
                  label: const Text('خروجی مالی'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _exportTaxCsv,
                  icon: const Icon(Icons.receipt_rounded),
                  label: const Text('خروجی مالیات'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _exportInsuranceCsv,
                  icon: const Icon(Icons.health_and_safety_rounded),
                  label: const Text('خروجی بیمه'),
                ),
              ];
              if (constraints.maxWidth < 760) {
                return Wrap(spacing: 8, runSpacing: 8, children: buttons);
              }
              return Row(
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: buttons[i]),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _employeesList(ColorScheme scheme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 88),
      itemCount: _employees.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final id = employee.id;
        final selected = id != null && _selectedEmployeeIds.contains(id);
        final record = id == null
            ? null
            : _records.cast<SalaryRecord?>().firstWhere(
                (item) => item?.employeeId == id,
                orElse: () => null,
              );
        return Card(
          child: CheckboxListTile(
            value: selected,
            onChanged: id == null
                ? null
                : (value) {
                    setState(() {
                      if (value == true) {
                        _selectedEmployeeIds.add(id);
                      } else {
                        _selectedEmployeeIds.remove(id);
                      }
                    });
                  },
            secondary: CircleAvatar(
              backgroundColor: record == null
                  ? scheme.surfaceContainerHighest
                  : AppTheme.successColor.withValues(alpha: 0.16),
              child: Icon(
                record == null
                    ? Icons.receipt_long_outlined
                    : Icons.receipt_long_rounded,
                color: record == null
                    ? scheme.onSurfaceVariant
                    : AppTheme.successColor,
              ),
            ),
            title: Text(employee.fullName),
            subtitle: Text(
              'کد ${PersianNumberFormatter.toPersian(employee.personnelCode.toString())}'
              '${record == null ? ' | فیش این ماه ثبت نشده' : ' | استعلاجی ${_formatDays(record.sickLeaveDays)} روز'}',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      },
    );
  }
}
