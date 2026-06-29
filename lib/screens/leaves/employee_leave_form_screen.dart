import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/employee_leave.dart';
import '../../services/employee_leave_service.dart';
import '../../services/employee_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/persian_date_picker.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/persian_number_field.dart';

class EmployeeLeaveFormScreen extends StatefulWidget {
  final EmployeeLeave? leave;

  const EmployeeLeaveFormScreen({super.key, this.leave});

  @override
  State<EmployeeLeaveFormScreen> createState() =>
      _EmployeeLeaveFormScreenState();
}

class _EmployeeLeaveFormScreenState extends State<EmployeeLeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _leaveService = EmployeeLeaveService();
  final _employeeService = EmployeeService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _loading = true;
  bool _saving = false;

  late final TextEditingController _fromDateCtrl;
  late final TextEditingController _toDateCtrl;
  late final TextEditingController _notesCtrl;

  double _days = 0;
  String _type = EmployeeLeave.typeAnnual;
  String _status = EmployeeLeave.statusApproved;

  @override
  void initState() {
    super.initState();
    final leave = widget.leave;
    _days = leave?.days ?? 1;
    _type = leave?.normalizedType ?? EmployeeLeave.typeAnnual;
    _status = leave?.normalizedStatus ?? EmployeeLeave.statusApproved;
    final initialDate = leave?.fromDate ?? PersianDateHelper.todayText();
    _fromDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(initialDate),
    );
    _toDateCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(leave?.toDate ?? initialDate),
    );
    _notesCtrl = TextEditingController(
      text: PersianNumberFormatter.toPersian(leave?.notes ?? ''),
    );
    _init();
  }

  Future<void> _init() async {
    _employees = await _employeeService.getAll(
      onlyActive: widget.leave == null,
    );
    if (widget.leave != null) {
      _selectedEmployee = _employees.cast<Employee?>().firstWhere(
        (employee) => employee?.id == widget.leave!.employeeId,
        orElse: () => null,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial =
        PersianDateHelper.parseJalali(
          PersianNumberFormatter.toEnglish(controller.text),
        ) ??
        PersianDateHelper.today();
    final selected = await showPersianDatePicker(
      context: context,
      initialDate: initial,
    );
    if (selected == null) return;
    setState(() {
      controller.text = PersianNumberFormatter.toPersian(
        PersianDateHelper.formatJalali(selected),
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null || _selectedEmployee!.id == null) return;

    final fromDate = PersianNumberFormatter.toEnglish(
      _fromDateCtrl.text.trim(),
    );
    final toDate = PersianNumberFormatter.toEnglish(_toDateCtrl.text.trim());
    final from = PersianDateHelper.parseJalali(fromDate);
    final to = PersianDateHelper.parseJalali(toDate);
    if (from == null ||
        to == null ||
        to.toDateTime().isBefore(from.toDateTime())) {
      _showError('بازه تاریخ مرخصی معتبر نیست.');
      return;
    }

    setState(() => _saving = true);
    final leave = EmployeeLeave(
      id: widget.leave?.id,
      employeeId: _selectedEmployee!.id!,
      fromDate: fromDate,
      toDate: toDate,
      days: _days,
      type: _type,
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      if (widget.leave == null) {
        await _leaveService.insert(leave);
      } else {
        await _leaveService.update(leave);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(
        AppErrorMessage.from(
          e,
          fallback: 'ذخیره مرخصی انجام نشد. اطلاعات را بررسی کنید.',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leave == null ? 'ثبت مرخصی جدید' : 'ویرایش مرخصی'),
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
              (widget.leave != null && _selectedEmployee == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  widget.leave != null
                      ? 'کارمند این مرخصی حذف شده است و امکان ویرایش مرخصی وجود ندارد.'
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
                    constraints: const BoxConstraints(maxWidth: 820),
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
                              onChanged: widget.leave == null
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
                          title: 'نوع و مدت',
                          icon: Icons.beach_access_rounded,
                          accent: AppTheme.warningColor,
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: EmployeeLeave.typeAnnual,
                                  icon: Icon(Icons.beach_access_rounded),
                                  label: Text('استحقاقی'),
                                ),
                                ButtonSegment(
                                  value: EmployeeLeave.typeSick,
                                  icon: Icon(Icons.medical_services_rounded),
                                  label: Text('استعلاجی'),
                                ),
                              ],
                              selected: {_type},
                              onSelectionChanged: (values) =>
                                  setState(() => _type = values.first),
                            ),
                            const SizedBox(height: 12),
                            PersianNumberField(
                              label: 'مدت مرخصی *',
                              suffix: 'روز',
                              prefixIcon: Icons.timelapse_rounded,
                              initialValue: _days,
                              maxDecimalDigits: 1,
                              onChanged: (value) =>
                                  _days = value?.toDouble() ?? 0,
                              validator: (value) {
                                final parsed =
                                    PersianNumberFormatter.parseNumber(
                                      value ?? '',
                                    );
                                if (parsed == null || parsed <= 0) {
                                  return 'مدت مرخصی معتبر نیست';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('لحاظ در محاسبه حقوق'),
                              value: _status == EmployeeLeave.statusApproved,
                              onChanged: (value) => setState(() {
                                _status = value
                                    ? EmployeeLeave.statusApproved
                                    : EmployeeLeave.statusPending;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _section(
                          context: context,
                          title: 'تاریخ',
                          icon: Icons.event_rounded,
                          accent: scheme.tertiary,
                          children: [
                            _dateField(
                              controller: _fromDateCtrl,
                              label: 'از تاریخ *',
                              onTap: () => _pickDate(_fromDateCtrl),
                            ),
                            const SizedBox(height: 12),
                            _dateField(
                              controller: _toDateCtrl,
                              label: 'تا تاریخ *',
                              onTap: () => _pickDate(_toDateCtrl),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _section(
                          context: context,
                          title: 'توضیحات',
                          icon: Icons.notes_rounded,
                          accent: scheme.secondary,
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
                                children: _actions(),
                              )
                            : Row(
                                children: [
                                  Expanded(child: _actions()[0]),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 2, child: _actions()[1]),
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

  List<Widget> _actions() => [
    OutlinedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close_rounded),
      label: const Text('انصراف'),
    ),
    FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: const Icon(Icons.save_rounded),
      label: Text(widget.leave == null ? 'ثبت مرخصی' : 'ذخیره تغییرات'),
    ),
  ];

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: false,
      onTap: onTap,
      keyboardType: TextInputType.datetime,
      enableInteractiveSelection: true,
      inputFormatters: const [PersianDateInputFormatter()],
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        suffixIcon: const Icon(Icons.edit_calendar_rounded),
        hintText: 'سال/ماه/روز',
      ),
      validator: (value) {
        final raw = PersianNumberFormatter.toEnglish(value?.trim() ?? '');
        if (raw.isEmpty) return 'تاریخ الزامی است';
        return PersianDateHelper.parseJalali(raw) == null
            ? 'تاریخ معتبر نیست'
            : null;
      },
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
