import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/persian_date_picker.dart';
import '../../widgets/persian_number_field.dart';

enum _LoanCalculationAnchor { totalInstallments, installmentAmount }

enum _LoanCalculationSource { amount, totalInstallments, installmentAmount }

class LoanFormScreen extends StatefulWidget {
  final Loan? loan;
  const LoanFormScreen({super.key, this.loan});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanService = LoanService();
  final _employeeService = EmployeeService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _startDateCtrl;
  late TextEditingController _notesCtrl;

  double _amount = 0;
  double _installmentAmount = 0;
  double _totalInstallments = 0;
  double _paidInstallments = 0;
  int _loanNumber = 1;
  bool _isActive = true;
  _LoanCalculationAnchor _anchor = _LoanCalculationAnchor.totalInstallments;

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    _startDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(
        l?.startDate ?? PersianDateHelper.todayText(),
      ),
    );
    _notesCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(l?.notes ?? ''),
    );
    if (l != null) {
      _amount = l.amount;
      _installmentAmount = l.installmentAmount;
      _totalInstallments = l.totalInstallments;
      _paidInstallments = l.paidInstallments;
      _loanNumber = l.loanNumber;
      _isActive = l.isActive;
    }
    _init();
  }

  Future<void> _init() async {
    _employees = await _employeeService.getAll(onlyActive: widget.loan == null);
    if (widget.loan != null) {
      _selectedEmployee = _employees.cast<Employee?>().firstWhere(
        (e) => e?.id == widget.loan!.employeeId,
        orElse: () => null,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setAmount(num? value) {
    setState(() {
      _amount = value?.toDouble() ?? 0;
      _syncLoanNumbers(_LoanCalculationSource.amount);
    });
  }

  void _setTotalInstallments(num? value) {
    setState(() {
      _totalInstallments = value?.toDouble() ?? 0;
      _anchor = _LoanCalculationAnchor.totalInstallments;
      _syncLoanNumbers(_LoanCalculationSource.totalInstallments);
    });
  }

  void _setInstallmentAmount(num? value) {
    setState(() {
      _installmentAmount = value?.toDouble() ?? 0;
      _anchor = _LoanCalculationAnchor.installmentAmount;
      _syncLoanNumbers(_LoanCalculationSource.installmentAmount);
    });
  }

  void _setPaidInstallments(num? value) {
    setState(() => _paidInstallments = value?.toDouble() ?? 0);
  }

  void _syncLoanNumbers(_LoanCalculationSource source) {
    if (_amount <= 0) return;
    switch (source) {
      case _LoanCalculationSource.amount:
        if (_anchor == _LoanCalculationAnchor.installmentAmount &&
            _installmentAmount > 0) {
          _totalInstallments = _amount / _installmentAmount;
        } else if (_totalInstallments > 0) {
          _installmentAmount = _amount / _totalInstallments;
        } else if (_installmentAmount > 0) {
          _totalInstallments = _amount / _installmentAmount;
        }
        break;
      case _LoanCalculationSource.totalInstallments:
        if (_totalInstallments > 0) {
          _installmentAmount = _amount / _totalInstallments;
        }
        break;
      case _LoanCalculationSource.installmentAmount:
        if (_installmentAmount > 0) {
          _totalInstallments = _amount / _installmentAmount;
        }
        break;
    }
  }

  Future<void> _pickStartDate() async {
    final initial =
        PersianDateHelper.parseJalali(
          PersianNumberFormatter.toEnglish(_startDateCtrl.text),
        ) ??
        PersianDateHelper.today();
    final selected = await showPersianDatePicker(
      context: context,
      initialDate: initial,
    );
    if (selected == null) return;
    setState(() {
      _startDateCtrl.text = PersianNumberFormatter.toPersian(
        PersianDateHelper.formatJalali(selected),
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      _showError('کارمند را انتخاب کنید');
      return;
    }
    if (_amount <= 0) {
      _showError('مبلغ وام نامعتبر است');
      return;
    }

    final totalInstallments = _totalInstallments;
    final paidInstallments = _paidInstallments;
    if (_installmentAmount <= 0) {
      _showError('مبلغ هر قسط نامعتبر است');
      return;
    }
    if (totalInstallments <= 0) {
      _showError('تعداد کل اقساط نامعتبر است');
      return;
    }
    if (paidInstallments < 0 || paidInstallments > totalInstallments) {
      _showError('تعداد اقساط پرداخت‌شده نامعتبر است');
      return;
    }

    setState(() => _saving = true);
    try {
      var loanNum = _loanNumber;
      if (widget.loan == null) {
        final existing = await _loanService.getByEmployee(
          _selectedEmployee!.id!,
        );
        loanNum = existing.length + 1;
      }
      final loan = Loan(
        id: widget.loan?.id,
        employeeId: _selectedEmployee!.id!,
        loanNumber: loanNum,
        amount: _amount,
        installmentAmount: _installmentAmount,
        totalInstallments: totalInstallments,
        paidInstallments: paidInstallments,
        startDate: PersianNumberFormatter.toEnglish(_startDateCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isActive: _isActive && paidInstallments < totalInstallments,
      );
      if (widget.loan == null) {
        await _loanService.insert(loan);
      } else {
        await _loanService.update(loan);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(
        AppErrorMessage.from(
          e,
          fallback: 'ذخیره وام انجام نشد. اطلاعات را بررسی کنید.',
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

  double get _paidAmountPreview =>
      (_installmentAmount * _paidInstallments).clamp(0.0, _amount).toDouble();

  double get _remainingAmountPreview =>
      (_amount - _paidAmountPreview).clamp(0.0, double.infinity).toDouble();

  double get _nextInstallmentPreview {
    if (!_isActive || _remainingAmountPreview <= 0) return 0;
    if (_installmentAmount <= 0) return _remainingAmountPreview;
    return _installmentAmount < _remainingAmountPreview
        ? _installmentAmount
        : _remainingAmountPreview;
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
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    final isMobile = _isMobile;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loan == null ? 'افزودن وام جدید' : 'ویرایش وام'),
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
      body:
          _employees.isEmpty ||
              (widget.loan != null && _selectedEmployee == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  widget.loan != null
                      ? 'کارمند این وام حذف شده است و امکان ویرایش وام وجود ندارد.'
                      : 'ابتدا حداقل یک کارمند فعال ثبت کنید',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSection(
                          context: context,
                          title: 'انتخاب کارمند',
                          icon: Icons.person_rounded,
                          accent: scheme.primary,
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
                              onChanged: widget.loan == null
                                  ? (v) => setState(() => _selectedEmployee = v)
                                  : null,
                              validator: (v) =>
                                  v == null ? 'انتخاب کارمند الزامی است' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context: context,
                          title: 'مبلغ و اقساط',
                          icon: Icons.payments_rounded,
                          accent: AppTheme.warningColor,
                          children: [
                            PersianNumberField(
                              label: 'مبلغ وام (ریال) *',
                              isCurrency: true,
                              prefixIcon: Icons.attach_money_rounded,
                              initialValue: _amount,
                              onChanged: _setAmount,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _responsiveRow(
                              isMobile: isMobile,
                              children: [
                                PersianNumberField(
                                  label: 'تعداد کل اقساط *',
                                  suffix: 'قسط',
                                  prefixIcon: Icons.numbers_rounded,
                                  initialValue: _totalInstallments > 0
                                      ? _totalInstallments
                                      : null,
                                  maxDecimalDigits: 2,
                                  onChanged: _setTotalInstallments,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'الزامی است';
                                    }
                                    final value =
                                        PersianNumberFormatter.parseNumber(v);
                                    if (value == null || value <= 0) {
                                      return 'عدد نامعتبر';
                                    }
                                    return null;
                                  },
                                ),
                                PersianNumberField(
                                  label: 'اقساط پرداخت شده',
                                  suffix: 'قسط',
                                  prefixIcon: Icons.done_rounded,
                                  initialValue: _paidInstallments,
                                  maxDecimalDigits: 2,
                                  onChanged: _setPaidInstallments,
                                  validator: (v) {
                                    final value =
                                        PersianNumberFormatter.parseNumber(
                                          v ?? '',
                                        ) ??
                                        0;
                                    if (value < 0 ||
                                        (_totalInstallments > 0 &&
                                            value > _totalInstallments)) {
                                      return 'عدد نامعتبر';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PersianNumberField(
                              label: 'مبلغ هر قسط (ریال) *',
                              isCurrency: true,
                              prefixIcon: Icons.calculate_rounded,
                              initialValue: _installmentAmount,
                              onChanged: _setInstallmentAmount,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            if (_amount > 0 && _installmentAmount > 0)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _summaryRow(context, 'مبلغ وام:', _amount),
                                    _summaryRow(
                                      context,
                                      'جمع اقساط:',
                                      _installmentAmount * _totalInstallments,
                                    ),
                                    _summaryRow(
                                      context,
                                      'پرداخت‌شده تاکنون:',
                                      _paidAmountPreview,
                                    ),
                                    _summaryRow(
                                      context,
                                      'مانده وام:',
                                      _remainingAmountPreview,
                                    ),
                                    _summaryRow(
                                      context,
                                      'قسط بعدی:',
                                      _nextInstallmentPreview,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context: context,
                          title: 'تاریخ و توضیحات',
                          icon: Icons.event_rounded,
                          accent: scheme.tertiary,
                          children: [
                            TextFormField(
                              controller: _startDateCtrl,
                              readOnly: true,
                              onTap: _pickStartDate,
                              inputFormatters: const [
                                PersianDateInputFormatter(),
                              ],
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'تاریخ شروع وام (شمسی) *',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                suffixIcon: Icon(Icons.edit_calendar_rounded),
                                hintText: 'سال/ماه/روز',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'الزامی است';
                                }
                                final parsed = PersianDateHelper.parseJalali(
                                  PersianNumberFormatter.toEnglish(v),
                                );
                                return parsed == null
                                    ? 'تاریخ نامعتبر است'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 2,
                              inputFormatters: const [
                                PersianDigitsInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'توضیحات (اختیاری)',
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text(
                                'وام فعال (در حال کسر از حقوق)',
                              ),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              secondary: Icon(
                                Icons.toggle_on_rounded,
                                color: _isActive
                                    ? AppTheme.successColor
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final responsive = Responsive.of(context);
                            if (responsive.isCompact) {
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
                                      widget.loan == null
                                          ? 'افزودن وام'
                                          : 'ذخیره تغییرات',
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
                                      widget.loan == null
                                          ? 'افزودن وام'
                                          : 'ذخیره تغییرات',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, double value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          CurrencyText(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'ریال',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
