import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/persian_number_field.dart';

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
  late TextEditingController _installmentsCtrl;
  late TextEditingController _paidCtrl;

  double _amount = 0;
  double _installmentAmount = 0;
  int _loanNumber = 1;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    _startDateCtrl = TextEditingController(text: l?.startDate ?? '1405/01/01');
    _notesCtrl = TextEditingController(text: l?.notes ?? '');
    _installmentsCtrl = TextEditingController(
      text: l != null
          ? PersianNumberFormatter.toPersian(l.totalInstallments.toString())
          : '',
    );
    _paidCtrl = TextEditingController(
      text: l != null
          ? PersianNumberFormatter.toPersian(l.paidInstallments.toString())
          : '0',
    );
    if (l != null) {
      _amount = l.amount;
      _installmentAmount = l.installmentAmount;
      _loanNumber = l.loanNumber;
      _isActive = l.isActive;
    }
    _init();
  }

  Future<void> _init() async {
    _employees = await _employeeService.getAll(onlyActive: true);
    if (widget.loan != null) {
      _selectedEmployee = _employees.firstWhere(
        (e) => e.id == widget.loan!.employeeId,
        orElse: () => _employees.first,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _notesCtrl.dispose();
    _installmentsCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _autoCalculateInstallment() {
    final installments = int.tryParse(
      PersianNumberFormatter.toEnglish(_installmentsCtrl.text).trim(),
    );
    if (installments != null && installments > 0 && _amount > 0) {
      _installmentAmount = (_amount / installments).roundToDouble();
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      _showError('کارمند را انتخاب کنید');
      return;
    }
    if (_amount <= 0) {
      _showError('مبلغ وام نامعتبر است');
      return;
    }

    setState(() => _saving = true);

    final totalInstallments =
        int.tryParse(
          PersianNumberFormatter.toEnglish(_installmentsCtrl.text).trim(),
        ) ??
        0;
    final paidInstallments =
        int.tryParse(PersianNumberFormatter.toEnglish(_paidCtrl.text).trim()) ??
        0;

    int loanNum = _loanNumber;
    if (widget.loan == null) {
      final existing = await _loanService.getByEmployee(_selectedEmployee!.id!);
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

    try {
      if (widget.loan == null) {
        await _loanService.insert(loan);
      } else {
        await _loanService.update(loan);
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

  Widget _responsiveRow({required bool isMobile, required List<Widget> children}) {
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
      body: _employees.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'ابتدا حداقل یک کارمند ثبت کنید',
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
                              onChanged: (v) =>
                                  setState(() => _selectedEmployee = v),
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
                              onChanged: (v) {
                                _amount = v?.toDouble() ?? 0;
                                _autoCalculateInstallment();
                              },
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _responsiveRow(
                              isMobile: isMobile,
                              children: [
                                TextFormField(
                                  controller: _installmentsCtrl,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    labelText: 'تعداد کل اقساط *',
                                    prefixIcon: Icon(Icons.numbers_rounded),
                                  ),
                                  onChanged: (_) =>
                                      _autoCalculateInstallment(),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'الزامی است';
                                    }
                                    final num = int.tryParse(
                                      PersianNumberFormatter.toEnglish(
                                        v,
                                      ).trim(),
                                    );
                                    if (num == null || num <= 0) {
                                      return 'عدد نامعتبر';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: _paidCtrl,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    labelText: 'اقساط پرداخت شده',
                                    prefixIcon: Icon(Icons.done_rounded),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PersianNumberField(
                              key: ValueKey('inst_$_installmentAmount'),
                              label: 'مبلغ هر قسط (ریال) *',
                              isCurrency: true,
                              prefixIcon: Icons.calculate_rounded,
                              initialValue: _installmentAmount,
                              onChanged: (v) => setState(
                                () => _installmentAmount = v?.toDouble() ?? 0,
                              ),
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
                                      _installmentAmount *
                                          (int.tryParse(
                                                PersianNumberFormatter.toEnglish(
                                                  _installmentsCtrl.text,
                                                ).trim(),
                                              ) ??
                                              0),
                                    ),
                                    _summaryRow(
                                      context,
                                      'پرداخت‌شده تاکنون:',
                                      _installmentAmount *
                                          (int.tryParse(
                                                PersianNumberFormatter.toEnglish(
                                                  _paidCtrl.text,
                                                ).trim(),
                                              ) ??
                                              0),
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
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'تاریخ شروع وام (شمسی) *',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                hintText: '1405/01/01',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 2,
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
