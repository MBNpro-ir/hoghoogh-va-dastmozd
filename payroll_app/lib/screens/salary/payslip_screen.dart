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
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        title: const Text('فیش حقوق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // هدر
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'فیش حقوق',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'تاریخ: ${PersianDateHelper.monthName(record.month)} ${PersianNumberFormatter.toPersian(record.year.toString())}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'دوره: ماه ${PersianNumberFormatter.toPersian(record.month.toString())}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        // اطلاعات کارمند
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.borderColor, width: 1.5),
              right: BorderSide(color: AppTheme.borderColor, width: 1.5),
              bottom: BorderSide(color: AppTheme.borderColor, width: 1.5),
            ),
            color: const Color(0xFFF5F5F5),
          ),
          child: Row(
            children: [
              _infoBox('کد کارمند', PersianNumberFormatter.toPersian(employee.personnelCode.toString())),
              _infoBox('نام و نام خانوادگی', employee.fullName, flex: 2),
              _infoBox('کد ملی', PersianNumberFormatter.toPersian(employee.nationalId)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // جدول کارکرد
        Row(
          children: [
            _topBox('کارکرد-روز', PersianNumberFormatter.toPersian(record.workDays.toString())),
            _topBox('اضافه کار', '${PersianNumberFormatter.toPersian(record.overtimeHours.toStringAsFixed(0))} ساعت'),
            _topBox('مرخصی', PersianNumberFormatter.toPersian(record.leaveDays.toString())),
          ],
        ),
        const SizedBox(height: 16),
        // جدول حقوق و کسورات
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              // هدر دو ستونه
              Container(
                color: const Color(0xFFEEEEEE),
                child: const Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'حقوق و دستمزد (ریال)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 1,
                      height: 32,
                      child: ColoredBox(color: AppTheme.borderColor),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'کسورات (ریال)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // محتوای دو ستونه
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(child: _buildEarningsTable()),
                    const VerticalDivider(width: 1, color: AppTheme.borderColor, thickness: 1.5),
                    Expanded(child: _buildDeductionsTable()),
                  ],
                ),
              ),
              // جمع‌ها
              const Divider(color: AppTheme.borderColor, height: 1, thickness: 1.5),
              Container(
                color: const Color(0xFFFFF9C4),
                child: Row(
                  children: [
                    Expanded(child: _payslipRow('جمع', record.totalEarnings, isBold: true)),
                    const SizedBox(
                      width: 1,
                      height: 36,
                      child: ColoredBox(color: AppTheme.borderColor),
                    ),
                    Expanded(child: _payslipRow('جمع کسورات', record.totalDeductions, isBold: true)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // خالص پرداختی
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: BorderRadius.circular(6),
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
              const Text('ریال', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // امضا
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(height: 1, color: AppTheme.borderColor),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('امضای کارمند', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(height: 1, color: AppTheme.borderColor),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('امضای حسابدار', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(height: 1, color: AppTheme.borderColor),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('امضای مدیریت', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoBox(String label, String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _topBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor, width: 1.5),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsTable() {
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
      children: items.map((item) => _payslipRow(item.$1, item.$2)).toList(),
    );
  }

  Widget _buildDeductionsTable() {
    final items = <(String, double)>[
      ('حق بیمه', record.insurance),
      ('مالیات حقوق', record.tax),
      ('قسط وام', record.loanInstallment),
      ('مساعده', record.advance),
      ('سایر کسورات', record.otherDeductions),
    ];
    return Column(
      children: items.map((item) => _payslipRow(item.$1, item.$2)).toList(),
    );
  }

  Widget _payslipRow(String label, double value, {bool isBold = false}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // بارگذاری فونت فارسی
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
        name: 'فیش حقوق ${employee.fullName} - ${PersianDateHelper.monthName(record.month)} ${record.year}',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('خطا در ساخت PDF: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  pw.Widget _buildPdfContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // هدر
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(settings.companyName,
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('فیش حقوق', style: const pw.TextStyle(fontSize: 11)),
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
        // اطلاعات کارمند
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1), color: PdfColors.grey200),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('کد کارمند: ${employee.personnelCode}', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('نام و نام خانوادگی: ${employee.fullName}',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Expanded(
                child: pw.Text('کد ملی: ${employee.nationalId}',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        // کارکرد
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Text('کارکرد - روز', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('${record.workDays}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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
                    pw.Text('اضافه کار', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('${record.overtimeHours.toStringAsFixed(0)} ساعت',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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
                    pw.Text('مرخصی', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('${record.leaveDays}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // جدول حقوق و کسورات
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Column(
            children: [
              // هدر
              pw.Container(
                color: PdfColors.grey200,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('حقوق و دستمزد (ریال)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('کسورات (ریال)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ردیف‌ها
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _pdfTable(_earningsRows())),
                  pw.Container(width: 1, color: PdfColors.black),
                  pw.Expanded(child: _pdfTable(_deductionsRows())),
                ],
              ),
              pw.Container(height: 1, color: PdfColors.black),
              // جمع
              pw.Container(
                color: PdfColors.yellow50,
                child: pw.Row(
                  children: [
                    pw.Expanded(child: _pdfRow('جمع', record.totalEarnings, bold: true)),
                    pw.Container(width: 1, color: PdfColors.black),
                    pw.Expanded(child: _pdfRow('جمع کسورات', record.totalDeductions, bold: true)),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        // خالص دریافتی
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: PdfColors.green700, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Row(
            children: [
              pw.Text('خالص پرداختی:',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Spacer(),
              pw.Text(
                '${PersianNumberFormatter.formatRial(record.finalPayment, persian: false)} ریال',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
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
    return pw.Column(
      children: rows.map((r) => _pdfRow(r.$1, r.$2)).toList(),
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
