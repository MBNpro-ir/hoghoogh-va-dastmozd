import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';

enum _PayslipExportAction {
  savePdf,
  saveImage,
  saveText,
  savePdfAndImage,
  saveExcel,
  saveTax,
  saveInsurance,
  sharePdf,
  shareImage,
  shareText,
  shareExcel,
}

enum _PayslipPaper { a4, a5, b5 }

extension _PayslipPaperDetails on _PayslipPaper {
  String get label => switch (this) {
    _PayslipPaper.a4 => 'A4',
    _PayslipPaper.a5 => 'A5',
    _PayslipPaper.b5 => 'B5',
  };

  PdfPageFormat get format => switch (this) {
    _PayslipPaper.a4 => PdfPageFormat.a4,
    _PayslipPaper.a5 => PdfPageFormat.a5,
    _PayslipPaper.b5 => PdfPageFormat(
      176 * PdfPageFormat.mm,
      250 * PdfPageFormat.mm,
    ),
  };

  double get designWidth => switch (this) {
    _PayslipPaper.a4 => 540,
    _PayslipPaper.a5 => 380,
    _PayslipPaper.b5 => 455,
  };
}

class PayslipScreen extends StatelessWidget {
  static const double _pdfSafePadding = 28;

  final Employee employee;
  final AppSettings settings;
  final SalaryRecord record;
  final GlobalKey _payslipKey = GlobalKey();

  PayslipScreen({
    super.key,
    required this.employee,
    required this.settings,
    required this.record,
  });

  String get _employeeFullName {
    final snapshot = record.employeeFullNameSnapshot?.trim();
    return snapshot != null && snapshot.isNotEmpty
        ? snapshot
        : employee.fullName;
  }

  int get _employeePersonnelCode =>
      record.employeePersonnelCodeSnapshot ?? employee.personnelCode;

  String get _employeeNationalId {
    final snapshot = record.employeeNationalIdSnapshot?.trim();
    return snapshot != null && snapshot.isNotEmpty
        ? snapshot
        : employee.nationalId;
  }

