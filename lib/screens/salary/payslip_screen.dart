import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';

class PayslipScreen extends StatelessWidget {
  final Employee employee;
  final AppSettings settings;
  final SalaryRecord record;

  const PayslipScreen({
    super.key,
    required this.employee,
    required this.settings,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('فیش حقوق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'چاپ / ذخیره PDF',
            onPressed: () => _printPdf(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                  employee.personnelCode.toString(),
                ),
              ),
              _infoBox(
                context,
                'نام و نام خانوادگی',
                employee.fullName,
                flex: 2,
              ),
              _infoBox(
                context,
                'کد ملی',
                PersianNumberFormatter.toPersian(employee.nationalId),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _topBox(
              context,
              'کارکرد-روز',
              PersianNumberFormatter.toPersian(record.workDays.toString()),
            ),
            _topBox(
              context,
              'اضافه کار',
              '${PersianNumberFormatter.toPersian(record.overtimeHours.toStringAsFixed(0))} ساعت',
            ),
            _topBox(
              context,
              'مرخصی',
              PersianNumberFormatter.toPersian(record.leaveDays.toString()),
            ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'رند کسورات: ${PersianNumberFormatter.toPersian(record.rounding.toString())}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
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

  Future<void> _printPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    try {
      final fontRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'),
      );
      final fontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'),
      );

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (ctx) => _buildPdfContent(),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name:
            'فیش حقوق ${employee.fullName} - ${PersianDateHelper.monthName(record.month)} ${record.year}',
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
                    'تاریخ: ${PersianDateHelper.monthName(record.month)} ${record.year}',
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
                  'کد کارمند: ${employee.personnelCode}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'نام و نام خانوادگی: ${employee.fullName}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'کد ملی: ${employee.nationalId}',
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
                      '${record.workDays}',
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
                      '${record.overtimeHours.toStringAsFixed(0)} ساعت',
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
                      '${record.leaveDays}',
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
                '${PersianNumberFormatter.formatRial(record.finalPayment, persian: false)} ریال',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
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
  ];

  pw.Widget _pdfTable(List<(String, double)> rows) {
    return pw.Column(children: rows.map((r) => _pdfRow(r.$1, r.$2)).toList());
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
            PersianNumberFormatter.formatRial(value, persian: false),
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
