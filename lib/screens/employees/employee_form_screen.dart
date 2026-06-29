import 'package:flutter/material.dart';

import '../../data/employee_reference_data.dart';
import '../../data/job_title_repository.dart';
import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../services/salary_calculator.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/constants.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/seniority_helper.dart';
import '../../widgets/persian_date_picker.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/persian_number_field.dart';
import 'job_code_picker_screen.dart';

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
  final _sync = SyncService();

  bool _loading = true;
  bool _saving = false;
  AppSettings? _settings;
  final Set<String> _collapsedSections = {};

  late final TextEditingController _personnelCodeCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _nationalIdCtrl;
  late final TextEditingController _birthCertificateCtrl;
  late final TextEditingController _birthDateCtrl;
  late final TextEditingController _birthPlaceCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _workplaceCtrl;
  late final TextEditingController _bankAccountNumberCtrl;
  late final TextEditingController _jobCodeCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _cardNumberCtrl;
  late final TextEditingController _insuranceNumberCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _payslipFooterNoteCtrl;
  late final TextEditingController _notesCtrl;

  bool _isActive = true;
  bool _isMarried = false;
  bool _hasPriorExperience = true;
  bool _hardAndHarmfulJob = false;
  bool _hasShiftWork = false;
  int _childrenCount = 0;

  String _gender = EmployeeReferenceData.genders.first;
  String _bankName = '';
  String _bankAccountType = '';
  String _education = '';
  String _employmentType = EmployeeReferenceData.employmentTypes.first;

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
    final today = PersianDateHelper.todayText();
    _personnelCodeCtrl = TextEditingController(
      text: e == null
          ? ''
          : PersianNumberFormatter.toPersian(e.personnelCode.toString()),
    );
    _firstNameCtrl = TextEditingController(text: _visibleText(e?.firstName));
    _lastNameCtrl = TextEditingController(text: _visibleText(e?.lastName));
    _fatherNameCtrl = TextEditingController(text: _visibleText(e?.fatherName));
    _nationalIdCtrl = TextEditingController(text: _visibleText(e?.nationalId));
    _birthCertificateCtrl = TextEditingController(
      text: _visibleText(e?.birthCertificateNumber),
    );
    _birthDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(e?.birthDate ?? ''),
    );
    _birthPlaceCtrl = TextEditingController(text: _visibleText(e?.birthPlace));
    _phoneCtrl = TextEditingController(text: _visibleText(e?.phone));
    _workplaceCtrl = TextEditingController(text: _visibleText(e?.workplace));
    _bankAccountNumberCtrl = TextEditingController(
      text: _visibleText(e?.bankAccountNumber),
    );
    _jobCodeCtrl = TextEditingController(text: _visibleText(e?.jobCode));
    _jobTitleCtrl = TextEditingController(text: _visibleText(e?.jobTitle));
    _startDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(e?.startDate ?? today),
    );
    _endDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(e?.endDate ?? ''),
    );
    _cardNumberCtrl = TextEditingController(text: _visibleText(e?.cardNumber));
    _insuranceNumberCtrl = TextEditingController(
      text: _visibleText(e?.insuranceNumber),
    );
    _positionCtrl = TextEditingController(text: _visibleText(e?.position));
    _addressCtrl = TextEditingController(text: _visibleText(e?.address));
    _payslipFooterNoteCtrl = TextEditingController(
      text: _visibleText(e?.payslipFooterNote),
    );
    _notesCtrl = TextEditingController(text: _visibleText(e?.notes));

    if (e != null) {
      _collapsedSections.addAll(_employeeSectionTitles);
      _isActive = e.isActive;
      _isMarried = e.isMarried;
      _hasPriorExperience = e.hasPriorExperience;
      _hardAndHarmfulJob = e.hardAndHarmfulJob;
      _hasShiftWork = e.hasShiftWork;
      _childrenCount = e.childrenCount;
      _gender = _safeChoice(EmployeeReferenceData.genders, e.gender);
      _bankName = _safeChoice(EmployeeReferenceData.iranianBanks, e.bankName);
      _bankAccountType = _safeChoice(
        EmployeeReferenceData.bankAccountTypes,
        e.bankAccountType,
      );
      _education = _safeChoice(EmployeeReferenceData.educations, e.education);
      _employmentType = _safeChoice(
        EmployeeReferenceData.employmentTypes,
        e.employmentType,
      );
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

  static const _employeeSectionTitles = [
    'وضعیت کاری',
    'اطلاعات هویتی',
    'تماس و محل خدمت',
    'استخدام، بیمه و شغل',
    'اطلاعات بانکی',
    'وضعیت تاهل و فرزند',
    'محاسبه دستمزد ۱۴۰۵',
    'مزایای روزانه',
    'مزایای ماهانه',
    'یادداشت‌ها',
  ];

  String _visibleText(String? value) =>
      PersianNumberFormatter.toPersian(value ?? '');

  Future<void> _init() async {
    if (widget.employee == null) {
      await _sync.pullLatest(silent: true);
    }
    _settings = await _settingsService.getCurrentSettings();
    if (_workplaceCtrl.text.trim().isEmpty) {
      _workplaceCtrl.text = _visibleText(_settings!.companyName);
    }
    if (widget.employee != null) {
      _selectedRate = _inferSalaryRate(widget.employee!, _settings!);
    }
    if (widget.employee == null) {
      final nextCode = await _service.getNextPersonnelCode();
      _personnelCodeCtrl.text = PersianNumberFormatter.toPersian(
        nextCode.toString(),
      );
      _dailyWage1404 = AppConstants.defaultDailyWage1404;
      _autoCalculate1405(notify: false);
      _syncExperienceAndSeniorityFromDate(notify: false);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _safeChoice(List<String> values, String value) {
    if (value.trim().isEmpty) return '';
    return values.contains(value) ? value : '';
  }

  String _formatSalaryRate(double value) {
    final formatted = value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return PersianNumberFormatter.toPersian(formatted);
  }

  double _inferSalaryRate(Employee employee, AppSettings settings) {
    if (employee.dailyWage1404 <= 0) return settings.salaryRateA;
    final inferred =
        (employee.dailyWage1405 - settings.fixedRial) / employee.dailyWage1404;
    final distanceA = (inferred - settings.salaryRateA).abs();
    final distanceB = (inferred - settings.salaryRateB).abs();
    return distanceA <= distanceB ? settings.salaryRateA : settings.salaryRateB;
  }

  List<DropdownMenuItem<double>> _salaryRateItems() {
    final settings = _settings;
    if (settings == null) return const [];

    final entries = <double, List<String>>{};
    entries.putIfAbsent(settings.salaryRateA, () => []).add('کارگری');
    entries.putIfAbsent(settings.salaryRateB, () => []).add('سایر');

    return entries.entries
        .map(
          (entry) => DropdownMenuItem<double>(
            value: entry.key,
            child: Text(
              '${_formatSalaryRate(entry.key)} (${entry.value.join(' / ')})',
            ),
          ),
        )
        .toList();
  }

  String get _startDateEnglish =>
      PersianNumberFormatter.toEnglish(_startDateCtrl.text.trim());

  void _autoCalculate1405({bool notify = true}) {
    if (_settings == null) return;
    _dailyWage1405 = _defaultDailyWage1405;
    _baseSalary30Days = _defaultBaseSalary30Days;
    _dailyHousing = _defaultDailyHousing;
    _dailyFood = _defaultDailyFood;
    _dailyChildAllowance = _defaultDailyChildAllowance;
    _dailySeniority = _defaultDailySeniority;
    _dailyMarriage = _defaultDailyMarriage;
    if (notify && mounted) setState(() {});
  }

  void _syncExperienceAndSeniorityFromDate({bool notify = true}) {
    if (_settings == null) return;
    final eligible = _isEligibleForPriorExperience();
    _hasPriorExperience = eligible;
    _dailySeniority = eligible
        ? SeniorityHelper.calculateDailySeniority(
            startDate: _startDateEnglish,
            settings: _settings!,
          )
        : 0;
    if (notify && mounted) setState(() {});
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    bool syncStartDate = false,
  }) async {
    final current = PersianNumberFormatter.toEnglish(controller.text.trim());
    final initial =
        SeniorityHelper.parseStartDate(current) ?? PersianDateHelper.today();
    final selected = await showPersianDatePicker(
      context: context,
      initialDate: initial,
    );
    if (selected == null) return;
    controller.text = PersianNumberFormatter.toPersian(
      PersianDateHelper.formatJalali(selected),
    );
    if (syncStartDate) _syncExperienceAndSeniorityFromDate();
  }

  Future<void> _pickJobTitle() async {
    final selected = await Navigator.push<JobTitleEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => JobCodePickerScreen(
          initialCode: _jobCodeCtrl.text,
          initialTitle: _jobTitleCtrl.text,
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _jobCodeCtrl.text = _visibleText(selected.code);
      _jobTitleCtrl.text = _visibleText(selected.title);
      if (_positionCtrl.text.trim().isEmpty) {
        _positionCtrl.text = _visibleText(selected.title);
      }
    });
  }

  Future<void> _setPriorExperienceManually(bool value) async {
    if (_settings == null) return;
    final expected = _isEligibleForPriorExperience();
    if (value && !expected) {
      _showError(
        'برای فعال کردن «دارای سابقه»، تاریخ شروع باید تا پایان سال مالی حداقل یک سال سابقه داشته باشد.',
      );
      return;
    }
    var confirmed = true;
    if (!value && expected) {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تغییر دستی سابقه'),
              content: const Text(
                'این شخص تا پایان سال مالی حداقل یک سال سابقه دارد. آیا مطمئن هستید که می‌خواهید این بخش را غیر فعال کنید؟',
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

  bool _isEligibleForPriorExperience() {
    final settings = _settings;
    if (settings == null) return false;
    return SeniorityHelper.isEligibleForPriorExperience(
      startDate: _startDateEnglish,
      settings: settings,
    );
  }

  double _toMonthly(double daily) => daily * AppConstants.standardMonthDays;

  void _setDailyFromMonthly(double monthly, ValueChanged<double> updateDaily) {
    updateDaily(monthly / AppConstants.standardMonthDays);
    if (mounted) setState(() {});
  }

  double get _defaultDailyWage1405 {
    if (_settings == null) return 0;
    return SalaryCalculator.calculateDailyWage1405(
      dailyWage1404: _dailyWage1404,
      rate: _selectedRate,
      fixedRial: _settings!.fixedRial,
    );
  }

  double get _defaultBaseSalary30Days =>
      _defaultDailyWage1405 * AppConstants.standardMonthDays;

  double get _defaultDailyHousing =>
      (_settings?.monthlyHousing ?? 0) / AppConstants.standardMonthDays;

  double get _defaultDailyFood =>
      (_settings?.monthlyFood ?? 0) / AppConstants.standardMonthDays;

  double get _defaultDailyMarriage => _isMarried
      ? (_settings?.monthlyMarriage ?? 0) / AppConstants.standardMonthDays
      : 0;

  double get _defaultDailyChildAllowance => _childrenCount > 0
      ? (_settings?.monthlyChild ?? 0) / AppConstants.standardMonthDays
      : 0;

  double get _defaultDailySeniority => _hasPriorExperience && _settings != null
      ? SeniorityHelper.calculateDailySeniority(
          startDate: _startDateEnglish,
          settings: _settings!,
        )
      : 0;

  bool _differsFromDefault(double value, double defaultValue) =>
      (value - defaultValue).abs() >= 1;

  Widget _withDefaultReset({
    required Widget child,
    required double value,
    required double defaultValue,
    required VoidCallback onReset,
  }) {
    if (!_differsFromDefault(value, defaultValue)) return child;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton.filledTonal(
            tooltip: 'بازگشت به مقدار پیش‌فرض',
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _personnelCodeCtrl,
      _firstNameCtrl,
      _lastNameCtrl,
      _fatherNameCtrl,
      _nationalIdCtrl,
      _birthCertificateCtrl,
      _birthDateCtrl,
      _birthPlaceCtrl,
      _phoneCtrl,
      _workplaceCtrl,
      _bankAccountNumberCtrl,
      _jobCodeCtrl,
      _jobTitleCtrl,
      _startDateCtrl,
      _endDateCtrl,
      _cardNumberCtrl,
      _insuranceNumberCtrl,
      _positionCtrl,
      _addressCtrl,
      _payslipFooterNoteCtrl,
      _notesCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final code = int.tryParse(
      PersianNumberFormatter.toEnglish(_personnelCodeCtrl.text).trim(),
    );
    if (code == null) {
      _showError('شماره پرسنلی نامعتبر است');
      return;
    }
    if (!_isActive && _endDateCtrl.text.trim().isEmpty) {
      _showError('برای کارمند غیرفعال، تاریخ ترک کار را وارد کنید');
      return;
    }
    if (_hasPriorExperience && !_isEligibleForPriorExperience()) {
      _showError(
        'برای فعال بودن «دارای سابقه»، تاریخ شروع باید تا پایان سال مالی حداقل یک سال سابقه داشته باشد.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = await _service.getByPersonnelCode(code);
      if (existing != null && existing.id != widget.employee?.id) {
        _showError('شماره پرسنلی باید یکتا باشد');
        return;
      }
      final nationalId = PersianNumberFormatter.toEnglish(
        _nationalIdCtrl.text.trim(),
      );
      final existingNationalId = await _service.getByNationalId(nationalId);
      if (existingNationalId != null &&
          existingNationalId.id != widget.employee?.id) {
        _showError('این کد ملی قبلاً برای کارمند دیگری ثبت شده است');
        return;
      }

      final employee = Employee(
        id: widget.employee?.id,
        personnelCode: code,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        nationalId: nationalId,
        fatherName: _fatherNameCtrl.text.trim(),
        birthCertificateNumber: PersianNumberFormatter.toEnglish(
          _birthCertificateCtrl.text.trim(),
        ),
        gender: _gender.isEmpty ? EmployeeReferenceData.genders.first : _gender,
        workplace: _workplaceCtrl.text.trim(),
        bankName: _bankName,
        bankAccountType: _bankAccountType,
        bankAccountNumber: PersianNumberFormatter.toEnglish(
          _bankAccountNumberCtrl.text.trim(),
        ),
        jobCode: PersianNumberFormatter.toEnglish(_jobCodeCtrl.text.trim()),
        jobTitle: _jobTitleCtrl.text.trim(),
        birthDate: PersianNumberFormatter.toEnglish(_birthDateCtrl.text.trim()),
        birthPlace: _birthPlaceCtrl.text.trim(),
        phone: PersianNumberFormatter.toEnglish(_phoneCtrl.text.trim()),
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
        hasShiftWork: _hasShiftWork,
        startDate: PersianNumberFormatter.toEnglish(_startDateCtrl.text.trim()),
        isActive: _isActive,
        endDate: PersianNumberFormatter.toEnglish(_endDateCtrl.text.trim()),
        cardNumber: PersianNumberFormatter.toEnglish(
          _cardNumberCtrl.text.trim(),
        ),
        insuranceNumber: PersianNumberFormatter.toEnglish(
          _insuranceNumberCtrl.text.trim(),
        ),
        education: _education,
        position: _positionCtrl.text.trim(),
        employmentType: _employmentType.isEmpty
            ? EmployeeReferenceData.employmentTypes.first
            : _employmentType,
        address: _addressCtrl.text.trim(),
        hardAndHarmfulJob: _hardAndHarmfulJob,
        payslipFooterNote: _payslipFooterNoteCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (widget.employee == null) {
        await _service.insert(employee);
      } else {
        await _service.update(employee);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(
        AppErrorMessage.from(
          e,
          fallback: 'ذخیره کارمند انجام نشد. اطلاعات را بررسی کنید.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    AppNotification.error(context, message);
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
                  _buildEmploymentStatusSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildIdentitySection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildContactSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildJobSection(context, isMobile),
                  const SizedBox(height: 16),
                  _buildBankSection(context, isMobile),
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

  Widget _buildEmploymentStatusSection(BuildContext context, bool isMobile) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSection(
      context: context,
      title: 'وضعیت کاری',
      icon: Icons.verified_user_rounded,
      accent: _isActive ? AppTheme.successColor : scheme.error,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _isActive ? 'مشغول به کار می باشد' : 'مشغول به کار نمی باشد',
          ),
          subtitle: Text(
            _isActive
                ? 'این کارمند در محاسبه حقوق و وام‌ها قابل انتخاب است.'
                : 'برای این کارمند امکان ثبت فیش حقوق جدید وجود ندارد.',
          ),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          secondary: Icon(
            _isActive ? Icons.work_rounded : Icons.work_off_rounded,
            color: _isActive ? AppTheme.successColor : scheme.error,
          ),
        ),
        if (!_isActive) ...[
          const SizedBox(height: 12),
          _responsiveRow(
            isMobile: isMobile,
            children: [
              _dateField(
                controller: _endDateCtrl,
                label: 'تاریخ ترک کار *',
                icon: Icons.event_busy_rounded,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIdentitySection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'اطلاعات هویتی',
      icon: Icons.badge_rounded,
      accent: Theme.of(context).colorScheme.primary,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _responsiveField(
              isMobile: isMobile,
              child: _textField(
                controller: _personnelCodeCtrl,
                label: 'شماره پرسنلی *',
                icon: Icons.tag_rounded,
                ltr: true,
                validator: _requiredValidator,
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              flex: 2,
              child: _textField(
                controller: _firstNameCtrl,
                label: 'نام *',
                icon: Icons.person_rounded,
                validator: _requiredValidator,
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              flex: 2,
              child: _textField(
                controller: _lastNameCtrl,
                label: 'نام خانوادگی *',
                icon: Icons.person_outline_rounded,
                validator: _requiredValidator,
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
              child: _textField(
                controller: _fatherNameCtrl,
                label: 'نام پدر',
                icon: Icons.family_restroom_rounded,
              ),
            ),
            _responsiveField(
              isMobile: isMobile,
              child: _textField(
                controller: _nationalIdCtrl,
                label: 'کد ملی *',
                icon: Icons.credit_card_rounded,
                ltr: true,
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
              child: _textField(
                controller: _birthCertificateCtrl,
                label: 'شماره شناسنامه',
                icon: Icons.assignment_ind_rounded,
                ltr: true,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _dateField(
              controller: _birthDateCtrl,
              label: 'تاریخ تولد',
              icon: Icons.cake_rounded,
            ),
            _dropdown(
              label: 'جنس',
              icon: Icons.wc_rounded,
              value: _gender,
              items: EmployeeReferenceData.genders,
              onChanged: (value) => setState(() => _gender = value ?? ''),
            ),
            _textField(
              controller: _birthPlaceCtrl,
              label: 'محل تولد',
              icon: Icons.location_city_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'تماس و محل خدمت',
      icon: Icons.contact_phone_rounded,
      accent: Theme.of(context).colorScheme.secondary,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _textField(
              controller: _phoneCtrl,
              label: 'تلفن تماس',
              icon: Icons.phone_rounded,
              ltr: true,
            ),
            _textField(
              controller: _workplaceCtrl,
              label: 'محل خدمت',
              icon: Icons.business_rounded,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _textField(
          controller: _addressCtrl,
          label: 'نشانی',
          icon: Icons.location_on_rounded,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildJobSection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'استخدام، بیمه و شغل',
      icon: Icons.work_history_rounded,
      accent: AppTheme.warningColor,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _dateField(
              controller: _startDateCtrl,
              label: 'تاریخ شروع به کار *',
              icon: Icons.event_available_rounded,
              syncStartDate: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الزامی است';
                final parsed = SeniorityHelper.parseStartDate(
                  PersianNumberFormatter.toEnglish(v),
                );
                return parsed == null ? 'تاریخ نامعتبر است' : null;
              },
            ),
            _dropdown(
              label: 'نوع استخدام',
              icon: Icons.assignment_turned_in_rounded,
              value: _employmentType,
              items: EmployeeReferenceData.employmentTypes,
              onChanged: (value) =>
                  setState(() => _employmentType = value ?? ''),
            ),
            _dropdown(
              label: 'تحصیلات',
              icon: Icons.school_rounded,
              value: _education,
              items: EmployeeReferenceData.educations,
              onChanged: (value) => setState(() => _education = value ?? ''),
              optional: true,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _textField(
              controller: _positionCtrl,
              label: 'سمت/شغل',
              icon: Icons.engineering_rounded,
            ),
            _textField(
              controller: _insuranceNumberCtrl,
              label: 'شماره بیمه',
              icon: Icons.health_and_safety_rounded,
              ltr: true,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        OutlinedButton.icon(
          onPressed: _pickJobTitle,
          icon: const Icon(Icons.manage_search_rounded),
          label: Text(
            _jobTitleCtrl.text.trim().isEmpty
                ? 'انتخاب کد شغل بیمه'
                : '${_jobTitleCtrl.text} - ${PersianNumberFormatter.toPersian(_jobCodeCtrl.text)}',
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('شاغل در مشاغل سخت و زیان آور'),
          value: _hardAndHarmfulJob,
          onChanged: (value) => setState(() => _hardAndHarmfulJob = value),
          secondary: const Icon(Icons.warning_amber_rounded),
        ),
      ],
    );
  }

  Widget _buildBankSection(BuildContext context, bool isMobile) {
    return _buildSection(
      context: context,
      title: 'اطلاعات بانکی',
      icon: Icons.account_balance_rounded,
      accent: Theme.of(context).colorScheme.tertiary,
      children: [
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _dropdown(
              label: 'نام بانک',
              icon: Icons.account_balance_rounded,
              value: _bankName,
              items: EmployeeReferenceData.iranianBanks,
              onChanged: (value) => setState(() => _bankName = value ?? ''),
              optional: true,
            ),
            _dropdown(
              label: 'نوع حساب',
              icon: Icons.savings_rounded,
              value: _bankAccountType,
              items: EmployeeReferenceData.bankAccountTypes,
              onChanged: (value) =>
                  setState(() => _bankAccountType = value ?? ''),
              optional: true,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _textField(
              controller: _bankAccountNumberCtrl,
              label: 'شماره حساب',
              icon: Icons.numbers_rounded,
              ltr: true,
            ),
            _textField(
              controller: _cardNumberCtrl,
              label: 'شماره کارت',
              icon: Icons.credit_card_rounded,
              ltr: true,
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
                onChanged: (value) {
                  _isMarried = value;
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
                title: const Text('دارای سابقه (حداقل ۱ سال)'),
                value: _hasPriorExperience,
                onChanged: _setPriorExperienceManually,
                secondary: const Icon(Icons.workspace_premium_rounded),
                contentPadding: EdgeInsets.zero,
              ),
              _buildChildrenCounter(true),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('متاهل'),
                  value: _isMarried,
                  onChanged: (value) {
                    _isMarried = value;
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
                  title: const Text('دارای سابقه (حداقل ۱ سال)'),
                  value: _hasPriorExperience,
                  onChanged: _setPriorExperienceManually,
                  secondary: const Icon(Icons.workspace_premium_rounded),
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
      child: Wrap(
        alignment: isMobile ? WrapAlignment.start : WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: isMobile ? 2 : 6,
        runSpacing: 4,
        children: [
          Icon(Icons.child_care_rounded, color: scheme.tertiary, size: 20),
          const Text('فرزند:', style: TextStyle(fontSize: 14)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _childrenCount > 0
                ? () {
                    _childrenCount--;
                    _autoCalculate1405();
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 28,
            child: Text(
              PersianNumberFormatter.toPersian(_childrenCount.toString()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _childrenCount++;
              _autoCalculate1405();
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySection(BuildContext context, bool isMobile) {
    final salaryRateItems = _salaryRateItems();
    final selectedRate =
        salaryRateItems.any((item) => item.value == _selectedRate)
        ? _selectedRate
        : salaryRateItems.firstOrNull?.value;

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
          child: Text(
            'دستمزد ۱۴۰۵ = دستمزد ۱۴۰۴ × ضریب + ثابت ریالی',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            PersianNumberField(
              label: 'دستمزد روزانه ۱۴۰۴ *',
              isCurrency: true,
              prefixIcon: Icons.history_rounded,
              initialValue: _dailyWage1404,
              onChanged: (value) {
                _dailyWage1404 = value?.toDouble() ?? 0;
                _autoCalculate1405();
              },
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الزامی است' : null,
            ),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'ضریب افزایش ۱۴۰۵',
                prefixIcon: Icon(Icons.percent_rounded, size: 20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  isExpanded: true,
                  value: selectedRate,
                  items: salaryRateItems,
                  onChanged: (value) {
                    if (value == null) return;
                    _selectedRate = value;
                    _autoCalculate1405();
                  },
                ),
              ),
            ),
            _withDefaultReset(
              value: _dailyWage1405,
              defaultValue: _defaultDailyWage1405,
              onReset: () => setState(() {
                _dailyWage1405 = _defaultDailyWage1405;
                _baseSalary30Days = _defaultBaseSalary30Days;
              }),
              child: PersianNumberField(
                label: 'دستمزد ۱۴۰۵',
                isCurrency: true,
                prefixIcon: Icons.calculate_rounded,
                initialValue: _dailyWage1405,
                onChanged: (value) {
                  _dailyWage1405 = value?.toDouble() ?? 0;
                  _baseSalary30Days =
                      _dailyWage1405 * AppConstants.standardMonthDays;
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _withDefaultReset(
          value: _baseSalary30Days,
          defaultValue: _defaultBaseSalary30Days,
          onReset: () =>
              setState(() => _baseSalary30Days = _defaultBaseSalary30Days),
          child: PersianNumberField(
            label: 'حقوق پایه (۳۰ روز)',
            isCurrency: true,
            prefixIcon: Icons.attach_money_rounded,
            initialValue: _baseSalary30Days,
            onChanged: (value) => _baseSalary30Days = value?.toDouble() ?? 0,
          ),
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
            _moneyField(
              'حق مسکن روزانه',
              Icons.home_rounded,
              _dailyHousing,
              (v) => setState(() => _dailyHousing = v),
              defaultValue: _defaultDailyHousing,
              onReset: () =>
                  setState(() => _dailyHousing = _defaultDailyHousing),
            ),
            _moneyField(
              'حق خواروبار روزانه',
              Icons.shopping_basket_rounded,
              _dailyFood,
              (v) => setState(() => _dailyFood = v),
              defaultValue: _defaultDailyFood,
              onReset: () => setState(() => _dailyFood = _defaultDailyFood),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _moneyField(
              'حق تاهل روزانه',
              Icons.favorite_rounded,
              _dailyMarriage,
              (v) => setState(() => _dailyMarriage = v),
              defaultValue: _defaultDailyMarriage,
              onReset: () =>
                  setState(() => _dailyMarriage = _defaultDailyMarriage),
            ),
            _moneyField(
              'حق هر فرزند روزانه',
              Icons.child_care_rounded,
              _dailyChildAllowance,
              (v) => setState(() => _dailyChildAllowance = v),
              defaultValue: _defaultDailyChildAllowance,
              onReset: () => setState(
                () => _dailyChildAllowance = _defaultDailyChildAllowance,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _moneyField(
              'پایه سنوات روزانه',
              Icons.workspace_premium_rounded,
              _dailySeniority,
              (v) => setState(() => _dailySeniority = v),
              defaultValue: _defaultDailySeniority,
              onReset: () =>
                  setState(() => _dailySeniority = _defaultDailySeniority),
            ),
            _moneyField(
              'سنوات سال گذشته روزانه',
              Icons.history_toggle_off_rounded,
              _lastYearSeniority,
              (v) => setState(() => _lastYearSeniority = v),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _moneyField(
              'سایر مزایا روزانه',
              Icons.add_box_rounded,
              _otherBenefitsDaily,
              (v) => setState(() => _otherBenefitsDaily = v),
            ),
            PersianNumberField(
              label: 'ساعت مزایای ساعتی قرارداد',
              prefixIcon: Icons.access_time_rounded,
              suffix: 'ساعت',
              initialValue: _hourlyBenefits,
              onChanged: (value) =>
                  setState(() => _hourlyBenefits = value?.toDouble() ?? 0),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('نوبت‌کاری'),
          subtitle: const Text(
            'در ساخت فیش، نوبت‌کاری این کارمند به‌صورت پیش‌فرض فعال می‌شود',
          ),
          value: _hasShiftWork,
          onChanged: (value) => setState(() => _hasShiftWork = value),
          secondary: const Icon(Icons.schedule_rounded),
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
            _moneyField(
              'حق مسکن ماهانه',
              Icons.home_work_rounded,
              _toMonthly(_dailyHousing),
              (v) => _setDailyFromMonthly(v, (d) => _dailyHousing = d),
              defaultValue: _toMonthly(_defaultDailyHousing),
              onReset: () =>
                  setState(() => _dailyHousing = _defaultDailyHousing),
            ),
            _moneyField(
              'حق خواروبار ماهانه',
              Icons.shopping_cart_rounded,
              _toMonthly(_dailyFood),
              (v) => _setDailyFromMonthly(v, (d) => _dailyFood = d),
              defaultValue: _toMonthly(_defaultDailyFood),
              onReset: () => setState(() => _dailyFood = _defaultDailyFood),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _moneyField(
              'حق تاهل ماهانه',
              Icons.favorite_rounded,
              _toMonthly(_dailyMarriage),
              (v) => _setDailyFromMonthly(v, (d) => _dailyMarriage = d),
              defaultValue: _toMonthly(_defaultDailyMarriage),
              onReset: () =>
                  setState(() => _dailyMarriage = _defaultDailyMarriage),
            ),
            _moneyField(
              'حق هر فرزند ماهانه',
              Icons.child_friendly_rounded,
              _toMonthly(_dailyChildAllowance),
              (v) => _setDailyFromMonthly(v, (d) => _dailyChildAllowance = d),
              defaultValue: _toMonthly(_defaultDailyChildAllowance),
              onReset: () => setState(
                () => _dailyChildAllowance = _defaultDailyChildAllowance,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _responsiveRow(
          isMobile: isMobile,
          children: [
            _moneyField(
              'پایه سنوات ماهانه',
              Icons.workspace_premium_rounded,
              _toMonthly(_dailySeniority),
              (v) => _setDailyFromMonthly(v, (d) => _dailySeniority = d),
              defaultValue: _toMonthly(_defaultDailySeniority),
              onReset: () =>
                  setState(() => _dailySeniority = _defaultDailySeniority),
            ),
            _moneyField(
              'سایر مزایا ماهانه',
              Icons.add_card_rounded,
              _toMonthly(_otherBenefitsDaily),
              (v) => _setDailyFromMonthly(v, (d) => _otherBenefitsDaily = d),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'یادداشت‌ها',
      icon: Icons.note_alt_rounded,
      accent: Theme.of(context).colorScheme.onSurfaceVariant,
      children: [
        _textField(
          controller: _payslipFooterNoteCtrl,
          label: 'توضیحات انتهای فیش',
          icon: Icons.receipt_long_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _notesCtrl,
          label: 'یادداشت داخلی',
          icon: Icons.sticky_note_2_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    final saveButton = FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_rounded),
      label: Text(widget.employee == null ? 'افزودن کارمند' : 'ذخیره تغییرات'),
    );
    final cancelButton = OutlinedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close_rounded),
      label: const Text('انصراف'),
    );
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [cancelButton, const SizedBox(height: 12), saveButton],
      );
    }
    return Row(
      children: [
        Expanded(child: cancelButton),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: saveButton),
      ],
    );
  }

  Widget _moneyField(
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged, {
    double? defaultValue,
    VoidCallback? onReset,
  }) {
    final field = PersianNumberField(
      label: label,
      isCurrency: true,
      prefixIcon: icon,
      initialValue: value,
      onChanged: (value) => onChanged(value?.toDouble() ?? 0),
    );
    if (defaultValue == null || onReset == null) return field;
    return _withDefaultReset(
      value: value,
      defaultValue: defaultValue,
      onReset: onReset,
      child: field,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool ltr = false,
    int maxLines = 1,
    int? maxLength,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: const [PersianDigitsInputFormatter()],
      textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
      ),
      validator: validator,
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool syncStartDate = false,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: false,
      onTap: () => _pickDate(controller, syncStartDate: syncStartDate),
      keyboardType: TextInputType.datetime,
      enableInteractiveSelection: true,
      inputFormatters: const [PersianDateInputFormatter()],
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: const Icon(Icons.edit_calendar_rounded, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool optional = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: [
        if (optional)
          const DropdownMenuItem(value: '', child: Text('انتخاب نشده')),
        ...items.map(
          (item) => DropdownMenuItem(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'الزامی است' : null;

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    final isMobile = _isMobile;
    final collapsed = _collapsedSections.contains(title);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              onTap: () {
                setState(() {
                  if (collapsed) {
                    _collapsedSections.remove(title);
                  } else {
                    _collapsedSections.add(title);
                  }
                });
              },
              child: Row(
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
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                  ),
                ],
              ),
            ),
            if (!collapsed) ...[const Divider(height: 24), ...children],
          ],
        ),
      ),
    );
  }

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
          children[i] is Expanded ? children[i] : Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _responsiveField({
    required bool isMobile,
    required Widget child,
    int flex = 1,
  }) {
    if (isMobile) return child;
    return Expanded(flex: flex, child: child);
  }
}
