import 'package:flutter/material.dart';

import '../../models/advance_payment.dart';
import '../../models/employee.dart';
import '../../services/advance_service.dart';
import '../../services/employee_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/persian_date_picker.dart';
import '../../widgets/persian_number_field.dart';

class AdvanceFormScreen extends StatefulWidget {
  final AdvancePayment? advance;

  const AdvanceFormScreen({super.key, this.advance});

  @override
  State<AdvanceFormScreen> createState() => _AdvanceFormScreenState();
}

class _AdvanceFormScreenState extends State<AdvanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _advanceService = AdvanceService();
  final _employeeService = EmployeeService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _loading = true;
  bool _saving = false;

  late final TextEditingController _dateCtrl;
  late final TextEditingController _notesCtrl;
  double _amount = 0;

  @override
  void initState() {
    super.initState();
    final advance = widget.advance;
    _amount = advance?.amount ?? 0;
    _dateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(
        advance?.paymentDate ?? PersianDateHelper.todayText(),
      ),
    );
    _notesCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(advance?.notes ?? ''),
    );
    _init();
  }

  Future<void> _init() async {
    _employees = await _employeeService.getAll(
      onlyActive: widget.advance == null,
    );
    if (widget.advance != null) {
      _selectedEmployee = _employees.cast<Employee?>().firstWhere(
        (employee) => employee?.id == widget.advance!.employeeId,
        orElse: () => null,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial =
        PersianDateHelper.parseJalali(
          PersianNumberFormatter.toEnglish(_dateCtrl.text),
        ) ??
        PersianDateHelper.today();
    final selected = await showPersianDatePicker(
      context: context,
      initialDate: initial,
    );
    if (selected == null) return;
    setState(() {
      _dateCtrl.text = PersianNumberFormatter.toPersian(
        PersianDateHelper.formatJalali(selected),
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null || _selectedEmployee!.id == null) return;
    setState(() => _saving = true);
    final advance = AdvancePayment(
      id: widget.advance?.id,
      employeeId: _selectedEmployee!.id!,
      amount: _amount,
      paymentDate: PersianNumberFormatter.toEnglish(_dateCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    try {
      if (widget.advance == null) {
        await _advanceService.insert(advance);
      } else {
        await _advanceService.update(advance);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMessage.from(
              e,
              fallback: 'ذخیره مساعده انجام نشد. اطلاعات را بررسی کنید.',
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 600;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.advance == null ? 'ثبت مساعده جدید' : 'ویرایش مساعده',
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
              (widget.advance != null && _selectedEmployee == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  widget.advance != null
                      ? 'کارمند این مساعده حذف شده است و امکان ویرایش مساعده وجود ندارد.'
                      : 'ابتدا حداقل یک کارمند فعال ثبت کنید',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_isMobile ? 12 : 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(
                          context: context,
                          title: 'کارمند',
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
                                    (employee) => DropdownMenuItem(
                                      value: employee,
                                      child: Text(
                                        '${PersianNumberFormatter.toPersian(employee.personnelCode.toString())} - ${employee.fullName}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: widget.advance == null
                                  ? (value) => setState(
                                      () => _selectedEmployee = value,
                                    )
                                  : null,
                              validator: (value) => value == null
                                  ? 'انتخاب کارمند الزامی است'
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _section(
                          context: context,
                          title: 'مبلغ و تاریخ',
                          icon: Icons.payments_rounded,
                          accent: AppTheme.warningColor,
                          children: [
                            PersianNumberField(
                              label: 'مبلغ مساعده (ریال) *',
                              isCurrency: true,
                              prefixIcon: Icons.attach_money_rounded,
                              initialValue: _amount,
                              onChanged: (value) =>
                                  _amount = value?.toDouble() ?? 0,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'مبلغ الزامی است';
                                }
                                final parsed =
                                    PersianNumberFormatter.parseNumber(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'مبلغ نامعتبر است';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dateCtrl,
                              readOnly: true,
                              onTap: _pickDate,
                              inputFormatters: const [
                                PersianDateInputFormatter(),
                              ],
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'تاریخ پرداخت *',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                suffixIcon: Icon(Icons.edit_calendar_rounded),
                                hintText: 'سال/ماه/روز',
                              ),
                              validator: (value) {
                                final raw = PersianNumberFormatter.toEnglish(
                                  value?.trim() ?? '',
                                );
                                if (raw.isEmpty) return 'تاریخ الزامی است';
                                return PersianDateHelper.parseJalali(raw) ==
                                        null
                                    ? 'تاریخ نامعتبر است'
                                    : null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _section(
                          context: context,
                          title: 'توضیحات',
                          icon: Icons.notes_rounded,
                          accent: scheme.tertiary,
                          children: [
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 3,
                              inputFormatters: const [
                                PersianDigitsInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'توضیحات اختیاری',
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Responsive.of(context).isCompact
                            ? Column(
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
                                      widget.advance == null
                                          ? 'ثبت مساعده'
                                          : 'ذخیره تغییرات',
                                    ),
                                  ),
                                ],
                              )
                            : Row(
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
                                        widget.advance == null
                                            ? 'ثبت مساعده'
                                            : 'ذخیره تغییرات',
                                      ),
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

  Widget _section({
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
}