  String get _employeeFooterNote {
    final snapshot = record.employeePayslipFooterNoteSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return employee.payslipFooterNote.trim();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('فیش حقوق'),
        actions: [
          PopupMenuButton<_PayslipExportAction>(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'اشتراک‌گذاری',
            onSelected: (action) => _handleExport(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PayslipExportAction.shareImage,
                child: Text('اشتراک عکس'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.sharePdf,
                child: Text('اشتراک PDF'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.shareText,
                child: Text('اشتراک متن'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.shareExcel,
                child: Text('اشتراک Excel'),
              ),
            ],
          ),
          PopupMenuButton<_PayslipExportAction>(
            icon: const Icon(Icons.save_alt_rounded),
            tooltip: 'ذخیره',
            onSelected: (action) => _handleExport(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PayslipExportAction.saveImage,
                child: Text('ذخیره عکس'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.savePdf,
                child: Text('ذخیره PDF'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.saveText,
                child: Text('ذخیره TXT'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.savePdfAndImage,
                child: Text('ذخیره PDF و عکس'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.saveExcel,
                child: Text('ذخیره Excel'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.saveTax,
                child: Text('خروجی مالیات'),
              ),
              PopupMenuItem(
                value: _PayslipExportAction.saveInsurance,
                child: Text('خروجی بیمه'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'چاپ',
            onPressed: () => _printPdf(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RepaintBoundary(
            key: _payslipKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 750),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: _buildPayslip(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayslip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.companyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'فیش حقوق',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'تاریخ: ${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'دوره: ماه ${PersianNumberFormatter.toPersian(record.month.toString())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: scheme.outline, width: 1.5),
              right: BorderSide(color: scheme.outline, width: 1.5),
              bottom: BorderSide(color: scheme.outline, width: 1.5),
            ),
            color: scheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              _infoBox(
                context,
                'کد کارمند',
                PersianNumberFormatter.toPersian(
                  _employeePersonnelCode.toString(),
                ),
              ),
              _infoBox(
                context,
                'نام و نام خانوادگی',
                _employeeFullName,
                flex: 2,
              ),
              _infoBox(
                context,
                'کد ملی',
                PersianNumberFormatter.toPersian(_employeeNationalId),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _topBox(context, 'کارکرد-روز', _formatDays(record.workDays)),
            _topBox(
              context,
              'اضافه کار',
              '${PersianNumberFormatter.toPersian(record.overtimeHours.toStringAsFixed(0))} ساعت',
            ),
            _topBox(context, 'مرخصی', _formatDays(record.leaveDays)),
            _topBox(context, 'استعلاجی', _formatDays(record.sickLeaveDays)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                color: scheme.surfaceContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'حقوق و دستمزد (ریال)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 1,
                      height: 32,
                      child: ColoredBox(color: scheme.outline),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'کسورات (ریال)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(child: _buildEarningsTable(context)),
                    VerticalDivider(
                      width: 1,
                      color: scheme.outline,
                      thickness: 1.5,
                    ),
                    Expanded(child: _buildDeductionsTable(context)),
                  ],
                ),
              ),
              Divider(color: scheme.outline, height: 1, thickness: 1.5),
              Container(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    Expanded(
                      child: _payslipRow(
                        context,
                        'جمع',
                        record.totalEarnings,
                        isBold: true,
                      ),
                    ),
                    SizedBox(
                      width: 1,
                      height: 36,
                      child: ColoredBox(color: scheme.outline),
                    ),
                    Expanded(
                      child: _payslipRow(
                        context,
                        'جمع کسورات',
                        record.totalDeductions,
                        isBold: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              const Text(
                'خالص پرداختی:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              CurrencyText(
                record.finalPayment,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ریال',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        if (record.rounding != 0) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.functions_rounded,
                  size: 16,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'رند حقوق',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                CurrencyText(
                  record.rounding,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ریال',
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_employeeFooterNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              color: scheme.surfaceContainerLowest,
            ),
            child: Text(
              _employeeFooterNote,
              style: TextStyle(fontSize: 12, color: scheme.onSurface),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(height: 1, color: scheme.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'امضای کارمند',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(height: 1, color: scheme.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'امضای حسابدار',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(height: 1, color: scheme.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'امضای مدیریت',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoBox(
    BuildContext context,
    String label,
    String value, {
    int flex = 1,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBox(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline, width: 1.5),
          color: scheme.surfaceContainerLowest,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsTable(BuildContext context) {
    final items = [
      ('حقوق ثابت', record.baseSalary),
      ('حق مسکن', record.housing),
      ('حق خواروبار', record.food),
      ('حق تاهل', record.marriage),
      ('حق فرزند', record.childAllowance),
      ('نوبت کاری', record.shiftWork),
      ('پایه سنوات', record.seniority),
      ('سایر مزایا', record.otherBenefits),
      ('اضافه کار', record.overtimeAmount),
      ('مزایای ساعتی', record.hourlyBenefitsAmount),
    ];
    return Column(
      children: items
          .map((item) => _payslipRow(context, item.$1, item.$2))
          .toList(),
    );
  }

  Widget _buildDeductionsTable(BuildContext context) {
    final items = <(String, double)>[
      ('حق بیمه', record.insurance),
      ('مالیات حقوق', record.tax),
      ('قسط وام', record.loanInstallment),
      ('مساعده', record.advance),
      ('سایر کسورات', record.otherDeductions),
      ('کسر مرخصی مازاد', record.leaveDeduction),
    ];
    return Column(
      children: items
          .map((item) => _payslipRow(context, item.$1, item.$2))
          .toList(),
    );
  }

  Widget _payslipRow(
    BuildContext context,
    String label,
    double value, {
    bool isBold = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              PersianNumberFormatter.formatRial(value),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDays(double value, {bool persian = true}) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return persian ? PersianNumberFormatter.toPersian(text) : text;
  }

  Future<void> _handleExport(
    BuildContext context,
    _PayslipExportAction action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    try {
      switch (action) {
        case _PayslipExportAction.savePdf:
          final pdfPaper = await _askPaperSize(context, 'اندازه فایل PDF');
          if (pdfPaper == null) return;
          await _saveBytes(
            bytes: await _buildPdfBytes(paper: pdfPaper),
            fileName: '${_fileBaseName()}.pdf',
            extension: 'pdf',
          );
          break;
        case _PayslipExportAction.saveImage:
          final imagePaper = await _askPaperSize(context, 'اندازه عکس فیش');
          if (imagePaper == null) return;
          await _saveBytes(
            bytes: await _captureJpegBytes(paper: imagePaper),
            fileName: '${_fileBaseName()}.jpg',
            extension: 'jpg',
          );
          break;
        case _PayslipExportAction.saveText:
          await _saveBytes(
            bytes: Uint8List.fromList(utf8.encode(_buildTextContent())),
            fileName: '${_fileBaseName()}.txt',
            extension: 'txt',
          );
          break;
        case _PayslipExportAction.savePdfAndImage:
          final comboPaper = await _askPaperSize(
            context,
            'اندازه PDF و عکس فیش',
          );
          if (comboPaper == null) return;
          await _saveBytes(
            bytes: await _buildPdfBytes(paper: comboPaper),
            fileName: '${_fileBaseName()}.pdf',
            extension: 'pdf',
          );
          await _saveBytes(
            bytes: await _captureJpegBytes(paper: comboPaper),
            fileName: '${_fileBaseName()}.jpg',
            extension: 'jpg',
          );
          break;
        case _PayslipExportAction.saveExcel:
          await _saveBytes(
            bytes: await _buildExcelBytes(),
            fileName: '${_fileBaseName()}.xlsx',
            extension: 'xlsx',
          );
          break;
        case _PayslipExportAction.saveTax:
          await _saveTaxFiles();
          break;
        case _PayslipExportAction.saveInsurance:
          await _saveBytes(
            bytes: Uint8List(0),
            fileName: 'insurance_${record.year}${_twoDigit(record.month)}.txt',
            extension: 'txt',
          );
          break;
        case _PayslipExportAction.sharePdf:
          final sharePdfPaper = await _askPaperSize(context, 'اندازه فایل PDF');
          if (sharePdfPaper == null) return;
          await _shareFile(
            await _buildPdfBytes(paper: sharePdfPaper),
            '${_fileBaseName()}.pdf',
          );
          break;
        case _PayslipExportAction.shareImage:
          final shareImagePaper = await _askPaperSize(
            context,
            'اندازه عکس فیش',
          );
          if (shareImagePaper == null) return;
          await _shareFile(
            await _captureJpegBytes(paper: shareImagePaper),
            '${_fileBaseName()}.jpg',
          );
          break;
        case _PayslipExportAction.shareText:
          await SharePlus.instance.share(
            ShareParams(title: 'فیش حقوق', text: _buildTextContent()),
          );
          break;
        case _PayslipExportAction.shareExcel:
          await _shareFile(await _buildExcelBytes(), '${_fileBaseName()}.xlsx');
          break;
      }
      messenger.showSnackBar(
        SnackBar(
          content: const Text('عملیات خروجی انجام شد'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطا در خروجی: $e'),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  Future<void> _saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره فیش حقوق',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    if (path == null) return;
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<void> _saveTaxFiles() async {
    final period = '${record.year}${_twoDigit(record.month)}';
    await _saveBytes(
      bytes: Uint8List.fromList(utf8.encode(_buildTaxEmployeeFile())),
      fileName: 'WP$period.TXT',
      extension: 'txt',
    );
    await _saveBytes(
      bytes: Uint8List.fromList(utf8.encode(_buildTaxSalaryFile())),
      fileName: 'WH$period.TXT',
      extension: 'txt',
    );
  }

  String _buildTaxEmployeeFile() {
    final fields = [
      '1',
      _employeeNationalId,
      employee.firstName,
      employee.lastName,
      employee.fatherName,
      _taxDate(employee.birthDate),
      employee.birthCertificateNumber,
      employee.birthPlace,
      _educationCode(employee.education),
      employee.insuranceNumber.trim().isEmpty ? '5' : '2',
      employee.insuranceNumber,
      employee.insuranceNumber.trim().isEmpty ? '' : 'تامین اجتماعی',
      '1',
      '103',
      '103',
      '',
      employee.address,
      '13',
      employee.position.trim().isNotEmpty
          ? employee.position
          : employee.jobTitle,
      _employmentTypeCode(employee.employmentType),
      _taxDate(employee.startDate),
      employee.isActive ? '' : _taxDate(employee.endDate),
      '',
    ];
    return '${_csvRow(fields)}\r\n';
  }

  String _buildTaxSalaryFile() {
    final continuousCash =
        record.baseSalary +
        record.housing +
        record.food +
        record.marriage +
        record.childAllowance +
        record.seniority;
    final otherCash = record.otherBenefits + record.hourlyBenefitsAmount;
    final fields = [
      _employeeNationalId,
      '1',
      '1',
      '1',
      '84',
      '1',
      _rial(continuousCash),
      '0',
      '1',
      '0',
      '1',
      '0',
      '0',
      '0',
      '0',
      '0',
      _rial(record.overtimeAmount),
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      _rial(otherCash),
      '0',
      '0',
      '0',
      '0',
      '0',
      _rial(record.finalPayment),
      '0',
      _rial(record.shiftWork),
      '0',
      '0',
    ];
    return '${_csvRow(fields)}\r\n';
  }

  String _csvRow(List<Object?> fields) {
    return fields
        .map((value) => (value ?? '').toString().replaceAll(',', ' '))
        .join(',');
  }

  String _taxDate(String value) {
    return PersianNumberFormatter.toEnglish(
      value,
    ).replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _educationCode(String education) {
    return switch (education) {
      'زیر دیپلم' => '1',
      'دیپلم' => '2',
      'فوق دیپلم' => '3',
      'کارشناسی' => '4',
      'کارشناسی ارشد' => '5',
      'دکتری' => '6',
      'فوق دکتری' => '7',
      _ => '',
    };
  }

  String _employmentTypeCode(String employmentType) {
    return employmentType == 'قراردادی' ? '1' : '12';
  }

  String _rial(double value) => value.round().toString();

  String _twoDigit(int value) => value.toString().padLeft(2, '0');

  Future<void> _shareFile(Uint8List bytes, String fileName) async {
    final file = await _writeTempFile(bytes, fileName);
    await SharePlus.instance.share(
      ShareParams(title: 'فیش حقوق', files: [XFile(file.path)]),
    );
  }

  Future<File> _writeTempFile(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List> _captureJpegBytes({
    _PayslipPaper paper = _PayslipPaper.a5,
  }) async {
    final pdfBytes = await _buildPdfBytes(paper: paper);
    final page = await Printing.raster(
      pdfBytes,
      pages: const [0],
      dpi: 300,
    ).first;
    return _rasterToWhiteJpeg(page);
  }

  Uint8List _rasterToWhiteJpeg(PdfRaster raster) {
    final source = raster.pixels;
    final rgb = Uint8List(raster.width * raster.height * 3);
    for (var si = 0, di = 0; si < source.length; si += 4, di += 3) {
      final alpha = source[si + 3];
      rgb[di] = _blendOnWhite(source[si], alpha);
      rgb[di + 1] = _blendOnWhite(source[si + 1], alpha);
      rgb[di + 2] = _blendOnWhite(source[si + 2], alpha);
    }
    final image = img.Image.fromBytes(
      width: raster.width,
      height: raster.height,
      bytes: rgb.buffer,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  int _blendOnWhite(int channel, int alpha) {
    return ((channel * alpha + 255 * (255 - alpha)) ~/ 255)
        .clamp(0, 255)
        .toInt();
  }

  Future<Uint8List> _buildPdfBytes({
    _PayslipPaper paper = _PayslipPaper.a5,
  }) async {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'),
    );
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: paper.format,
        margin: pw.EdgeInsets.zero,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (ctx) => pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.all(_pdfSafePadding),
          child: pw.FittedBox(
            fit: pw.BoxFit.contain,
            alignment: pw.Alignment.topCenter,
            child: pw.SizedBox(
              width: paper.designWidth,
              child: _buildPdfContent(),
            ),
          ),
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _printPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    try {
      final paper = await _askPaperSize(context, 'اندازه چاپ فیش');
      if (paper == null) return;
      await Printing.layoutPdf(
        onLayout: (format) async => _buildPdfBytes(paper: paper),
        name:
            'فیش حقوق $_employeeFullName - ${PersianDateHelper.monthName(record.month)} ${record.year}',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطا در ساخت PDF: $e'),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  Future<_PayslipPaper?> _askPaperSize(BuildContext context, String title) {
    return showDialog<_PayslipPaper>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final paper in _PayslipPaper.values)
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: Text(paper.label),
                trailing: paper == _PayslipPaper.a5
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, paper),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
        ],
      ),
    );
  }

  String _buildTextContent() {
    final rows = [
      'فیش حقوق $_employeeFullName',
      'دوره: ${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())}',
      'کد پرسنلی: ${PersianNumberFormatter.toPersian(_employeePersonnelCode.toString())}',
      'کد ملی: ${PersianNumberFormatter.toPersian(_employeeNationalId)}',
      'کارکرد: ${_formatDays(record.workDays)} روز',
      'مرخصی: ${_formatDays(record.leaveDays)} روز',
      'استعلاجی: ${_formatDays(record.sickLeaveDays)} روز',
      '',
      'حقوق و مزایا:',
      ..._earningsRows().map(
        (r) =>
            '${r.$1}: ${PersianNumberFormatter.formatRial(r.$2, showUnit: true)}',
      ),
      '',
      'کسورات:',
      ..._deductionsRows().map(
        (r) =>
            '${r.$1}: ${PersianNumberFormatter.formatRial(r.$2, showUnit: true)}',
      ),
      '',
      'جمع حقوق و مزایا: ${PersianNumberFormatter.formatRial(record.totalEarnings, showUnit: true)}',
      'جمع کسورات: ${PersianNumberFormatter.formatRial(record.totalDeductions, showUnit: true)}',
      'خالص پرداختی: ${PersianNumberFormatter.formatRial(record.finalPayment, showUnit: true)}',
      if (_employeeFooterNote.isNotEmpty) ...['', _employeeFooterNote],
    ];
    return rows.join('\n');
  }

  Future<Uint8List> _buildExcelBytes() async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['فیش حقوق'];
    excel.delete('Sheet1');
    sheet.isRTL = true;
    final headerStyle = xls.CellStyle(
      bold: true,
      fontFamily: 'Vazirmatn',
      fontSize: 12,
      horizontalAlign: xls.HorizontalAlign.Center,
    );
    final cellStyle = xls.CellStyle(
      fontFamily: 'Vazirmatn',
      horizontalAlign: xls.HorizontalAlign.Right,
    );
    void row(List<String> values, {bool header = false}) {
      sheet.appendRow(values.map((v) => xls.TextCellValue(v)).toList());
      final rowIndex = sheet.maxRows - 1;
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = header
            ? headerStyle
            : cellStyle;
      }
    }

    row(['فیش حقوق', settings.companyName], header: true);
    row(['نام کارمند', _employeeFullName]);
    row([
      'کد پرسنلی',
      PersianNumberFormatter.toPersian(_employeePersonnelCode.toString()),
    ]);
    row([
      'دوره',
      '${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())}',
    ]);
    row(['کارکرد', '${_formatDays(record.workDays)} روز']);
    row(['مرخصی', '${_formatDays(record.leaveDays)} روز']);
    row(['استعلاجی', '${_formatDays(record.sickLeaveDays)} روز']);
    row([]);
    row(['حقوق و مزایا', 'مبلغ'], header: true);
    for (final item in _earningsRows()) {
      row([item.$1, PersianNumberFormatter.formatRial(item.$2)]);
    }
    row([
      'جمع حقوق و مزایا',
      PersianNumberFormatter.formatRial(record.totalEarnings),
    ], header: true);
    row([]);
    row(['کسورات', 'مبلغ'], header: true);
    for (final item in _deductionsRows()) {
      row([item.$1, PersianNumberFormatter.formatRial(item.$2)]);
    }
    row([
      'جمع کسورات',
      PersianNumberFormatter.formatRial(record.totalDeductions),
    ], header: true);
    row([
      'خالص پرداختی',
      PersianNumberFormatter.formatRial(record.finalPayment),
    ], header: true);
    if (_employeeFooterNote.isNotEmpty) {
      row([]);
      row(['توضیحات انتهای فیش', _employeeFooterNote]);
    }

    for (var col = 0; col < 2; col++) {
      sheet.setColumnWidth(col, col == 0 ? 24 : 28);
    }
    final bytes = excel.encode();
    if (bytes == null) throw StateError('ساخت فایل Excel انجام نشد.');
    return Uint8List.fromList(bytes);
  }

  String _fileBaseName() {
    final period =
        '${PersianDateHelper.monthName(record.month)}-${record.year}';
    final cleanName = _employeeFullName.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '-',
    );
    return 'فیش حقوق $cleanName $period';
  }

  pw.Widget _buildPdfContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.companyName,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'فیش حقوق',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'تاریخ: ${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
            color: PdfColors.grey200,
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'کد کارمند: ${PersianNumberFormatter.toPersian(_employeePersonnelCode.toString())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'نام و نام خانوادگی: $_employeeFullName',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'کد ملی: ${PersianNumberFormatter.toPersian(_employeeNationalId)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'کارکرد - روز',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _formatDays(record.workDays),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'اضافه کار',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '${PersianNumberFormatter.toPersian(record.overtimeHours.toStringAsFixed(0))} ساعت',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'مرخصی',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _formatDays(record.leaveDays),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'استعلاجی',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _formatDays(record.sickLeaveDays),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Column(
            children: [
              pw.Container(
                color: PdfColors.grey200,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text(
                            'حقوق و دستمزد (ریال)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text(
                            'کسورات (ریال)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _pdfTable(_earningsRows())),
                  pw.Container(width: 1, color: PdfColors.black),
                  pw.Expanded(child: _pdfTable(_deductionsRows())),
                ],
              ),
              pw.Container(height: 1, color: PdfColors.black),
              pw.Container(
                color: PdfColors.yellow50,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfRow('جمع', record.totalEarnings, bold: true),
                    ),
                    pw.Container(width: 1, color: PdfColors.black),
                    pw.Expanded(
                      child: _pdfRow(
                        'جمع کسورات',
                        record.totalDeductions,
                        bold: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.green700,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'خالص پرداختی:',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                '${PersianNumberFormatter.formatRial(record.finalPayment)} ریال',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (record.rounding != 0) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300, width: 0.7),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'رند حقوق',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  '${PersianNumberFormatter.formatRial(record.rounding)} ریال',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_employeeFooterNote.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.7)),
            child: pw.Text(
              _employeeFooterNote,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            _pdfSignatureBox('امضای کارمند'),
            pw.SizedBox(width: 22),
            _pdfSignatureBox('امضای حسابدار'),
            pw.SizedBox(width: 22),
            _pdfSignatureBox('امضای مدیریت'),
          ],
        ),
      ],
    );
  }

  List<(String, double)> _earningsRows() => [
    ('حقوق ثابت', record.baseSalary),
    ('حق مسکن', record.housing),
    ('حق خواروبار', record.food),
    ('حق تاهل', record.marriage),
    ('حق فرزند', record.childAllowance),
    ('نوبت کاری', record.shiftWork),
    ('پایه سنوات', record.seniority),
    ('سایر مزایا', record.otherBenefits),
    ('اضافه کار', record.overtimeAmount),
    ('مزایای ساعتی', record.hourlyBenefitsAmount),
  ];

  List<(String, double)> _deductionsRows() => [
    ('حق بیمه', record.insurance),
    ('مالیات حقوق', record.tax),
    ('قسط وام', record.loanInstallment),
    ('مساعده', record.advance),
    ('سایر کسورات', record.otherDeductions),
    ('کسر مرخصی مازاد', record.leaveDeduction),
  ];

  pw.Widget _pdfTable(List<(String, double)> rows) {
    return pw.Column(children: rows.map((r) => _pdfRow(r.$1, r.$2)).toList());
  }

  pw.Widget _pdfSignatureBox(String label) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.SizedBox(height: 26),
          pw.Container(height: 0.8, color: PdfColors.black),
          pw.SizedBox(height: 5),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _pdfRow(String label, double value, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            PersianNumberFormatter.formatRial(value),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
