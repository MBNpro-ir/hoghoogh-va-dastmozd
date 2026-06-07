import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../services/salary_calculator.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/seniority_helper.dart';
import '../../widgets/persian_date_picker.dart';
import '../../widgets/persian_number_field.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EmployeeService();
  final _settingsService = SettingsService();

  bool _loading = true;
  bool _saving = false;
  AppSettings? _settings;

  late TextEditingController _personnelCodeCtrl;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _nationalIdCtrl;
  late TextEditingController _startDateCtrl;
  late TextEditingController _notesCtrl;

  bool _isMarried = false;
  bool _hasPriorExperience = true;
  int _childrenCount = 0;

  double _dailyWage1404 = 0;
  double _dailyWage1405 = 0;
  double _baseSalary30Days = 0;
  double _dailyHousing = 1000000;
  double _dailyFood = 733333;
  double _dailyMarriage = 0;
  double _dailyChildAllowance = 554185;
  double _dailySeniority = 0;
  double _lastYearSeniority = 0;
  double _otherBenefitsDaily = 0;
  double _hourlyBenefits = 0;

  double _selectedRate = AppConstants.salaryRateA;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _personnelCodeCtrl = TextEditingController(
      text: e?.personnelCode.toString() ?? '',
    );
    _firstNameCtrl = TextEditingController(text: e?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: e?.lastName ?? '');
    _nationalIdCtrl = TextEditingController(text: e?.nationalId ?? '');
    _startDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(e?.startDate ?? '1405/01/01'),
    );
    _notesCtrl = TextEditingController(text: e?.notes ?? '');

    if (e != null) {
      _isMarried = e.isMarried;
      _hasPriorExperience = e.hasPriorExperience;
      _childrenCount = e.childrenCount;
      _dailyWage1404 = e.dailyWage1404;
      _dailyWage1405 = e.dailyWage1405;
      _baseSalary30Days = e.baseSalary30Days;
      _dailyHousing = e.dailyHousing;
      _dailyFood = e.dailyFood;
      _dailyMarriage = e.dailyMarriage;
      _dailyChildAllowance = e.dailyChildAllowance;
      _dailySeniority = e.dailySeniority;
      _lastYearSeniority = e.lastYearSeniority;
      _otherBenefitsDaily = e.otherBenefitsDaily;
      _hourlyBenefits = e.hourlyBenefits;
    }
    _init();
  }

  Future<void> _init() async {
    _settings = await _settingsService.getCurrentSettings();
    if (widget.employee == null) {
      final nextCode = await _service.getNextPersonnelCode();
      _personnelCodeCtrl.text = nextCode.toString();
      _dailyWage1404 = AppConstants.defaultDailyWage1404;
      _autoCalculate1405();
      _syncExperienceAndSeniorityFromDate(notify: false);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _autoCalculate1405() {
    if (_settings == null) return;
    _dailyWage1405 = SalaryCalculator.calculateDailyWage1405(
      dailyWage1404: _dailyWage1404,
      rate: _selectedRate,
      fixedRial: _settings!.fixedRial,
    );
    _baseSalary30Days = _dailyWage1405 * AppConstants.standardMonthDays;
    _dailyHousing = _settings!.monthlyHousing / AppConstants.standardMonthDays;
    _dailyFood = _settings!.monthlyFood / AppConstants.standardMonthDays;
    _dailyChildAllowance =
        _settings!.monthlyChild / AppConstants.standardMonthDays;

    if (_hasPriorExperience && _dailySeniority == 0) {
      _dailySeniority = _settings!.dailySeniority;
    }

    _dailyMarriage = _isMarried
        ? _settings!.monthlyMarriage / AppConstants.standardMonthDays
        : 0;
    // فقط یکبار setState فراخوانی شود
    if (mounted) setState(() {});
  }

  String get _startDateEnglish =>
      PersianNumberFormatter.toEnglish(_startDateCtrl.text.trim());

  void _syncExperienceAndSeniorityFromDate({bool notify = true}) {
    if (_settings == null) return;
    final hasFourYears = SeniorityHelper.hasAtLeastFourYears(_startDateEnglish);
    _hasPriorExperience = hasFourYears;
    _dailySeniority = hasFourYears
        ? SeniorityHelper.calculateDailySeniority(
            startDate: _startDateEnglish,
            settings: _settings!,
          )
        : 0;
    if (notify && mounted) setState(() {});
  }

  Future<void> _pickStartDate() async {
    final initial =
        SeniorityHelper.parseStartDate(_startDateEnglish) ??
        SeniorityHelper.parseStartDate('1405/01/01');
    final selected = await showPersianDatePicker(
      context: context,
      initialDate: initial,
    );
    if (selected == null) return;
    _startDateCtrl.text = PersianNumberFormatter.toPersian(
      PersianDateHelper.formatJalali(selected),
    );
    _syncExperienceAndSeniorityFromDate();
  }

  Future<void> _setPriorExperienceManually(bool value) async {
    if (_settings == null) return;
    final expected = SeniorityHelper.hasAtLeastFourYears(_startDateEnglish);
    var confirmed = true;
    if (value != expected) {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تغییر دستی سابقه'),
              content: Text(
                expected
                    ? 'این شخص بیش از ۴ سال سابقه دارد. آیا مطمئن هستید که می‌خواهید این بخش را غیر فعال کنید؟'
                    : 'این شخص کمتر از ۴ سال سابقه دارد. آیا مطمئن هستید که می‌خواهید این بخش را فعال کنید؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('تایید'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!confirmed) return;
    setState(() {
      _hasPriorExperience = value;
      _dailySeniority = value
          ? SeniorityHelper.calculateDailySeniority(
              startDate: _startDateEnglish,
              settings: _settings!,
            )
          : 0;
    });
  }

  double _toMonthly(double daily) => daily * AppConstants.standardMonthDays;

  void _setDailyFromMonthly(double monthly, ValueChanged<double> updateDaily) {
    updateDaily(monthly / AppConstants.standardMonthDays);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _personnelCodeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _startDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final code = int.tryParse(
      PersianNumberFormatter.toEnglish(_personnelCodeCtrl.text).trim(),
    );
    if (code == null) {
      _showError('کد پرسنلی نامعتبر است');
      setState(() => _saving = false);
      return;
    }

    final employee = Employee(
      id: widget.employee?.id,
      personnelCode: code,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      nationalId: PersianNumberFormatter.toEnglish(_nationalIdCtrl.text.trim()),
      isMarried: _isMarried,
      hasPriorExperience: _hasPriorExperience,
      childrenCount: _childrenCount,
      lastYearSeniority: _lastYearSeniority,
      baseSalary30Days: _baseSalary30Days,
      dailyWage1404: _dailyWage1404,
      dailyWage1405: _dailyWage1405,
      dailyHousing: _dailyHousing,
      dailyFood: _dailyFood,
      dailyMarriage: _dailyMarriage,
      dailyChildAllowance: _dailyChildAllowance,
      dailySeniority: _dailySeniority,
      otherBenefitsDaily: _otherBenefitsDaily,
      hourlyBenefits: _hourlyBenefits,
      startDate: PersianNumberFormatter.toEnglish(_startDateCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      if (widget.employee == null) {
        await _service.insert(employee);
      } else {
        await _service.update(employee);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError('خطا در ذخیره: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: scheme.error),
    );
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 600;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    final isMobile = _isMobile;
    final padding = isMobile ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employee == null ? 'افزودن کارمند جدید' : 'ویرایش کارمند',
        ),
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: scheme.onPrimary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: Icon(Icons.save_rounded, color: scheme.onSurface),
              label: Text('ذخیره', style: TextStyle(color: scheme.onSurface)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPersonalInfoSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildMaritalSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildSalarySection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildBenefitsSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildMonthlyBenefitsSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildNotesSection(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'مشخصات فردی',
      icon: Icons.badge_rounded,
      accent: Theme.of(context).colorScheme.primary,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              flex: 1,
              child: TextFormField(
                controller: _personnelCodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'کد پرسنلی *',
                  prefixIcon: Icon(Icons.tag_rounded, size: 20),
                ),
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'الزامی است' : null,
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              flex: 2,
              child: TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'نام *',
                  prefixIcon: Icon(Icons.person_rounded, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'الزامی است' : null,
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              flex: 2,
              child: TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'نام خانوادگی *',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'الزامی است' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              flex: 2,
              child: TextFormField(
                controller: _nationalIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'کد ملی *',
                  prefixIcon: Icon(Icons.credit_card_rounded, size: 20),
                  counterText: '',
                ),
                textDirection: TextDirection.ltr,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'الزامی است';
                  final en = PersianNumberFormatter.toEnglish(v.trim());
                  if (en.length != 10) return 'کد ملی باید ۱۰ رقم باشد';
                  return null;
                },
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              flex: 1,
              child: TextFormField(
                controller: _startDateCtrl,
                readOnly: true,
                onTap: _pickStartDate,
                decoration: const InputDecoration(
                  labelText: 'تاریخ شروع *',
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  suffixIcon: Icon(Icons.edit_calendar_rounded, size: 20),
                  hintText: 'مثلا: 1402/01/01',
                ),
                textDirection: TextDirection.ltr,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'الزامی است';
                  final parsed = SeniorityHelper.parseStartDate(
                    PersianNumberFormatter.toEnglish(v),
                  );
                  return parsed == null ? 'تاریخ نامعتبر است' : null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaritalSection(BuildContext context, bool isMobile) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSection(
      context: context,
      title: 'وضعیت تاهل و فرزند',
      icon: Icons.family_restroom_rounded,
      accent: scheme.tertiary,
      children: [
        if (isMobile)
          Column(
            children: [
              SwitchListTile(
                title: const Text('متاهل'),
                value: _isMarried,
                onChanged: (v) {
                  _isMarried = v;
                  _autoCalculate1405();
                },
                secondary: Icon(
                  _isMarried
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: scheme.tertiary,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('بیش از ۴ سال سابقه'),
                value: _hasPriorExperience,
                onChanged: _setPriorExperienceManually,
                secondary: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.warningColor,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 4),
              _buildChildrenCounter(isMobile),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('متاهل'),
                  value: _isMarried,
                  onChanged: (v) {
                    _isMarried = v;
                    _autoCalculate1405();
                  },
                  secondary: Icon(
                    _isMarried
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: scheme.tertiary,
                  ),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  title: const Text('بیش از ۴ سال سابقه'),
                  value: _hasPriorExperience,
                  onChanged: _setPriorExperienceManually,
                  secondary: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
              Expanded(child: _buildChildrenCounter(false)),
            ],
          ),
      ],
    );
  }

  Widget _buildChildrenCounter(bool isMobile) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_rounded, color: scheme.tertiary, size: 20),
            const SizedBox(width: 6),
            const Text('فرزند:', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _childrenCount > 0
                  ? () {
                      _childrenCount--;
                      _autoCalculate1405();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 24),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            SizedBox(
              width: 32,
              child: Text(
                PersianNumberFormatter.toPersian(_childrenCount.toString()),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _childrenCount++;
                _autoCalculate1405();
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalarySection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'محاسبه دستمزد ۱۴۰۵',
      icon: Icons.payments_rounded,
      accent: AppTheme.successColor,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.warningColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'دستمزد روزانه ۱۴۰۵ = دستمزد ۱۴۰۴ × ضریب + ثابت ریالی\n'
                  'ثابت ریالی ${PersianNumberFormatter.formatRial(_settings!.fixedRial)} ریال',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'دستمزد روزانه ۱۴۰۴ *',
                isCurrency: true,
                prefixIcon: Icons.history_rounded,
                initialValue: _dailyWage1404,
                onChanged: (v) {
                  _dailyWage1404 = v?.toDouble() ?? 0;
                  _autoCalculate1405();
                },
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الزامی است' : null,
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'ضریب افزایش ۱۴۰۵',
                  prefixIcon: Icon(Icons.percent_rounded, size: 20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    isExpanded: true,
                    value: _selectedRate,
                    items: [
                      DropdownMenuItem(
                        value: _settings!.salaryRateA,
                        child: Text(
                          '${PersianNumberFormatter.toPersian(_settings!.salaryRateA.toString())} (کارگری)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: _settings!.salaryRateB,
                        child: Text(
                          '${PersianNumberFormatter.toPersian(_settings!.salaryRateB.toString())} (سایر)',
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        _selectedRate = v;
                        _autoCalculate1405();
                      }
                    },
                  ),
                ),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'دستمزد ۱۴۰۵ (خودکار)',
                isCurrency: true,
                prefixIcon: Icons.calculate_rounded,
                initialValue: _dailyWage1405,
                onChanged: (v) {
                  _dailyWage1405 = v?.toDouble() ?? 0;
                  _baseSalary30Days =
                      _dailyWage1405 * AppConstants.standardMonthDays;
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حقوق پایه (۳۰ روز)',
                isCurrency: true,
                prefixIcon: Icons.attach_money_rounded,
                initialValue: _baseSalary30Days,
                onChanged: (v) => _baseSalary30Days = v?.toDouble() ?? 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'مزایای روزانه',
      icon: Icons.card_giftcard_rounded,
      accent: Theme.of(context).colorScheme.secondary,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق مسکن',
                isCurrency: true,
                prefixIcon: Icons.home_rounded,
                initialValue: _dailyHousing,
                onChanged: (v) =>
                    setState(() => _dailyHousing = v?.toDouble() ?? 0),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق خواروبار',
                isCurrency: true,
                prefixIcon: Icons.shopping_basket_rounded,
                initialValue: _dailyFood,
                onChanged: (v) =>
                    setState(() => _dailyFood = v?.toDouble() ?? 0),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق تاهل',
                isCurrency: true,
                prefixIcon: Icons.favorite_rounded,
                initialValue: _dailyMarriage,
                onChanged: (v) =>
                    setState(() => _dailyMarriage = v?.toDouble() ?? 0),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق فرزند (هر فرزند)',
                isCurrency: true,
                prefixIcon: Icons.child_care_rounded,
                initialValue: _dailyChildAllowance,
                onChanged: (v) =>
                    setState(() => _dailyChildAllowance = v?.toDouble() ?? 0),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'پایه سنوات',
                isCurrency: true,
                prefixIcon: Icons.workspace_premium_rounded,
                initialValue: _dailySeniority,
                onChanged: (v) =>
                    setState(() => _dailySeniority = v?.toDouble() ?? 0),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'سنوات سال گذشته',
                isCurrency: true,
                prefixIcon: Icons.history_toggle_off_rounded,
                initialValue: _lastYearSeniority,
                onChanged: (v) =>
                    setState(() => _lastYearSeniority = v?.toDouble() ?? 0),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'سایر مزایا',
                isCurrency: true,
                prefixIcon: Icons.add_box_rounded,
                initialValue: _otherBenefitsDaily,
                onChanged: (v) =>
                    setState(() => _otherBenefitsDaily = v?.toDouble() ?? 0),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'ساعت مزایای ساعتی قرارداد',
                prefixIcon: Icons.access_time_rounded,
                suffix: 'ساعت',
                initialValue: _hourlyBenefits,
                onChanged: (v) =>
                    setState(() => _hourlyBenefits = v?.toDouble() ?? 0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyBenefitsSection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'مزایای ماهانه',
      icon: Icons.calendar_month_rounded,
      accent: Theme.of(context).colorScheme.secondary,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق مسکن ماهانه',
                isCurrency: true,
                prefixIcon: Icons.home_work_rounded,
                initialValue: _toMonthly(_dailyHousing),
                onChanged: (v) => _setDailyFromMonthly(
                  v?.toDouble() ?? 0,
                  (daily) => _dailyHousing = daily,
                ),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق خواروبار ماهانه',
                isCurrency: true,
                prefixIcon: Icons.shopping_cart_rounded,
                initialValue: _toMonthly(_dailyFood),
                onChanged: (v) => _setDailyFromMonthly(
                  v?.toDouble() ?? 0,
                  (daily) => _dailyFood = daily,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق تاهل ماهانه',
                isCurrency: true,
                prefixIcon: Icons.favorite_rounded,
                initialValue: _toMonthly(_dailyMarriage),
                onChanged: (v) => _setDailyFromMonthly(
                  v?.toDouble() ?? 0,
                  (daily) => _dailyMarriage = daily,
                ),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'حق فرزند ماهانه (هر فرزند)',
                isCurrency: true,
                prefixIcon: Icons.child_friendly_rounded,
                initialValue: _toMonthly(_dailyChildAllowance),
                onChanged: (v) => _setDailyFromMonthly(
                  v?.toDouble() ?? 0,
                  (daily) => _dailyChildAllowance = daily,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'پایه سنوات ماهانه',
                isCurrency: true,
                prefixIcon: Icons.workspace_premium_rounded,
                initialValue: _toMonthly(_dailySeniority),
                onChanged: (v) => _setDailyFromMonthly(
                  v?.toDouble() ?? 0,
                  (daily) => _dailySeniority = daily,
                ),
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: PersianNumberField(
                label: 'سایر مزایا ماهانه',
                isCurrency: true,
                prefixIcon: Icons.add_card_rounded,
                initialValue: _toMonthly(_otherBenefitsDaily),
                onChanged: (v) => _setDailyFromMonthly(
                  v?.toDouble() ?? 0,
                  (daily) => _otherBenefitsDaily = daily,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'یادداشت',
      icon: Icons.note_alt_rounded,
      accent: Theme.of(context).colorScheme.onSurfaceVariant,
      children: [
        TextFormField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'یادداشت (اختیاری)',
            hintText: 'مثلاً: کارگر فصلی، انتقالی از واحد...',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('انصراف'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(
              widget.employee == null ? 'افزودن کارمند' : 'ذخیره تغییرات',
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('انصراف'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(
              widget.employee == null ? 'افزودن کارمند' : 'ذخیره تغییرات',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    final isMobile = _isMobile;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: accent, size: isMobile ? 20 : 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: isMobile
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  /// On mobile: stacks children vertically.
  /// On desktop: lays them out in a Row.
  Widget _responsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          children[i],
        ],
      ],
    );
  }

  /// Wraps a child in Expanded on desktop, full-width on mobile.
  Widget _responsiveField({
    required bool isMobile,
    required Widget child,
    int flex = 1,
  }) {
    if (isMobile) return child;
    return Expanded(flex: flex, child: child);
  }
}
