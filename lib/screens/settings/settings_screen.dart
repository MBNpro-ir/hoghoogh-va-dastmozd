import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../providers/theme_controller.dart';
import '../../services/appearance_service.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../../utils/constants.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/gradient_helpers.dart';
import '../../utils/responsive.dart';
import '../../widgets/persian_number_field.dart';
import '../help/help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _backupService = BackupService();
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
        SnackBar(
          content: const Text('تنظیمات با موفقیت ذخیره شد'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
        content: const Text(
          'آیا از بازنشانی تنظیمات به مقادیر پیش‌فرض ۱۴۰۵ مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تنظیمات بازنشانی شد')));
    }
  }

  Future<void> _backup() async {
    try {
      final path = await _backupService.backupDatabase();
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('بکاپ ذخیره شد: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بکاپ: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازیابی بکاپ'),
        content: const Text(
          'با ریستور بکاپ، دیتابیس فعلی جایگزین می‌شود. بهتر است قبل از ادامه از دیتای فعلی بکاپ بگیرید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('انتخاب بکاپ'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final path = await _backupService.restoreDatabase();
      if (!mounted || path == null) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('بکاپ بازیابی شد: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بازیابی: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
    );
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
            icon: const Icon(Icons.restore_rounded),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('ذخیره'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInUp(child: _buildInfoBanner()),
                  const SizedBox(height: 20),
                  FadeInUp(
                    delay: const Duration(milliseconds: 60),
                    child: _section(
                      title: 'اطلاعات کلی',
                      icon: Icons.business_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                      children: [
                        TextFormField(
                          controller: _companyNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'نام شرکت',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 120),
                    child: _section(
                      title: 'حقوق و دستمزد پایه',
                      icon: Icons.payments_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      children: [
                        _row([
                          PersianNumberField(
                            label: 'دستمزد روزانه پایه',
                            isCurrency: true,
                            prefixIcon: Icons.attach_money_rounded,
                            initialValue: _dailyWage,
                            onChanged: (v) => _dailyWage = v?.toDouble() ?? 0,
                          ),
                          PersianNumberField(
                            label: 'پایه سنوات (روزانه)',
                            isCurrency: true,
                            prefixIcon: Icons.workspace_premium_rounded,
                            initialValue: _dailySeniority,
                            onChanged: (v) =>
                                _dailySeniority = v?.toDouble() ?? 0,
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _row([
                          PersianNumberField(
                            label: 'حق مسکن (ماهانه)',
                            isCurrency: true,
                            prefixIcon: Icons.home_rounded,
                            initialValue: _monthlyHousing,
                            onChanged: (v) =>
                                _monthlyHousing = v?.toDouble() ?? 0,
                          ),
                          PersianNumberField(
                            label: 'حق خواروبار / بن (ماهانه)',
                            isCurrency: true,
                            prefixIcon: Icons.shopping_basket_rounded,
                            initialValue: _monthlyFood,
                            onChanged: (v) => _monthlyFood = v?.toDouble() ?? 0,
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _row([
                          PersianNumberField(
                            label: 'حق تاهل (ماهانه)',
                            isCurrency: true,
                            prefixIcon: Icons.favorite_rounded,
                            initialValue: _monthlyMarriage,
                            onChanged: (v) =>
                                _monthlyMarriage = v?.toDouble() ?? 0,
                          ),
                          PersianNumberField(
                            label: 'حق فرزند (ماهانه - هر فرزند)',
                            isCurrency: true,
                            prefixIcon: Icons.child_care_rounded,
                            initialValue: _monthlyChild,
                            onChanged: (v) =>
                                _monthlyChild = v?.toDouble() ?? 0,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 180),
                    child: _section(
                      title: 'ضرایب افزایش دستمزد ۱۴۰۵',
                      icon: Icons.trending_up_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.tertiary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Icon(
                                Icons.info_rounded,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'فرمول: دستمزد ۱۴۰۵ = دستمزد ۱۴۰۴ × ضریب + ثابت ریالی',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _row([
                          PersianNumberField(
                            label: 'ضریب الف (کارگری)',
                            prefixIcon: Icons.engineering_rounded,
                            initialValue: _salaryRateA,
                            onChanged: (v) => _salaryRateA = v?.toDouble() ?? 0,
                          ),
                          PersianNumberField(
                            label: 'ضریب ب (سایر سطوح)',
                            prefixIcon: Icons.work_rounded,
                            initialValue: _salaryRateB,
                            onChanged: (v) => _salaryRateB = v?.toDouble() ?? 0,
                          ),
                        ]),
                        const SizedBox(height: 14),
                        PersianNumberField(
                          label: 'ثابت ریالی',
                          isCurrency: true,
                          prefixIcon: Icons.add_rounded,
                          initialValue: _fixedRial,
                          onChanged: (v) => _fixedRial = v?.toDouble() ?? 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 240),
                    child: _section(
                      title: 'بیمه تامین اجتماعی',
                      icon: Icons.health_and_safety_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      children: [
                        _row([
                          PersianNumberField(
                            label: 'سهم کارمند (۰.۰۷ = ۷٪)',
                            prefixIcon: Icons.person_rounded,
                            initialValue: _employeeInsuranceRate,
                            onChanged: (v) =>
                                _employeeInsuranceRate = v?.toDouble() ?? 0,
                          ),
                          PersianNumberField(
                            label: 'سهم کارفرما (۰.۲۰ = ۲۰٪)',
                            prefixIcon: Icons.business_rounded,
                            initialValue: _employerInsuranceRate,
                            onChanged: (v) =>
                                _employerInsuranceRate = v?.toDouble() ?? 0,
                          ),
                        ]),
                        const SizedBox(height: 14),
                        PersianNumberField(
                          label: 'بیمه بیکاری (۰.۰۳ = ۳٪)',
                          prefixIcon: Icons.work_off_rounded,
                          initialValue: _unemploymentInsuranceRate,
                          onChanged: (v) =>
                              _unemploymentInsuranceRate = v?.toDouble() ?? 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _section(
                      title: 'معافیت مالیاتی دو هفتم',
                      icon: Icons.discount_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Icon(
                                Icons.info_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'این معافیت برای شاغلین در صنایع سخت اعمال می‌شود. طبق فایل اکسل، مبلغ معافیت برابر دو هفتم حق بیمه کارگر است.',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        PersianNumberField(
                          label: 'ضریب معافیت دو هفتم بیمه (مثلاً ۰.۲۸۵۷)',
                          prefixIcon: Icons.percent_rounded,
                          initialValue: _twoSevenBaseRate,
                          onChanged: (v) =>
                              _twoSevenBaseRate = v?.toDouble() ?? 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 360),
                    child: _section(
                      title: 'جدول مالیات بر حقوق ۱۴۰۵',
                      icon: Icons.account_balance_rounded,
                      color: Theme.of(context).colorScheme.error,
                      children: [_buildTaxBracketTable()],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 420),
                    child: const _AccessibilitySection(),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 480),
                    child: _BackupSection(
                      onBackup: _backup,
                      onRestore: _restore,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 540),
                    child: _AboutSection(onOpenHelp: _openHelp),
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
    final scheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final isMobile = r.isMobileSize;
    final icon = Container(
      width: isMobile ? 48 : 56,
      height: isMobile ? 48 : 56,
      decoration: BoxDecoration(
        color: context.onGradientOverlayStrong,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
      ),
      child: Icon(
        Icons.tune_rounded,
        color: context.onGradientText,
        size: isMobile ? 26 : 32,
      ),
    );
    final titleStyle = TextStyle(
      fontFamily: 'Vazirmatn',
      color: context.onGradientText,
      fontSize: isMobile ? 16 : 20,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = TextStyle(
      fontFamily: 'Vazirmatn',
      color: context.onGradientTextMuted,
      fontSize: isMobile ? 12 : 13,
      height: 1.6,
    );
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('تنظیمات سال ۱۴۰۵', style: titleStyle),
        const SizedBox(height: 6),
        Text(
          'این مقادیر بر اساس مصوبه شورای عالی کار سال ۱۴۰۵ به صورت پیش‌فرض تنظیم شده‌اند.\nدر صورت تغییر، می‌توانید مقادیر را ویرایش کنید.',
          style: bodyStyle,
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevation2(scheme.shadow),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('تنظیمات سال ۱۴۰۵', style: titleStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'این مقادیر بر اساس مصوبه شورای عالی کار سال ۱۴۰۵ به صورت پیش‌فرض تنظیم شده‌اند.\nدر صورت تغییر، می‌توانید مقادیر را ویرایش کنید.',
                  style: bodyStyle,
                ),
              ],
            )
          : Row(
              textDirection: TextDirection.rtl,
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(child: textColumn),
              ],
            ),
    );
  }

  Widget _buildTaxBracketTable() {
    final scheme = Theme.of(context).colorScheme;
    final brackets = [
      ('۰', '۴۰۰,۰۰۰,۰۰۰', '۰٪', 'معاف'),
      ('۴۰۰,۰۰۰,۰۰۱', '۸۰۰,۰۰۰,۰۰۰', '۱۰٪', ''),
      ('۸۰۰,۰۰۰,۰۰۱', '۱,۰۰۰,۰۰۰,۰۰۰', '۱۵٪', ''),
      ('۱,۰۰۰,۰۰۰,۰۰۱', '۱۲,۰۰۰,۰۰۰,۰۰۰', '۲۰٪', ''),
      ('۱۲,۰۰۰,۰۰۰,۰۰۱', '۱۴,۰۰۰,۰۰۰,۰۰۰', '۲۵٪', ''),
      ('۱۴,۰۰۰,۰۰۰,۰۰۱', 'بیشتر', '۳۰٪', ''),
    ];
    return Table(
      border: TableBorder.all(color: scheme.outlineVariant),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.4),
          ),
          children: const [
            _TaxCell('از (ریال)', isHeader: true),
            _TaxCell('تا (ریال)', isHeader: true),
            _TaxCell('نرخ', isHeader: true),
            _TaxCell('وضعیت', isHeader: true),
          ],
        ),
        ...brackets.map(
          (b) => TableRow(
            children: [
              _TaxCell(b.$1),
              _TaxCell(b.$2),
              _TaxCell(b.$3),
              _TaxCell(b.$4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 500) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        final widgets = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          widgets.add(Expanded(child: children[i]));
          if (i < children.length - 1) widgets.add(const SizedBox(width: 14));
        }
        return Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        );
      },
    );
  }
}

class _TaxCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _TaxCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        PersianNumberFormatter.toPersian(text),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? scheme.onErrorContainer : scheme.onSurface,
        ),
      ),
    );
  }
}

// -------- بخش دسترسی‌پذیری --------
class _AccessibilitySection extends StatelessWidget {
  const _AccessibilitySection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<ThemeController>();
    final a = controller.accessibility;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.accessibility_new_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'دسترسی‌پذیری',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'جدید',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 56),
              child: Text(
                'تنظیمات دسترسی‌پذیری برای راحتی استفاده همه کاربران، شامل تنظیم اندازه متن، کنتراست و کاهش انیمیشن‌ها.',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 8),
            _TextScaleTile(
              value: a.textScale,
              onChanged: (v) => controller.updateAccessibility(textScale: v),
            ),
            _SwitchTile(
              icon: Icons.contrast_rounded,
              title: 'کنتراست بالا',
              subtitle: 'افزایش کنتراست رنگ‌ها برای دید بهتر',
              value: a.highContrast,
              onChanged: (v) => controller.updateAccessibility(highContrast: v),
            ),
            _SwitchTile(
              icon: Icons.motion_photos_pause_rounded,
              title: 'کاهش انیمیشن‌ها',
              subtitle: 'غیرفعال‌سازی انتقال‌ها و انیمیشن‌ها',
              value: a.reduceMotion,
              onChanged: (v) => controller.updateAccessibility(reduceMotion: v),
            ),
            _SwitchTile(
              icon: Icons.touch_app_rounded,
              title: 'دکمه‌های بزرگ',
              subtitle: 'افزایش اندازه دکمه‌ها و کنترل‌ها برای لمس راحت‌تر',
              value: a.largeControls,
              onChanged: (v) =>
                  controller.updateAccessibility(largeControls: v),
            ),
            _SwitchTile(
              icon: Icons.space_bar_rounded,
              title: 'فاصله بیشتر بین المان‌ها',
              subtitle: 'افزایش فضای خالی بین آیتم‌ها برای خوانایی بهتر',
              value: a.extraSpacing,
              onChanged: (v) => controller.updateAccessibility(extraSpacing: v),
            ),
            _SwitchTile(
              icon: Icons.volume_up_rounded,
              title: 'راهنمای صفحه‌خوان',
              subtitle: 'نمایش راهنما برای کاربران صفحه‌خوان',
              value: a.screenReaderHints,
              onChanged: (v) =>
                  controller.updateAccessibility(screenReaderHints: v),
            ),
            _SwitchTile(
              icon: Icons.emoji_emotions_rounded,
              title: 'برچسب ایموجی‌ها',
              subtitle: 'نمایش متن توصیفی برای ایموجی‌ها',
              value: a.emojiLabels,
              onChanged: (v) => controller.updateAccessibility(emojiLabels: v),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  controller.setAccessibility(const AccessibilitySettings()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('بازنشانی تنظیمات دسترسی‌پذیری'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextScaleTile extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _TextScaleTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.text_fields_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اندازه متن',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مقیاس متن در کل برنامه (${(value * 100).round()}٪)',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${PersianNumberFormatter.toPersian((value * 100).round().toString())}٪',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'A',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.85,
                  max: 1.5,
                  divisions: 13,
                  label: '${(value * 100).round()}٪',
                  onChanged: onChanged,
                ),
              ),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: scheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

// -------- بخش بکاپ و بازیابی --------
class _BackupSection extends StatelessWidget {
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  const _BackupSection({required this.onBackup, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.backup_rounded,
                    color: scheme.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'بکاپ و بازیابی اطلاعات',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'از کل دیتابیس برنامه شامل کارکنان، وام‌ها، تنظیمات و فیش‌های ثبت‌شده فایل بکاپ بگیرید یا فایل بکاپ قبلی را بازیابی کنید.',
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 560;
                final backupButton = FilledButton.icon(
                  onPressed: onBackup,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('گرفتن بکاپ'),
                );
                final restoreButton = FilledButton.tonalIcon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_page_rounded),
                  label: const Text('ریستور بکاپ'),
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      backupButton,
                      const SizedBox(height: 12),
                      restoreButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: backupButton),
                    const SizedBox(width: 12),
                    Expanded(child: restoreButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------- بخش درباره --------
class _AboutSection extends StatelessWidget {
  final VoidCallback onOpenHelp;

  const _AboutSection({required this.onOpenHelp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: scheme.tertiary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'درباره برنامه',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 12),
            _AboutRow(
              label: 'نام',
              value: 'حقوق و دستمزد فرایند کود و سم بافق',
            ),
            _AboutRow(label: 'نسخه', value: AppConstants.appVersion),
            _AboutRow(label: 'سال مالی', value: '۱۴۰۵'),
            _AboutRow(
              label: 'پلتفرم',
              value: 'Flutter (Windows, Android, Linux)',
            ),
            _AboutRow(label: 'فونت', value: 'Vazirmatn'),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onOpenHelp,
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('مشاهده راهنما'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
