import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/advance_payment.dart';
import '../../models/employee.dart';
import '../../models/employee_leave.dart';
import '../../models/loan.dart';
import '../../models/salary_draft.dart';
import '../../models/salary_record.dart';
import '../../services/advance_service.dart';
import '../../services/employee_service.dart';
import '../../services/employee_leave_service.dart';
import '../../services/loan_service.dart';
import '../../services/salary_calculator.dart';
import '../../services/salary_draft_service.dart';
import '../../services/salary_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/app_error_message.dart';
import '../../utils/responsive.dart';
import '../../utils/gradient_helpers.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/floating_nav_safe_area.dart';
import '../../widgets/mouse_wheel_picker.dart';
import '../../widgets/persian_number_field.dart';
import 'payslip_screen.dart';

enum _ExistingRecordAction { replace, showExisting }

class SalaryCalculationScreen extends StatefulWidget {
  final Employee? initialEmployee;
  final SalaryRecord? editRecord;
  final bool embedded;

  const SalaryCalculationScreen({
    super.key,
    this.initialEmployee,
    this.editRecord,
    this.embedded = false,
  });

  @override
  State<SalaryCalculationScreen> createState() =>
      _SalaryCalculationScreenState();
}

class _SalaryCalculationScreenState extends State<SalaryCalculationScreen> {
  final _employeeService = EmployeeService();
  final _leaveService = EmployeeLeaveService();
  final _loanService = LoanService();
  final _advanceService = AdvanceService();
  final _salaryService = SalaryService();
  final _salaryDraftService = SalaryDraftService();
  final _settingsService = SettingsService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  AppSettings? _settings;
  List<EmployeeLeave> _employeeLeaves = [];
  List<Loan> _employeeLoans = [];
  List<AdvancePayment> _employeeAdvances = [];

  bool _loading = true;
  bool _saving = false;

  late int _year;
  late int _month;
  late int _totalDays;
  double _leaveDays = 0;
  double _sickLeaveDays = 0;

  double _overtimeHours = 0;
  bool _useCustomOvertimeBase = false;
  double _overtimeBaseDaily = 0;
  double _shiftWork = 0;
  double _hourlyBenefitsAmount = 0;
  double _hourlyBenefitHours = 0;
  double _otherBenefitsOverride = -1;
  double _loanInstallment = 0;
  double _advance = 0;
  double _otherDeductions = 0;

  bool _useAutoLoanInstallment = true;
  bool _skipLoanInstallmentThisMonth = false;
  bool _useAutoAdvances = true;
  bool _useAutoOtherBenefits = true;
  bool _useAutoShiftWork = false;
  bool _useAutoHourlyBenefits = true;
  bool _includeLeaveInPayslip = true;
  bool _insuranceExempt = false;
  bool _taxExempt = false;
  bool _housingExempt = false;
  bool _foodExempt = false;
  bool _seniorityExempt = false;
  bool _restoringInputs = false;
  int _restoreGeneration = 0;
  Timer? _draftSaveTimer;

  SalaryCalculationResult? _result;
  SalaryRecord? get _editRecord => widget.editRecord;
  bool get _isEditMode => _editRecord != null;

  @override
  void initState() {
    super.initState();
    final today = PersianDateHelper.today();
    _year = today.year;
    _month = today.month;
    _totalDays = PersianDateHelper.daysInMonth(_year, _month);
    _init();
  }

