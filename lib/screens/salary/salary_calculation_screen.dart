import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../services/salary_calculator.dart';
import '../../services/salary_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/persian_number_field.dart';
import 'payslip_screen.dart';

class SalaryCalculationScreen extends StatefulWidget {
  const SalaryCalculationScreen({super.key});

  @override
  State<SalaryCalculationScreen> createState() => _SalaryCalculationScreenState();
}

class _SalaryCalculationScreenState extends State<SalaryCalculationScreen> {
  final _employeeService = EmployeeService();
  final _loanService = LoanService();
  final _salaryService = SalaryService();
  final _settingsService = SettingsService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  AppSettings? _settings;
  List<Loan> _employeeLoans = [];

  bool _loading = true;
  bool _saving = false;

  int _year = AppConstants.currentYear;
  int _month = 1;
  int _totalDays = 31;
  int _leaveDays = 0;

  double _overtimeHours = 0;
  double _shiftWork = 0;
  double _hourlyBenefitsAmount = 0;
  double _otherBenefitsOverride = -1;
  double _loanInstallment = 0;
  double _advance = 0;
  double _otherDeductions = 0;

  bool _useAutoLoanInstallment = true;
  bool _useAutoOtherBenefits = true;

  SalaryCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _totalDays = PersianDateHelper.daysInMonth(_year, _month);
    _init();
  }

  Future<void> _init() async {
    _employees = await _employeeService.getAll(onlyActive: true);
    _settings = await _settingsService.getCurrentSettings();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onEmployeeChanged(Employee? emp) async {
    setState(() => _selectedEmployee = emp);
    if (emp != null && emp.id != null) {
      _employeeLoans = await _loanService.getActiveLoansForEmployee(emp.id!);
      if (_useAutoLoanInstallment) {
        _loanInstallment = _employeeLoans.fold(0, (s, l) => s + l.installmentAmount);
      }
      await _checkExistingRecord();
    }
    _calculate();
  }

  Future<void> _checkExistingRecord() async {
    if (_selectedEmployee == null) return;
    final existing = await _salaryService.getByEmployeeYearMonth(
      _selectedEmployee!.id!,
      _year,
      _month,
    );
    if (existing != null) {
      setState(() {
        _totalDays = existing.totalDays;
        _leaveDays = existing.leaveDays;
        _overtimeHours = existing.overtimeHours;
        _shiftWork = existing.shiftWork;
        _hourlyBenefitsAmount = existing.hourlyBenefitsAmount;
        _otherBenefitsOverride = existing.otherBenefits;
        _useAutoOtherBenefits = false;
        _loanInstallment = existing.loanInstallment;
        _useAutoLoanInstallment = false;
        _advance = existing.advance;
        _otherDeductions = existing.otherDeductions;
      });
    } else {
      setState(() {
        _totalDays = PersianDateHelper.daysInMonth(_year, _month);
        _leaveDays = 0;
        _overtimeHours = 0;
        _shiftWork = 0;
        _hourlyBenefitsAmount = 0;
        _otherBenefitsOverride = -1;
        _useAutoOtherBenefits = true;
        _useAutoLoanInstallment = true;
        _loanInstallment = _employeeLoans.fold(0, (s, l) => s + l.installmentAmount);
        _advance = 0;
        _otherDeductions = 0;
      });
    }
  }

  void _calculate() {
    if (_selectedEmployee == null || _settings == null) {
      setState(() => _result = null);
      return;
    }
    final input = SalaryCalculationInput(
      totalDays: _totalDays,
      leaveDays: _leaveDays,
      overtimeHours: _overtimeHours,
      shiftWork: _shiftWork,
      hourlyBenefitsAmount: _hourlyBenefitsAmount,
      otherBenefitsOverride: _useAutoOtherBenefits ? -1 : _otherBenefitsOverride,
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
  }

  Future<void> _saveAndShowPayslip({bool deductLoanInstallments = true}) async {
    if (_result == null || _selectedEmployee == null) return;
    setState(() => _saving = true);

    final workDays = (_totalDays - _leaveDays).clamp(0, _totalDays);
    final record = _result!.toRecord(
      employeeId: _selectedEmployee!.id!,
      year: _year,
      month: _month,
      totalDays: _totalDays,
      leaveDays: _leaveDays,
      workDays: workDays,
      overtimeHours: _overtimeHours,
    );

    try {
      final recordId = await _salaryService.insertOrUpdate(record);

      if (deductLoanInstallments && _useAutoLoanInstallment) {
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
      _employeeLoans = await _loanService.getActiveLoansForEmployee(_selectedEmployee!.id!);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: scheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    final responsive = Responsive.of(context);
    final isWide = responsive.isExpanded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('محاسبه حقوق ماهانه'),
        actions: [
          if (_result != null && _selectedEmployee != null)
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'مشاهده فیش حقوق',
              onPressed: () {
                final workDays = (_totalDays - _leaveDays).clamp(0, _totalDays);
                final rec = _result!.toRecord(
                  employeeId: _selectedEmployee!.id!,
                  year: _year,
                  month: _month,
                  totalDays: _totalDays,
                  leaveDays: _leaveDays,
                  workDays: workDays,
                  overtimeHours: _overtimeHours,
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
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
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
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                              '${PersianNumberFormatter.toPersian(e.personnelCode.toString())} - ${e.fullName}'),
                        ))
                    .toList(),
                onChanged: _onEmployeeChanged,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
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
                      onChanged: (v) async {
                        if (v != null) {
                          setState(() {
                            _month = v;
                            _totalDays = PersianDateHelper.daysInMonth(_year, v);
                          });
                          await _checkExistingRecord();
                          _calculate();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _year,
                      decoration: const InputDecoration(
                        labelText: 'سال',
                        prefixIcon: Icon(Icons.event_rounded),
                      ),
                      items: [1404, 1405, 1406]
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(PersianNumberFormatter.toPersian(y.toString())),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        if (v != null) {
                          setState(() {
                            _year = v;
                            _totalDays = PersianDateHelper.daysInMonth(v, _month);
                          });
                          await _checkExistingRecord();
                          _calculate();
                        }
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
              Row(
                children: [
                  Expanded(
                    child: _intField(
                      label: 'کل کارکرد (روز)',
                      icon: Icons.date_range_rounded,
                      value: _totalDays,
                      onChanged: (v) {
                        setState(() => _totalDays = v);
                        _calculate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _intField(
                      label: 'مرخصی (روز)',
                      icon: Icons.beach_access_rounded,
                      value: _leaveDays,
                      onChanged: (v) {
                        setState(() => _leaveDays = v);
                        _calculate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _workDaysCard(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PersianNumberField(
                      label: 'ساعت اضافه‌کاری',
                      prefixIcon: Icons.timer_rounded,
                      initialValue: _overtimeHours,
                      onChanged: (v) {
                        _overtimeHours = v?.toDouble() ?? 0;
                        _calculate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PersianNumberField(
                      label: 'مبلغ نوبت‌کاری (ریال)',
                      isCurrency: true,
                      prefixIcon: Icons.nightlight_round,
                      initialValue: _shiftWork,
                      onChanged: (v) {
                        _shiftWork = v?.toDouble() ?? 0;
                        _calculate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PersianNumberField(
                label: 'مزایای ساعتی (مبلغ - مثل ۶۰-۶۴-۱۶۰ ساعته)',
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
          _buildSection(
            context: context,
            title: 'سایر مزایا',
            icon: Icons.card_giftcard_rounded,
            accent: Theme.of(context).colorScheme.secondary,
            children: [
              SwitchListTile(
                title: const Text('محاسبه خودکار سایر مزایا (روزانه × کارکرد خالص)'),
                value: _useAutoOtherBenefits,
                onChanged: (v) {
                  setState(() => _useAutoOtherBenefits = v);
                  _calculate();
                },
              ),
              if (!_useAutoOtherBenefits)
                PersianNumberField(
                  label: 'مبلغ سایر مزایا (ریال) - دستی',
                  isCurrency: true,
                  prefixIcon: Icons.edit_rounded,
                  initialValue: _otherBenefitsOverride >= 0 ? _otherBenefitsOverride : 0,
                  onChanged: (v) {
                    _otherBenefitsOverride = v?.toDouble() ?? 0;
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
                        'تعداد وام فعال: ${PersianNumberFormatter.toPersian(_employeeLoans.length.toString())}'),
                value: _useAutoLoanInstallment,
                onChanged: (v) {
                  setState(() {
                    _useAutoLoanInstallment = v;
                    if (v) {
                      _loanInstallment = _employeeLoans.fold(0, (s, l) => s + l.installmentAmount);
                    }
                  });
                  _calculate();
                },
              ),
              if (!_useAutoLoanInstallment)
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
              if (_useAutoLoanInstallment && _employeeLoans.isNotEmpty)
                _employeeLoansList(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PersianNumberField(
                      label: 'مساعده (ریال)',
                      isCurrency: true,
                      prefixIcon: Icons.attach_money_rounded,
                      initialValue: _advance,
                      onChanged: (v) {
                        _advance = v?.toDouble() ?? 0;
                        _calculate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PersianNumberField(
                      label: 'سایر کسورات / مابه تفاوت',
                      isCurrency: true,
                      prefixIcon: Icons.remove_circle_outline_rounded,
                      initialValue: _otherDeductions,
                      onChanged: (v) {
                        _otherDeductions = v?.toDouble() ?? 0;
                        _calculate();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving || _selectedEmployee == null ? null : _saveAndShowPayslip,
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
            label: const Text('ذخیره و چاپ فیش حقوق'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
        ),
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
            '${PersianNumberFormatter.toPersian((_totalDays - _leaveDays).clamp(0, _totalDays).toString())} روز',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeLoansList() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('وام‌های فعال:', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._employeeLoans.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'وام #${PersianNumberFormatter.toPersian(l.loanNumber.toString())}: ',
                      style: const TextStyle(fontSize: 13),
                    ),
                    CurrencyText(l.installmentAmount, style: const TextStyle(fontSize: 13)),
                    const Text(' ریال', style: TextStyle(fontSize: 11)),
                    const Spacer(),
                    Text(
                      'قسط ${PersianNumberFormatter.toPersian((l.paidInstallments + 1).toString())} '
                      'از ${PersianNumberFormatter.toPersian(l.totalInstallments.toString())}',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )),
          Divider(height: 16, color: scheme.outlineVariant),
          Row(
            children: [
              const Text('جمع کل: ', style: TextStyle(fontWeight: FontWeight.w700)),
              CurrencyText(_loanInstallment, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Text(' ریال', style: TextStyle(fontSize: 12)),
            ],
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
              Icon(Icons.touch_app_rounded, size: 64, color: scheme.outlineVariant),
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
      padding: const EdgeInsets.all(16),
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
          colors: [AppTheme.successColor, AppTheme.successColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          _resultRow('خالص حقوق', _result!.netSalary, white: true, bold: false),
          if (_result!.rounding != 0)
            _resultRow('رند حقوق', _result!.rounding.toDouble(), white: true, bold: false),
          Divider(color: Colors.white.withValues(alpha: 0.4), height: 24),
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
              const Text('ریال',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
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
      controller: TextEditingController(text: PersianNumberFormatter.toPersian(value.toString()))
        ..selection = TextSelection.collapsed(offset: value.toString().length),
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
                    style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
                  ),
                  const Spacer(),
                  CurrencyText(
                    total,
                    style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15),
                  ),
                  const SizedBox(width: 4),
                  Text('ریال', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, double value, {bool white = false, bool bold = false}) {
    if (value == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final color = white ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.85)),
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
}
