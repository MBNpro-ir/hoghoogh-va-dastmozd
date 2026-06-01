import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/loan.dart';
import '../../services/employee_service.dart';
import '../../services/loan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_number_formatter.dart';
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
      text: l != null ? PersianNumberFormatter.toPersian(l.totalInstallments.toString()) : '',
    );
    _paidCtrl = TextEditingController(
      text: l != null ? PersianNumberFormatter.toPersian(l.paidInstallments.toString()) : '0',
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
        PersianNumberFormatter.toEnglish(_installmentsCtrl.text).trim());
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

    final totalInstallments = int.tryParse(
            PersianNumberFormatter.toEnglish(_installmentsCtrl.text).trim()) ??
        0;
    final paidInstallments = int.tryParse(
            PersianNumberFormatter.toEnglish(_paidCtrl.text).trim()) ??
        0;

    // اگر وام جدید است، خودکار شماره وام را تنظیم کن
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loan == null ? 'افزودن وام جدید' : 'ویرایش وام'),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
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
      body: _employees.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'ابتدا حداقل یک کارمند ثبت کنید',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text('انتخاب کارمند',
                                        style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                                const Divider(height: 24),
                                DropdownButtonFormField<Employee>(
                                  initialValue: _selectedEmployee,
                                  decoration: const InputDecoration(
                                    labelText: 'کارمند *',
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                  items: _employees
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              '${PersianNumberFormatter.toPersian(e.personnelCode.toString())} - ${e.fullName}',
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedEmployee = v),
                                  validator: (v) =>
                                      v == null ? 'انتخاب کارمند الزامی است' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.payments, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text('مبلغ و اقساط',
                                        style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                                const Divider(height: 24),
                                PersianNumberField(
                                  label: 'مبلغ وام (ریال) *',
                                  isCurrency: true,
                                  prefixIcon: Icons.attach_money,
                                  initialValue: _amount,
                                  onChanged: (v) {
                                    _amount = v?.toDouble() ?? 0;
                                    _autoCalculateInstallment();
                                  },
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'الزامی است' : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _installmentsCtrl,
                                        textDirection: TextDirection.ltr,
                                        decoration: const InputDecoration(
                                          labelText: 'تعداد کل اقساط *',
                                          prefixIcon: Icon(Icons.numbers),
                                        ),
                                        onChanged: (_) => _autoCalculateInstallment(),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'الزامی است';
                                          }
                                          final num = int.tryParse(
                                              PersianNumberFormatter.toEnglish(v).trim());
                                          if (num == null || num <= 0) {
                                            return 'عدد نامعتبر';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _paidCtrl,
                                        textDirection: TextDirection.ltr,
                                        decoration: const InputDecoration(
                                          labelText: 'اقساط پرداخت شده',
                                          prefixIcon: Icon(Icons.done),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                PersianNumberField(
                                  key: ValueKey('inst_$_installmentAmount'),
                                  label: 'مبلغ هر قسط (ریال) *',
                                  isCurrency: true,
                                  prefixIcon: Icons.calculate,
                                  initialValue: _installmentAmount,
                                  onChanged: (v) =>
                                      setState(() => _installmentAmount = v?.toDouble() ?? 0),
                                ),
                                const SizedBox(height: 8),
                                if (_amount > 0 && _installmentAmount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _summaryRow('مبلغ وام:', _amount),
                                        _summaryRow('جمع اقساط:',
                                            _installmentAmount * (int.tryParse(PersianNumberFormatter.toEnglish(_installmentsCtrl.text).trim()) ?? 0)),
                                        _summaryRow(
                                            'پرداخت‌شده تاکنون:',
                                            _installmentAmount *
                                                (int.tryParse(PersianNumberFormatter.toEnglish(_paidCtrl.text).trim()) ?? 0)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text('تاریخ و توضیحات',
                                        style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                                const Divider(height: 24),
                                TextFormField(
                                  controller: _startDateCtrl,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    labelText: 'تاریخ شروع وام (شمسی) *',
                                    prefixIcon: Icon(Icons.calendar_today),
                                    hintText: '1405/01/01',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'الزامی است' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _notesCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'توضیحات (اختیاری)',
                                    prefixIcon: Icon(Icons.notes),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  title: const Text('وام فعال (در حال کسر از حقوق)'),
                                  value: _isActive,
                                  onChanged: (v) => setState(() => _isActive = v),
                                  activeThumbColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                label: const Text('انصراف'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: const Icon(Icons.save),
                                label: Text(widget.loan == null
                                    ? 'افزودن وام'
                                    : 'ذخیره تغییرات'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _summaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          CurrencyText(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 4),
          const Text('ریال', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