  Future<void> _init() async {
    _employees = await _employeeService.getAll(onlyActive: !_isEditMode);
    _settings = await _settingsService.getCurrentSettings(year: _year);
    if (_editRecord != null) {
      _year = _editRecord!.year;
      _month = _editRecord!.month;
      for (final employee in _employees) {
        if (employee.id == _editRecord!.employeeId) {
          _selectedEmployee = employee;
          break;
        }
      }
      if (_selectedEmployee != null && _selectedEmployee!.id != null) {
        await _loadEmployeeDeductions(_selectedEmployee!.id!);
      }
      _applyRecordToInputs(_editRecord!, notify: false);
    } else if (widget.initialEmployee != null) {
      _selectedEmployee = _employees.cast<Employee?>().firstWhere(
        (employee) => employee?.id == widget.initialEmployee!.id,
        orElse: () => null,
      );
      if (_selectedEmployee!.id != null) {
        await _loadEmployeeDeductions(_selectedEmployee!.id!);
      }
      await _checkExistingRecord(notify: false);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _calculate(saveDraft: false);
  }

  Future<void> _onEmployeeChanged(Employee? emp) async {
    setState(() => _selectedEmployee = emp);
    if (emp != null && emp.id != null) {
      await _loadEmployeeDeductions(emp.id!);
      if (_skipLoanInstallmentThisMonth) {
        _loanInstallment = 0;
      } else if (_useAutoLoanInstallment) {
        _loanInstallment = _activeLoanInstallmentTotal;
      }
      if (_useAutoAdvances) {
        _advance = _activeAdvanceTotal;
      }
      await _checkExistingRecord();
    }
    _calculate(saveDraft: false);
  }

  Future<void> _onMonthChanged(int month) async {
    setState(() {
      _month = month;
      _totalDays = PersianDateHelper.daysInMonth(_year, month);
    });
    if (_selectedEmployee?.id != null) {
      await _loadEmployeeDeductions(_selectedEmployee!.id!);
    }
    await _checkExistingRecord();
    _calculate(saveDraft: false);
  }

  Future<void> _onYearChanged(int year) async {
    setState(() {
      _year = year;
      _totalDays = PersianDateHelper.daysInMonth(year, _month);
    });
    _settings = await _settingsService.getCurrentSettings(year: year);
    if (_selectedEmployee?.id != null) {
      await _loadEmployeeDeductions(_selectedEmployee!.id!);
    }
    await _checkExistingRecord();
    _calculate(saveDraft: false);
  }

  Future<void> _loadEmployeeDeductions(int employeeId) async {
    _employeeLoans = await _loanService.getActiveLoansForEmployee(employeeId);
    _employeeAdvances = await _advanceService.getByEmployeeYearMonth(
      employeeId,
      _year,
      _month,
    );
    _employeeLeaves = await _leaveService.getApprovedByEmployeeYearMonth(
      employeeId,
      _year,
      _month,
    );
  }

  Future<void> _checkExistingRecord({bool notify = true}) async {
    final employeeId = _selectedEmployee?.id;
    if (employeeId == null) return;
    final targetYear = _year;
    final targetMonth = _month;
    final generation = ++_restoreGeneration;
    bool isStale() =>
        generation != _restoreGeneration ||
        _selectedEmployee?.id != employeeId ||
        _year != targetYear ||
        _month != targetMonth;
    _draftSaveTimer?.cancel();
    _restoringInputs = true;
    try {
      final existing = await _salaryService.getByEmployeeYearMonth(
        employeeId,
        targetYear,
        targetMonth,
      );
      if (isStale()) return;
      if (_isEditMode && existing != null) {
        _applyRecordToInputs(existing, notify: notify);
        return;
      }

      final exactDraft = await _salaryDraftService.getForPeriod(
        employeeId,
        targetYear,
        targetMonth,
      );
      if (isStale()) return;
      if (exactDraft != null) {
        _applyDraftToInputs(exactDraft, notify: notify);
        return;
      }

      if (existing != null) {
        _applyRecordToInputs(existing, notify: notify);
        return;
      }

      final previousDraft = await _salaryDraftService.getLatestBefore(
        employeeId,
        targetYear,
        targetMonth,
      );
      if (isStale()) return;
      final previousRecord = await _salaryService.getLatestBefore(
        employeeId,
        targetYear,
        targetMonth,
      );
      if (isStale()) return;
      final draftPeriod = previousDraft == null
          ? -1
          : previousDraft.year * 100 + previousDraft.month;
      final recordPeriod = previousRecord == null
          ? -1
          : previousRecord.year * 100 + previousRecord.month;
      if (previousDraft != null && draftPeriod >= recordPeriod) {
        _applyDraftToInputs(previousDraft, notify: notify);
        _applyMonthlyLeaveRecordsToInputs(notify: notify);
        return;
      }
      if (previousRecord != null) {
        _applyRecordToInputs(previousRecord, notify: notify);
        _applyMonthlyLeaveRecordsToInputs(notify: notify);
        return;
      }
      _resetInputs(notify: notify);
    } finally {
      if (generation == _restoreGeneration) _restoringInputs = false;
    }
  }

  void _applyRecordToInputs(SalaryRecord record, {bool notify = true}) {
    void apply() {
      _totalDays = record.totalDays;
      _leaveDays = record.leaveDays;
      _sickLeaveDays = record.sickLeaveDays;
      _overtimeHours = record.overtimeHours;
      _useCustomOvertimeBase = record.useCustomOvertimeBase;
      _overtimeBaseDaily = record.overtimeBaseDaily;
      _shiftWork = record.shiftWork;
      _hourlyBenefitsAmount = record.hourlyBenefitsAmount;
      _hourlyBenefitHours = record.hourlyBenefitHours;
      _useAutoShiftWork =
          (_selectedEmployee?.hasShiftWork ?? false) && record.shiftWork > 0;
      _useAutoHourlyBenefits = record.hourlyBenefitHours > 0;
      _otherBenefitsOverride = record.workDays > 0
          ? record.otherBenefits / record.workDays
          : record.otherBenefits;
      _useAutoOtherBenefits = false;
      _loanInstallment = record.loanInstallment;
      _skipLoanInstallmentThisMonth =
          record.loanInstallment == 0 && _employeeLoans.isNotEmpty;
      _useAutoLoanInstallment = _skipLoanInstallmentThisMonth
          ? true
          : record.loanInstallment == _activeLoanInstallmentTotal &&
                _employeeLoans.isNotEmpty;
      _includeLeaveInPayslip = record.includeLeaveInPayslip;
      _insuranceExempt = record.insuranceBase == 0 && record.totalEarnings > 0;
      _taxExempt = record.tax == 0 && record.totalEarnings > 400000000;
      _housingExempt = record.housingExempt;
      _foodExempt = record.foodExempt;
      _seniorityExempt = record.seniorityExempt;
      _advance = record.advance;
      _useAutoAdvances =
          _employeeAdvances.isNotEmpty && record.advance == _activeAdvanceTotal;
      _otherDeductions = record.otherDeductions;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _applyDraftToInputs(SalaryDraft draft, {bool notify = true}) {
    void apply() {
      _totalDays = draft.totalDays;
      _leaveDays = draft.leaveDays;
      _sickLeaveDays = draft.sickLeaveDays;
      _overtimeHours = draft.overtimeHours;
      _useCustomOvertimeBase = draft.useCustomOvertimeBase;
      _overtimeBaseDaily = draft.overtimeBaseDaily;
      _shiftWork = draft.shiftWork;
      _useAutoShiftWork = draft.autoShiftWork;
      _hourlyBenefitsAmount = draft.hourlyBenefitsAmount;
      _hourlyBenefitHours = draft.hourlyBenefitHours;
      _useAutoHourlyBenefits = draft.autoHourlyBenefits;
      _otherBenefitsOverride = draft.otherBenefitsOverride;
      _useAutoOtherBenefits = draft.autoOtherBenefits;
      _loanInstallment = draft.loanInstallment;
      _useAutoLoanInstallment = draft.autoLoanInstallment;
      _skipLoanInstallmentThisMonth = draft.skipLoanInstallment;
      _advance = draft.advance;
      _useAutoAdvances = draft.autoAdvances;
      _otherDeductions = draft.otherDeductions;
      _includeLeaveInPayslip = draft.includeLeaveInPayslip;
      _insuranceExempt = draft.insuranceExempt;
      _taxExempt = draft.taxExempt;
      _housingExempt = draft.housingExempt;
      _foodExempt = draft.foodExempt;
      _seniorityExempt = draft.seniorityExempt;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _resetInputs({bool notify = true}) {
    void apply() {
      _totalDays = PersianDateHelper.daysInMonth(_year, _month);
      _leaveDays = _activeAnnualLeaveDays;
      _sickLeaveDays = _activeSickLeaveDays;
      _overtimeHours = 0;
      _useCustomOvertimeBase =
          _selectedEmployee?.useCustomOvertimeBase ?? false;
      _overtimeBaseDaily = _selectedEmployee?.overtimeBaseDaily ?? 0;
      _shiftWork = 0;
      _hourlyBenefitsAmount = 0;
      _hourlyBenefitHours = _selectedEmployee?.hourlyBenefits ?? 0;
      _useAutoShiftWork = _selectedEmployee?.hasShiftWork ?? false;
      _useAutoHourlyBenefits = true;
      _includeLeaveInPayslip = true;
      _otherBenefitsOverride = -1;
      _useAutoOtherBenefits = true;
      _useAutoLoanInstallment = true;
      _skipLoanInstallmentThisMonth = false;
      _loanInstallment = _activeLoanInstallmentTotal;
      _useAutoAdvances = _employeeAdvances.isNotEmpty;
      _insuranceExempt = false;
      _taxExempt = false;
      _housingExempt = false;
      _foodExempt = false;
      _seniorityExempt = false;
      _advance = _useAutoAdvances ? _activeAdvanceTotal : 0;
      _otherDeductions = 0;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _applyMonthlyLeaveRecordsToInputs({bool notify = true}) {
    void apply() {
      _leaveDays = _activeAnnualLeaveDays;
      _sickLeaveDays = _activeSickLeaveDays;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _calculate({bool saveDraft = true}) {
    if (!mounted) return;
    if (_selectedEmployee == null || _settings == null) {
      setState(() => _result = null);
      return;
    }
    final input = SalaryCalculationInput(
      totalDays: _totalDays,
      leaveDays: _leaveDays,
      sickLeaveDays: _sickLeaveDays,
      overtimeHours: _overtimeHours,
      useCustomOvertimeBase: _useCustomOvertimeBase,
      overtimeBaseDaily: _overtimeBaseDaily,
      shiftWork: _shiftWork,
      hourlyBenefitsAmount: _hourlyBenefitsAmount,
      hourlyBenefitHours: _hourlyBenefitHours,
      autoShiftWork: _useAutoShiftWork,
      autoHourlyBenefits: _useAutoHourlyBenefits,
      includeLeaveInPayslip: _includeLeaveInPayslip,
      insuranceExempt: _insuranceExempt,
      taxExempt: _taxExempt,
      housingExempt: _housingExempt,
      foodExempt: _foodExempt,
      seniorityExempt: _seniorityExempt,
      otherBenefitsOverride: _useAutoOtherBenefits
          ? -1
          : _otherBenefitsOverride,
      loanInstallment: _loanInstallment,
      advance: _advance,
      otherDeductions: _otherDeductions,
    );
    final result = SalaryCalculator.calculate(
      employee: _selectedEmployee!,
      settings: _settings!,
      input: input,
    );
    setState(() => _result = result);
    if (saveDraft) _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (_loading || _restoringInputs) return;
    if (_selectedEmployee?.id == null) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 700), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final employeeId = _selectedEmployee?.id;
    if (employeeId == null || _restoringInputs) return;
    final draft = SalaryDraft(
      employeeId: employeeId,
      year: _year,
      month: _month,
      totalDays: _totalDays,
      leaveDays: _leaveDays,
      sickLeaveDays: _sickLeaveDays,
      overtimeHours: _overtimeHours,
      useCustomOvertimeBase: _useCustomOvertimeBase,
      overtimeBaseDaily: _overtimeBaseDaily,
      shiftWork: _shiftWork,
      autoShiftWork: _useAutoShiftWork,
      hourlyBenefitsAmount: _hourlyBenefitsAmount,
      hourlyBenefitHours: _hourlyBenefitHours,
      autoHourlyBenefits: _useAutoHourlyBenefits,
      otherBenefitsOverride: _otherBenefitsOverride,
      autoOtherBenefits: _useAutoOtherBenefits,
      loanInstallment: _loanInstallment,
      autoLoanInstallment: _useAutoLoanInstallment,
      skipLoanInstallment: _skipLoanInstallmentThisMonth,
      advance: _advance,
      autoAdvances: _useAutoAdvances,
      otherDeductions: _otherDeductions,
      includeLeaveInPayslip: _includeLeaveInPayslip,
      insuranceExempt: _insuranceExempt,
      taxExempt: _taxExempt,
      housingExempt: _housingExempt,
      foodExempt: _foodExempt,
      seniorityExempt: _seniorityExempt,
    );
    try {
      await _salaryDraftService.upsert(draft, scheduleSync: false);
    } catch (_) {
      // Draft saving is best-effort and must not interrupt salary entry.
    }
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    super.dispose();
  }

  double get _activeLoanInstallmentTotal =>
      _employeeLoans.fold(0, (s, l) => s + l.nextInstallmentAmount);

  double get _activeAdvanceTotal =>
      _employeeAdvances.fold(0, (sum, advance) => sum + advance.amount);

  double get _activeAnnualLeaveDays => _employeeLeaves.fold(
    0,
    (sum, leave) => leave.isSick ? sum : sum + leave.days,
  );

  double get _activeSickLeaveDays => _employeeLeaves.fold(
    0,
    (sum, leave) => leave.isSick ? sum + leave.days : sum,
  );

  double get _workDays => (_totalDays - _leaveDays - _sickLeaveDays).clamp(
    0.0,
    _totalDays.toDouble(),
  );

  double get _payableDays =>
      (_totalDays - _sickLeaveDays).clamp(0.0, _totalDays.toDouble());

  String? get _attendanceError {
    if (_leaveDays < 0 || _sickLeaveDays < 0) {
      return 'تعداد روزهای مرخصی و استعلاجی نمی‌تواند منفی باشد.';
    }
    if (_leaveDays + _sickLeaveDays > _totalDays) {
      return 'جمع مرخصی و استعلاجی نباید از کل روزهای کارکرد بیشتر باشد.';
    }
    return null;
  }

  bool _validateAttendance() {
    final error = _attendanceError;
    if (error == null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return false;
  }

  Future<void> _saveAndShowPayslip({bool deductLoanInstallments = true}) async {
    if (_saving) return;
    if (_result == null || _selectedEmployee == null) return;
    if (!_validateAttendance()) return;
    if (_useCustomOvertimeBase && _overtimeBaseDaily <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('مبنای روزانه اضافه‌کاری باید بیشتر از صفر باشد'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (!_isEditMode && !_selectedEmployee!.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'برای کارمند غیرفعال امکان ثبت فیش حقوق جدید وجود ندارد',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final record = _result!.toRecord(
      employeeId: _selectedEmployee!.id!,
      employeeFullNameSnapshot: _selectedEmployee!.fullName,
      employeePersonnelCodeSnapshot: _selectedEmployee!.personnelCode,
      employeeNationalIdSnapshot: _selectedEmployee!.nationalId,
      employeePayslipFooterNoteSnapshot: _selectedEmployee!.payslipFooterNote,
      year: _year,
      month: _month,
      totalDays: _totalDays,
      leaveDays: _leaveDays,
      sickLeaveDays: _sickLeaveDays,
      workDays: _workDays,
      overtimeHours: _overtimeHours,
      hourlyBenefitHours: _useAutoHourlyBenefits ? _hourlyBenefitHours : 0,
      includeLeaveInPayslip: _includeLeaveInPayslip,
      housingExempt: _housingExempt,
      foodExempt: _foodExempt,
      seniorityExempt: _seniorityExempt,
    );

    try {
      if (!_isEditMode) {
        final existing = await _salaryService.getByEmployeeYearMonth(
          _selectedEmployee!.id!,
          _year,
          _month,
        );
        if (existing != null) {
          final action = await _showExistingRecordDialog();
          if (action == _ExistingRecordAction.showExisting) {
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PayslipScreen(
                  employee: _selectedEmployee!,
                  settings: _settings!,
                  record: existing,
                ),
              ),
            );
            return;
          }
          if (action != _ExistingRecordAction.replace) return;
        }
      }

      await _persistEmployeeOvertimePreference();
      await _saveDraft();
      final recordId = await _salaryService.insertOrUpdate(record);

      if (deductLoanInstallments &&
          _useAutoLoanInstallment &&
          !_skipLoanInstallmentThisMonth &&
          _loanInstallment > 0) {
        for (final loan in _employeeLoans) {
          if (loan.isActive && loan.id != null) {
            await _loanService.recordInstallmentPayment(loan.id!);
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فیش حقوق با موفقیت ذخیره شد'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayslipScreen(
            employee: _selectedEmployee!,
            settings: _settings!,
            record: record.copyWithId(recordId),
          ),
        ),
      );
      if (!mounted) return;
      await _loadEmployeeDeductions(_selectedEmployee!.id!);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMessage.from(
              e,
              fallback:
                  'ذخیره فیش انجام نشد. اطلاعات را بررسی و دوباره تلاش کنید.',
            ),
          ),
          backgroundColor: scheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persistEmployeeOvertimePreference() async {
    final employee = _selectedEmployee;
    if (employee?.id == null) return;
    if (employee!.useCustomOvertimeBase == _useCustomOvertimeBase &&
        employee.overtimeBaseDaily == _overtimeBaseDaily) {
      return;
    }
    final updated = employee.copyWith(
      useCustomOvertimeBase: _useCustomOvertimeBase,
      overtimeBaseDaily: _overtimeBaseDaily,
    );
    await _employeeService.update(updated, sync: false);
    _selectedEmployee = updated;
    final index = _employees.indexWhere((item) => item.id == updated.id);
    if (index >= 0) _employees[index] = updated;
  }

  Future<void> _onAutoShiftWorkChanged(bool value) async {
    if (!value &&
        _useAutoShiftWork &&
        (_selectedEmployee?.hasShiftWork ?? false)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('غیرفعال‌کردن نوبت‌کاری'),
          content: const Text(
            'این کارمند در اطلاعات پرسنلی به‌عنوان نوبت‌کار ثبت شده است. نوبت‌کاری فقط برای این فیش غیرفعال شود؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('غیرفعال شود'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() => _useAutoShiftWork = value);
    _calculate();
  }

  Future<_ExistingRecordAction?> _showExistingRecordDialog() {
    return showDialog<_ExistingRecordAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فیش تکراری'),
        content: const Text(
          'برای این کارمند در این ماه قبلاً یک فیش ثبت شده است. فیش قبلی جایگزین شود یا همان فیش قبلی نمایش داده شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _ExistingRecordAction.showExisting),
            child: const Text('نمایش فیش قبلی'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ExistingRecordAction.replace),
            child: const Text('جایگزینی'),
          ),
        ],
      ),
    );
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 600;

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
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      return widget.embedded ? loading : const Scaffold(body: loading);
    }
    final scheme = Theme.of(context).colorScheme;
    final responsive = Responsive.of(context);
    final isWide = responsive.isExpanded;

    return Scaffold(
      appBar:
          widget.embedded ||
              (!responsive.showsSidebar && !Navigator.canPop(context))
          ? null
          : AppBar(
              title: Text(
                _isEditMode ? 'ویرایش فیش حقوق' : 'محاسبه حقوق ماهانه',
              ),
              actions: [
                if (_result != null && _selectedEmployee != null)
                  IconButton(
                    icon: const Icon(Icons.print_rounded),
                    tooltip: 'مشاهده فیش حقوق',
                    onPressed: () {
                      if (!_validateAttendance()) return;
                      final rec = _result!.toRecord(
                        employeeId: _selectedEmployee!.id!,
                        employeeFullNameSnapshot: _selectedEmployee!.fullName,
                        employeePersonnelCodeSnapshot:
                            _selectedEmployee!.personnelCode,
                        employeeNationalIdSnapshot:
                            _selectedEmployee!.nationalId,
                        employeePayslipFooterNoteSnapshot:
                            _selectedEmployee!.payslipFooterNote,
                        year: _year,
                        month: _month,
                        totalDays: _totalDays,
                        leaveDays: _leaveDays,
                        sickLeaveDays: _sickLeaveDays,
                        workDays: _workDays,
                        overtimeHours: _overtimeHours,
                        hourlyBenefitHours: _useAutoHourlyBenefits
                            ? _hourlyBenefitHours
                            : 0,
                        includeLeaveInPayslip: _includeLeaveInPayslip,
                        housingExempt: _housingExempt,
                        foodExempt: _foodExempt,
                        seniorityExempt: _seniorityExempt,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayslipScreen(
                            employee: _selectedEmployee!,
                            settings: _settings!,
                            record: rec,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
      body: _employees.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'ابتدا کارمندان را در منوی «مدیریت کارمندان» ثبت کنید',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : isWide
          ? Row(
              children: [
                Expanded(flex: 5, child: _buildInputs()),
                VerticalDivider(width: 1, color: scheme.outlineVariant),
                Expanded(flex: 4, child: _buildResults()),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 3, child: _buildInputs()),
                Divider(height: 1, color: scheme.outlineVariant),
                Expanded(flex: 2, child: _buildResults()),
              ],
            ),
    );
  }

  Widget _buildInputs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(
            context: context,
            title: 'انتخاب کارمند و دوره',
            icon: Icons.person_search_rounded,
            accent: Theme.of(context).colorScheme.primary,
            children: [
              DropdownButtonFormField<Employee>(
                initialValue: _selectedEmployee,
                decoration: const InputDecoration(
                  labelText: 'کارمند *',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                items: _employees
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          '${PersianNumberFormatter.toPersian(e.personnelCode.toString())} - ${e.fullName}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onEmployeeChanged,
              ),
              const SizedBox(height: 12),
              _responsiveRow(
                isMobile: _isMobile,
                children: [
                  MouseWheelPicker<int>(
                    value: _month,
                    options: List.generate(12, (index) => index + 1),
                    onChanged: _onMonthChanged,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('salary-month-$_month'),
                      initialValue: _month,
                      decoration: const InputDecoration(
                        labelText: 'ماه',
                        prefixIcon: Icon(Icons.calendar_view_month_rounded),
                      ),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem(
                          value: m,
                          child: Text(PersianDateHelper.monthName(m)),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) _onMonthChanged(value);
                      },
                    ),
                  ),
                  MouseWheelPicker<int>(
                    value: _year,
                    options: PersianDateHelper.nearbyYearOptions(
                      selectedYear: _year,
                    ),
                    onChanged: _onYearChanged,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('salary-year-$_year'),
                      initialValue: _year,
                      decoration: const InputDecoration(
                        labelText: 'سال',
                        prefixIcon: Icon(Icons.event_rounded),
                      ),
                      items:
                          PersianDateHelper.nearbyYearOptions(
                                selectedYear: _year,
                              )
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    PersianNumberFormatter.toPersian(
                                      y.toString(),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) _onYearChanged(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildSection(
            context: context,
            title: 'کارکرد و ساعت',
            icon: Icons.access_time_rounded,
            accent: Theme.of(context).colorScheme.tertiary,
            children: [
              _responsiveRow(
                isMobile: _isMobile,
                children: [
                  _intField(
                    label: 'کل کارکرد (روز)',
                    icon: Icons.date_range_rounded,
                    value: _totalDays,
                    onChanged: (v) {
                      setState(() => _totalDays = v);
                      _calculate();
                    },
                  ),
                  PersianNumberField(
                    label: 'مرخصی (روز)',
                    prefixIcon: Icons.beach_access_rounded,
                    suffix: 'روز',
                    initialValue: _leaveDays,
                    maxDecimalDigits: 1,
                    onChanged: (v) {
                      setState(() => _leaveDays = v?.toDouble() ?? 0);
                      _calculate();
                    },
                  ),
                  PersianNumberField(
                    label: 'استعلاجی (روز)',
                    prefixIcon: Icons.medical_services_rounded,
                    suffix: 'روز',
                    initialValue: _sickLeaveDays,
                    maxDecimalDigits: 1,
                    onChanged: (v) {
                      setState(() => _sickLeaveDays = v?.toDouble() ?? 0);
                      _calculate();
                    },
                  ),
                  _workDaysCard(),
                ],
              ),
              const SizedBox(height: 8),
              if (_leaveDays > 0) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('محاسبه مرخصی در فیش حقوقی'),
                  subtitle: Text(
                    _settings == null
                        ? ''
                        : 'سقف ماهانه ${PersianNumberFormatter.toPersian(_settings!.monthlyLeaveAllowance.toString())} روز، سالانه ${PersianNumberFormatter.toPersian(_settings!.annualLeaveAllowance.toString())} روز',
                  ),
                  value: _includeLeaveInPayslip,
                  onChanged: (v) {
                    setState(() => _includeLeaveInPayslip = v);
                    _calculate();
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (_sickLeaveDays > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Text(
                    'استعلاجی تاییدشده از سهم مرخصی استحقاقی کم نمی‌شود. حقوق این روزها در فیش کارفرما محاسبه نمی‌شود و غرامت آن طبق مقررات، جداگانه توسط تامین اجتماعی پرداخت می‌شود.',
                  ),
                ),
              const SizedBox(height: 12),
              _buildTimeEarningsControls(),
            ],
          ),
          _buildSection(
            context: context,
            title: 'سایر مزایا',
            icon: Icons.card_giftcard_rounded,
            accent: Theme.of(context).colorScheme.secondary,
            children: [
              SwitchListTile(
                title: const Text(
                  'محاسبه خودکار سایر مزایا (روزانه × کارکرد خالص)',
                ),
                value: _useAutoOtherBenefits,
                onChanged: (v) {
                  setState(() => _useAutoOtherBenefits = v);
                  _calculate();
                },
              ),
              if (!_useAutoOtherBenefits)
                PersianNumberField(
                  label: 'سایر مزایا روزانه (ریال) - دستی',
                  isCurrency: true,
                  prefixIcon: Icons.edit_rounded,
                  initialValue: _otherBenefitsOverride >= 0
                      ? _otherBenefitsOverride
                      : 0,
                  onChanged: (v) {
                    _otherBenefitsOverride = v?.toDouble() ?? 0;
                    _calculate();
                  },
                ),
            ],
          ),
          _buildSection(
            context: context,
            title: 'معافیت مزایای ثابت',
            icon: Icons.block_rounded,
            accent: Theme.of(context).colorScheme.primary,
            children: [
              Text(
                'این گزینه‌ها فقط مبلغ همان ردیف را برای این فیش صفر می‌کنند و نتیجه در جمع حقوق، بیمه، مالیات و فیش ذخیره‌شده لحاظ می‌شود.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('معاف از حق مسکن'),
                subtitle: const Text('حق مسکن این فیش صفر محاسبه شود'),
                value: _housingExempt,
                onChanged: (v) {
                  setState(() => _housingExempt = v);
                  _calculate();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('معاف از حق خواروبار (بن)'),
                subtitle: const Text('حق خواروبار این فیش صفر محاسبه شود'),
                value: _foodExempt,
                onChanged: (v) {
                  setState(() => _foodExempt = v);
                  _calculate();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('معاف از پایه سنوات'),
                subtitle: const Text('پایه سنوات این فیش صفر محاسبه شود'),
                value: _seniorityExempt,
                onChanged: (v) {
                  setState(() => _seniorityExempt = v);
                  _calculate();
                },
              ),
            ],
          ),
          _buildSection(
            context: context,
            title: 'کسورات',
            icon: Icons.money_off_rounded,
            accent: Theme.of(context).colorScheme.error,
            children: [
              SwitchListTile(
                title: const Text('کسر اقساط وام به صورت خودکار'),
                subtitle: _employeeLoans.isEmpty
                    ? const Text('وام فعالی برای این کارمند ثبت نشده')
                    : Text(
                        'تعداد وام فعال: ${PersianNumberFormatter.toPersian(_employeeLoans.length.toString())}',
                      ),
                value: _useAutoLoanInstallment,
                onChanged: (v) {
                  setState(() {
                    _useAutoLoanInstallment = v;
                    if (!v) {
                      _skipLoanInstallmentThisMonth = false;
                    } else if (_skipLoanInstallmentThisMonth) {
                      _loanInstallment = 0;
                    } else {
                      _loanInstallment = _activeLoanInstallmentTotal;
                    }
                  });
                  _calculate();
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('معاف از محاسبه وام در این ماه'),
                subtitle: const Text(
                  'فقط برای همین فیش اعمال می‌شود و از ماه بعد اقساط دوباره خودکار محاسبه می‌شود.',
                ),
                value: _skipLoanInstallmentThisMonth,
                onChanged: _employeeLoans.isEmpty
                    ? null
                    : (v) {
                        setState(() {
                          _skipLoanInstallmentThisMonth = v;
                          if (v) {
                            _useAutoLoanInstallment = true;
                            _loanInstallment = 0;
                          } else if (_useAutoLoanInstallment) {
                            _loanInstallment = _activeLoanInstallmentTotal;
                          }
                        });
                        _calculate();
                      },
              ),
              if (!_useAutoLoanInstallment && !_skipLoanInstallmentThisMonth)
                PersianNumberField(
                  key: ValueKey('lin_$_loanInstallment'),
                  label: 'قسط وام (ریال)',
                  isCurrency: true,
                  prefixIcon: Icons.account_balance_wallet_rounded,
                  initialValue: _loanInstallment,
                  onChanged: (v) {
                    _loanInstallment = v?.toDouble() ?? 0;
                    _calculate();
                  },
                ),
              if (_useAutoLoanInstallment &&
                  _employeeLoans.isNotEmpty &&
                  !_skipLoanInstallmentThisMonth)
                _employeeLoansList(),
              const SizedBox(height: 12),
              if (_employeeAdvances.isNotEmpty) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('کسر مساعده‌های ثبت‌شده در این ماه'),
                  subtitle: Text(
                    'تعداد مساعده: ${PersianNumberFormatter.toPersian(_employeeAdvances.length.toString())} | جمع: ${PersianNumberFormatter.formatRial(_activeAdvanceTotal, showUnit: true)}',
                  ),
                  value: _useAutoAdvances,
                  onChanged: (value) {
                    setState(() {
                      _useAutoAdvances = value;
                      if (value) _advance = _activeAdvanceTotal;
                    });
                    _calculate();
                  },
                ),
                if (_useAutoAdvances) _employeeAdvancesList(),
                const SizedBox(height: 12),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('عدم شمول بیمه برای این فیش'),
                subtitle: const Text('برای فیش‌هایی که مشمول حق بیمه نیستند'),
                value: _insuranceExempt,
                onChanged: (v) {
                  setState(() => _insuranceExempt = v);
                  _calculate();
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('عدم شمول مالیات برای این فیش'),
                subtitle: const Text(
                  'برای فیش‌هایی که مشمول مالیات حقوق نیستند',
                ),
                value: _taxExempt,
                onChanged: (v) {
                  setState(() => _taxExempt = v);
                  _calculate();
                },
              ),
              const SizedBox(height: 12),
              _responsiveRow(
                isMobile: _isMobile,
                children: [
                  if (!_useAutoAdvances || _employeeAdvances.isEmpty)
                    PersianNumberField(
                      label: 'مساعده (ریال)',
                      isCurrency: true,
                      prefixIcon: Icons.attach_money_rounded,
                      initialValue: _advance,
                      onChanged: (v) {
                        _advance = v?.toDouble() ?? 0;
                        _calculate();
                      },
                    )
                  else
                    _autoAdvanceSummary(),
                  PersianNumberField(
                    label: 'سایر کسورات / مابه تفاوت',
                    isCurrency: true,
                    prefixIcon: Icons.remove_circle_outline_rounded,
                    initialValue: _otherDeductions,
                    onChanged: (v) {
                      _otherDeductions = v?.toDouble() ?? 0;
                      _calculate();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving || _selectedEmployee == null
                ? null
                : _saveAndShowPayslip,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isEditMode ? 'ویرایش و چاپ فیش حقوق' : 'ذخیره و چاپ فیش حقوق',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _isEditMode
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workDaysCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'کارکرد خالص',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDays(_workDays)} روز',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'قابل پرداخت کارفرما: ${_formatDays(_payableDays)} روز',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEarningsControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _timeEarningsPanel(
          title: 'اضافه‌کاری',
          icon: Icons.timer_rounded,
          children: [
            PersianNumberField(
              label: 'ساعت اضافه‌کاری',
              prefixIcon: Icons.timer_rounded,
              initialValue: _overtimeHours,
              onChanged: (v) {
                _overtimeHours = v?.toDouble() ?? 0;
                _calculate();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مبنای دستی اضافه‌کاری'),
              subtitle: const Text(
                'فرمول: مبنای روزانه ÷ ۷.۳۳ × ۱.۴ × ساعت اضافه‌کاری',
              ),
              value: _useCustomOvertimeBase,
              onChanged: (value) {
                setState(() {
                  _useCustomOvertimeBase = value;
                  if (value && _overtimeBaseDaily <= 0) {
                    _overtimeBaseDaily = _selectedEmployee?.dailyWage1405 ?? 0;
                  }
                });
                _calculate();
              },
            ),
            if (_useCustomOvertimeBase)
              PersianNumberField(
                label: 'مبنای روزانه اضافه‌کاری (ریال)',
                isCurrency: true,
                prefixIcon: Icons.calculate_rounded,
                initialValue: _overtimeBaseDaily,
                onChanged: (value) {
                  _overtimeBaseDaily = value?.toDouble() ?? 0;
                  _calculate();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _timeEarningsPanel(
          title: 'نوبت‌کاری',
          icon: Icons.nightlight_round,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نوبت‌کاری خودکار'),
              subtitle: const Text('۱۵٪ حقوق ثابت'),
              value: _useAutoShiftWork,
              onChanged: _onAutoShiftWorkChanged,
            ),
            if (!_useAutoShiftWork)
              PersianNumberField(
                label: 'مبلغ نوبت‌کاری (ریال)',
                isCurrency: true,
                prefixIcon: Icons.nightlight_round,
                initialValue: _shiftWork,
                onChanged: (v) {
                  _shiftWork = v?.toDouble() ?? 0;
                  _calculate();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _timeEarningsPanel(
          title: 'مزایای ساعتی',
          icon: Icons.access_time_filled_rounded,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('محاسبه خودکار مزایای ساعتی'),
              subtitle: Text(
                _selectedEmployee == null
                    ? 'بعد از انتخاب کارمند، ساعت قرارداد خوانده می‌شود'
                    : 'فرمول: دستمزد روزانه / ۷.۳۳ × ۱.۴ × ساعت',
              ),
              value: _useAutoHourlyBenefits,
              onChanged: (v) {
                if (v && _hourlyBenefitHours == 0) {
                  _hourlyBenefitHours = _selectedEmployee?.hourlyBenefits ?? 0;
                }
                setState(() => _useAutoHourlyBenefits = v);
                _calculate();
              },
            ),
            if (_useAutoHourlyBenefits)
              PersianNumberField(
                label: 'ساعت مزایای ساعتی',
                prefixIcon: Icons.access_time_filled_rounded,
                suffix: 'ساعت',
                initialValue: _hourlyBenefitHours,
                onChanged: (v) {
                  _hourlyBenefitHours = v?.toDouble() ?? 0;
                  _calculate();
                },
              )
            else
              PersianNumberField(
                label: 'مزایای ساعتی (مبلغ دستی)',
                isCurrency: true,
                prefixIcon: Icons.access_time_filled_rounded,
                initialValue: _hourlyBenefitsAmount,
                onChanged: (v) {
                  _hourlyBenefitsAmount = v?.toDouble() ?? 0;
                  _calculate();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _timeEarningsPanel({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDays(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return PersianNumberFormatter.toPersian(text);
  }

  Widget _employeeLoansList() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وام‌های فعال:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._employeeLoans.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'وام #${PersianNumberFormatter.toPersian(l.loanNumber.toString())}: ',
                    style: const TextStyle(fontSize: 13),
                  ),
                  CurrencyText(
                    l.nextInstallmentAmount,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Text(' ریال', style: TextStyle(fontSize: 11)),
                  const Spacer(),
                  Text(
                    'قسط ${PersianNumberFormatter.formatDecimal(l.paidInstallments + l.nextInstallmentStep)} '
                    'از ${PersianNumberFormatter.formatDecimal(l.totalInstallments)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 16, color: scheme.outlineVariant),
          Row(
            children: [
              const Text(
                'جمع کل: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              CurrencyText(
                _loanInstallment,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Text(' ریال', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _employeeAdvancesList() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: scheme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مساعده‌های همین دوره:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._employeeAdvances.map(
            (advance) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      PersianNumberFormatter.toPersian(advance.paymentDate),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  CurrencyText(
                    advance.amount,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Text(' ریال', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoAdvanceSummary() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: scheme.tertiary, size: 20),
          const SizedBox(width: 8),
          const Expanded(child: Text('مساعده خودکار این ماه')),
          CurrencyText(
            _advance,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final scheme = Theme.of(context).colorScheme;
    if (_selectedEmployee == null || _result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 64,
                color: scheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'کارمندی را برای محاسبه انتخاب کنید',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: FloatingNavSafeArea.scrollPadding(
        context,
        left: 16,
        top: 16,
        right: 16,
        minimumBottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _resultsHeader(),
          const SizedBox(height: 12),
          _resultGroup(
            title: 'حقوق و مزایا',
            color: AppTheme.successColor,
            icon: Icons.add_circle_rounded,
            items: [
              _resultRow('حقوق ثابت', _result!.baseSalary),
              _resultRow('حق مسکن', _result!.housing),
              _resultRow('حق خواروبار (بن)', _result!.food),
              _resultRow('حق تاهل', _result!.marriage),
              _resultRow('حق فرزند', _result!.childAllowance),
              _resultRow('پایه سنوات', _result!.seniority),
              _resultRow('سایر مزایا', _result!.otherBenefits),
              _resultRow('نوبت‌کاری', _result!.shiftWork),
              _resultRow('اضافه‌کاری', _result!.overtimeAmount),
              _resultRow('مزایای ساعتی', _result!.hourlyBenefitsAmount),
            ],
            total: _result!.totalEarnings,
            totalLabel: 'جمع حقوق و مزایا',
          ),
          const SizedBox(height: 12),
          _resultGroup(
            title: 'کسورات',
            color: scheme.error,
            icon: Icons.remove_circle_rounded,
            items: [
              _resultRow('حق بیمه ۷٪', _result!.insurance),
              _resultRow('مالیات بر حقوق', _result!.tax),
              _resultRow('قسط وام', _result!.loanInstallment),
              _resultRow('مساعده', _result!.advance),
              _resultRow('سایر کسورات', _result!.otherDeductions),
              _resultRow('کسر مرخصی مازاد', _result!.leaveDeduction),
            ],
            total: _result!.totalDeductions,
            totalLabel: 'جمع کسورات',
          ),
          const SizedBox(height: 12),
          _finalPaymentCard(),
          const SizedBox(height: 12),
          _detailsExpansion(),
        ],
      ),
    );
  }

  Widget _resultsHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: scheme.onPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedEmployee!.fullName}  •  کد ${PersianNumberFormatter.toPersian(_selectedEmployee!.personnelCode.toString())}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${PersianDateHelper.monthName(_month)} ${PersianNumberFormatter.toPersian(_year.toString())}',
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _finalPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor,
            AppTheme.successColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          _resultRow('خالص حقوق', _result!.netSalary, white: true, bold: false),
          if (_result!.rounding != 0)
            _resultRow(
              'رند حقوق',
              _result!.rounding.toDouble(),
              white: true,
              bold: false,
            ),
          Divider(color: context.onGradientTextFaint, height: 24),
          Row(
            children: [
              const Text(
                'خالص دریافتی:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              CurrencyText(
                _result!.finalPayment,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ریال',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsExpansion() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      title: const Text('جزئیات محاسبات (مبنا و سهم کارفرما)'),
      initiallyExpanded: false,
      children: [
        _resultRow('مبنای بیمه', _result!.insuranceBase),
        _resultRow('مبنای مالیات', _result!.taxBase),
        _resultRow('معافیت دو هفتم', _result!.twoSevenExemption),
        _plainDetailRow(
          'مرخصی مجاز ماهانه',
          '${_formatDays(_result!.leaveAllowanceDays)} روز',
        ),
        _plainDetailRow(
          'مرخصی مازاد',
          '${_formatDays(_result!.excessLeaveDays)} روز',
        ),
        if (_sickLeaveDays > 0)
          _plainDetailRow(
            'مرخصی استعلاجی',
            '${_formatDays(_sickLeaveDays)} روز',
          ),
        _plainDetailRow(
          'روزهای قابل پرداخت کارفرما',
          '${_formatDays(_result!.payableDays)} روز',
        ),
        const Divider(),
        _resultRow('سهم کارفرما (۲۰٪)', _result!.employerInsurance),
        _resultRow('بیمه بیکاری (۳٪)', _result!.unemploymentInsurance),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _intField({
    required String label,
    required IconData icon,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return TextFormField(
      controller: TextEditingController(
        text: PersianNumberFormatter.toPersian(value.toString()),
      )..selection = TextSelection.collapsed(offset: value.toString().length),
      inputFormatters: const [PersianDigitsOnlyInputFormatter()],
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      onChanged: (v) {
        final n = int.tryParse(PersianNumberFormatter.toEnglish(v).trim()) ?? 0;
        onChanged(n);
      },
    );
  }

  Widget _resultGroup({
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> items,
    required double total,
    required String totalLabel,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 16),
            ...items,
            const Divider(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    totalLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  CurrencyText(
                    total,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ریال',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(
    String label,
    double value, {
    bool white = false,
    bool bold = false,
  }) {
    if (value == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final color = white ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          CurrencyText(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'ریال',
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _plainDetailRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
