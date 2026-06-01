import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/persian_number_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _formKey = GlobalKey<FormState>();

  AppSettings? _settings;
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _companyNameCtrl;

  double _dailyWage = 0;
  double _monthlyFood = 0;
  double _monthlyHousing = 0;
  double _monthlyMarriage = 0;
  double _monthlyChild = 0;
  double _dailySeniority = 0;
  double _salaryRateA = 0;
  double _salaryRateB = 0;
  double _fixedRial = 0;
  double _employeeInsuranceRate = 0;
  double _employerInsuranceRate = 0;
  double _unemploymentInsuranceRate = 0;
  double _twoSevenBaseRate = 0;

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    _settings = await _service.getCurrentSettings();
    _companyNameCtrl.text = _settings!.companyName;
    _dailyWage = _settings!.dailyWage;
    _monthlyFood = _settings!.monthlyFood;
    _monthlyHousing = _settings!.monthlyHousing;
    _monthlyMarriage = _settings!.monthlyMarriage;
    _monthlyChild = _settings!.monthlyChild;
    _dailySeniority = _settings!.dailySeniority;
    _salaryRateA = _settings!.salaryRateA;
    _salaryRateB = _settings!.salaryRateB;
    _fixedRial = _settings!.fixedRial;
    _employeeInsuranceRate = _settings!.employeeInsuranceRate;
    _employerInsuranceRate = _settings!.employerInsuranceRate;
    _unemploymentInsuranceRate = _settings!.unemploymentInsuranceRate;
    _twoSevenBaseRate = _settings!.twoSevenBaseRate;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = _settings!.copyWith(
        companyName: _companyNameCtrl.text.trim(),
        dailyWage: _dailyWage,
        monthlyFood: _monthlyFood,
        monthlyHousing: _monthlyHousing,
        monthlyMarriage: _monthlyMarriage,
        monthlyChild: _monthlyChild,
        dailySeniority: _dailySeniority,
        salaryRateA: _salaryRateA,
        salaryRateB: _salaryRateB,
        fixedRial: _fixedRial,
        employeeInsuranceRate: _employeeInsuranceRate,
        employerInsuranceRate: _employerInsuranceRate,
        unemploymentInsuranceRate: _unemploymentInsuranceRate,
        twoSevenBaseRate: _twoSevenBaseRate,
      );
      await _service.update(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات با موفقیت ذخیره شد'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازنشانی تنظیمات'),
        content: const Text('آیا از بازنشانی تنظیمات به مقادیر پیش‌فرض ۱۴۰۵ مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بازنشانی'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.resetToDefaults();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تنظیمات بازنشانی شد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات حقوق پایه ۱۴۰۵'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'بازنشانی به مقادیر پیش‌فرض',
            onPressed: _resetDefaults,
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('ذخیره', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 16),
                  _section(
                    title: 'اطلاعات کلی',
                    icon: Icons.business,
                    color: Colors.indigo,
                    children: [
                      TextFormField(
                        controller: _companyNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'نام شرکت',
                          prefixIcon: Icon(Icons.apartment),
                        ),
                      ),
                    ],
                  ),
                  _section(
                    title: 'حقوق و دستمزد پایه',
                    icon: Icons.payments,
                    color: AppTheme.successColor,
                    children: [
                      _row([
                        PersianNumberField(
                          label: 'دستمزد روزانه پایه',
                          isCurrency: true,
                          prefixIcon: Icons.attach_money,
                          initialValue: _dailyWage,
                          onChanged: (v) => _dailyWage = v?.toDouble() ?? 0,
                        ),
                        PersianNumberField(
                          label: 'پایه سنوات (روزانه)',
                          isCurrency: true,
                          prefixIcon: Icons.workspace_premium,
                          initialValue: _dailySeniority,
                          onChanged: (v) => _dailySeniority = v?.toDouble() ?? 0,
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _row([
                        PersianNumberField(
                          label: 'حق مسکن (ماهانه)',
                          isCurrency: true,
                          prefixIcon: Icons.home,
                          initialValue: _monthlyHousing,
                          onChanged: (v) => _monthlyHousing = v?.toDouble() ?? 0,
                        ),
                        PersianNumberField(
                          label: 'حق خواروبار / بن (ماهانه)',
                          isCurrency: true,
                          prefixIcon: Icons.shopping_basket,
                          initialValue: _monthlyFood,
                          onChanged: (v) => _monthlyFood = v?.toDouble() ?? 0,
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _row([
                        PersianNumberField(
                          label: 'حق تاهل (ماهانه)',
                          isCurrency: true,
                          prefixIcon: Icons.favorite,
                          initialValue: _monthlyMarriage,
                          onChanged: (v) => _monthlyMarriage = v?.toDouble() ?? 0,
                        ),
                        PersianNumberField(
                          label: 'حق فرزند (ماهانه - هر فرزند)',
                          isCurrency: true,
                          prefixIcon: Icons.child_care,
                          initialValue: _monthlyChild,
                          onChanged: (v) => _monthlyChild = v?.toDouble() ?? 0,
                        ),
                      ]),
                    ],
                  ),
                  _section(
                    title: 'ضرایب افزایش دستمزد ۱۴۰۵',
                    icon: Icons.trending_up,
                    color: Colors.deepPurple,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'فرمول: دستمزد ۱۴۰۵ = دستمزد ۱۴۰۴ × ضریب + ثابت ریالی',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _row([
                        PersianNumberField(
                          label: 'ضریب الف (کارگری)',
                          prefixIcon: Icons.engineering,
                          initialValue: _salaryRateA,
                          onChanged: (v) => _salaryRateA = v?.toDouble() ?? 0,
                        ),
                        PersianNumberField(
                          label: 'ضریب ب (سایر سطوح)',
                          prefixIcon: Icons.work,
                          initialValue: _salaryRateB,
                          onChanged: (v) => _salaryRateB = v?.toDouble() ?? 0,
                        ),
                      ]),
                      const SizedBox(height: 12),
                      PersianNumberField(
                        label: 'ثابت ریالی',
                        isCurrency: true,
                        prefixIcon: Icons.add,
                        initialValue: _fixedRial,
                        onChanged: (v) => _fixedRial = v?.toDouble() ?? 0,
                      ),
                    ],
                  ),
                  _section(
                    title: 'بیمه تامین اجتماعی',
                    icon: Icons.health_and_safety,
                    color: Colors.teal,
                    children: [
                      _row([
                        PersianNumberField(
                          label: 'سهم کارمند (۰.۰۷ = ۷٪)',
                          prefixIcon: Icons.person,
                          initialValue: _employeeInsuranceRate,
                          onChanged: (v) => _employeeInsuranceRate = v?.toDouble() ?? 0,
                        ),
                        PersianNumberField(
                          label: 'سهم کارفرما (۰.۲۰ = ۲۰٪)',
                          prefixIcon: Icons.business,
                          initialValue: _employerInsuranceRate,
                          onChanged: (v) => _employerInsuranceRate = v?.toDouble() ?? 0,
                        ),
                      ]),
                      const SizedBox(height: 12),
                      PersianNumberField(
                        label: 'بیمه بیکاری (۰.۰۳ = ۳٪)',
                        prefixIcon: Icons.work_off,
                        initialValue: _unemploymentInsuranceRate,
                        onChanged: (v) => _unemploymentInsuranceRate = v?.toDouble() ?? 0,
                      ),
                    ],
                  ),
                  _section(
                    title: 'معافیت مالیاتی دو هفتم',
                    icon: Icons.discount,
                    color: Colors.orange,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'این معافیت برای شاغلین در صنایع سخت اعمال می‌شود. ضریب طبق فایل اکسل ارسالی تقریباً ۰.۰۱۸۶ است.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PersianNumberField(
                        label: 'ضریب معافیت دو هفتم (مثلاً ۰.۰۱۸۶)',
                        prefixIcon: Icons.percent,
                        initialValue: _twoSevenBaseRate,
                        onChanged: (v) => _twoSevenBaseRate = v?.toDouble() ?? 0,
                      ),
                    ],
                  ),
                  _section(
                    title: 'جدول مالیات بر حقوق ۱۴۰۵',
                    icon: Icons.account_balance,
                    color: Colors.red,
                    children: [
                      _buildTaxBracketTable(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('ذخیره تنظیمات'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDarkColor, AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_applications, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تنظیمات سال ۱۴۰۵',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'این مقادیر بر اساس مصوبه شورای عالی کار سال ۱۴۰۵ به صورت پیش‌فرض تنظیم شده‌اند.\nدر صورت تغییر، می‌توانید مقادیر را ویرایش کنید.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBracketTable() {
    // جدول مالیات
    final brackets = [
      ('۰', '۴۰۰,۰۰۰,۰۰۰', '۰٪', 'معاف'),
      ('۴۰۰,۰۰۰,۰۰۱', '۸۰۰,۰۰۰,۰۰۰', '۱۰٪', ''),
      ('۸۰۰,۰۰۰,۰۰۱', '۱,۰۰۰,۰۰۰,۰۰۰', '۱۵٪', ''),
      ('۱,۰۰۰,۰۰۰,۰۰۱', '۱۲,۰۰۰,۰۰۰,۰۰۰', '۲۰٪', ''),
      ('۱۲,۰۰۰,۰۰۰,۰۰۱', '۱۴,۰۰۰,۰۰۰,۰۰۰', '۲۵٪', ''),
      ('۱۴,۰۰۰,۰۰۰,۰۰۱', 'بیشتر', '۳۰٪', ''),
    ];
    return Table(
      border: TableBorder.all(color: AppTheme.borderColor),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.red.shade50),
          children: const [
            _TaxCell('از (ریال)', isHeader: true),
            _TaxCell('تا (ریال)', isHeader: true),
            _TaxCell('نرخ', isHeader: true),
            _TaxCell('وضعیت', isHeader: true),
          ],
        ),
        ...brackets.map((b) => TableRow(
              children: [
                _TaxCell(b.$1),
                _TaxCell(b.$2),
                _TaxCell(b.$3),
                _TaxCell(b.$4),
              ],
            )),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      widgets.add(Expanded(child: children[i]));
      if (i < children.length - 1) widgets.add(const SizedBox(width: 12));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

class _TaxCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _TaxCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        PersianNumberFormatter.toPersian(text),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
