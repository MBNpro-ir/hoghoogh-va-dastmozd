import 'package:flutter/material.dart';

import '../../data/employee_reference_data.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/seniority_helper.dart';

enum _EmployeeGridSection { identity, job, payroll, supplemental }

class EmployeeBatchEntryView extends StatefulWidget {
  final VoidCallback? onSaved;

  const EmployeeBatchEntryView({super.key, this.onSaved});

  @override
  State<EmployeeBatchEntryView> createState() => _EmployeeBatchEntryViewState();
}

class _EmployeeBatchEntryViewState extends State<EmployeeBatchEntryView> {
  final _employeeService = EmployeeService();
  final _sync = SyncService();
  final _horizontalScroll = ScrollController();
  final _verticalScroll = ScrollController();
  final List<_EmployeeDraft> _drafts = [];

  List<Employee> _existingEmployees = const [];
  _EmployeeGridSection _section = _EmployeeGridSection.identity;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addRows(6, notify: false);
    _loadExisting();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _horizontalScroll.dispose();
    _verticalScroll.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final employees = await _employeeService.getAll();
    if (!mounted) return;
    setState(() {
      _existingEmployees = employees;
      _loading = false;
    });
  }

  void _addRows(int count, {bool notify = true}) {
    void add() {
      _drafts.addAll(List.generate(count, (_) => _EmployeeDraft()));
    }

    if (notify) {
      setState(add);
    } else {
      add();
    }
  }

  void _removeRow(int index) {
    if (_drafts.length == 1) {
      _drafts.first.clear();
      setState(() {});
      return;
    }
    final removed = _drafts.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _clearGrid() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts
      ..clear()
      ..addAll(List.generate(6, (_) => _EmployeeDraft()));
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    final existingCodes = _existingEmployees
        .map((employee) => employee.personnelCode)
        .toSet();
    final existingNationalIds = _existingEmployees
        .map((employee) => _EmployeeDraft._digits(employee.nationalId))
        .where((value) => value.isNotEmpty)
        .toSet();
    final seenCodes = <int>{};
    final seenNationalIds = <String>{};
    final employees = <Employee>[];
    var invalidRows = 0;

    for (final draft in _drafts) {
      draft.errors = [];
      if (!draft.hasData) continue;
      draft.errors = draft.validate(
        existingCodes: existingCodes,
        existingNationalIds: existingNationalIds,
        seenCodes: seenCodes,
        seenNationalIds: seenNationalIds,
      );
      if (draft.errors.isEmpty) {
        employees.add(draft.toEmployee());
      } else {
        invalidRows++;
      }
    }
    setState(() {});

    if (employees.isEmpty && invalidRows == 0) {
      _message('حداقل یک ردیف کارمند وارد کنید', isError: true);
      return;
    }
    if (invalidRows > 0) {
      _message(
        '$invalidRows ردیف نیاز به اصلاح دارد. علامت قرمز هر ردیف را بررسی کنید.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _employeeService.insertMany(employees);
      await _loadExisting();
      if (!mounted) return;
      final snapshot = _sync.status.value;
      final synced =
          snapshot.pendingCount == 0 && snapshot.phase == SyncPhase.synced;
      _clearGrid();
      widget.onSaved?.call();
      _message(
        synced
            ? '${employees.length} کارمند ثبت و با سرور همگام شد'
            : '${employees.length} کارمند ثبت شد؛ همگام‌سازی با سرور در پس‌زمینه ادامه دارد',
      );
    } catch (error) {
      final message = error is ArgumentError
          ? error.message?.toString() ?? error.toString()
          : error.toString();
      _message('ثبت گروهی انجام نشد: $message', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final scheme = Theme.of(context).colorScheme;
    final invalidCount = _drafts
        .where((draft) => draft.errors.isNotEmpty)
        .length;
    final filledCount = _drafts.where((draft) => draft.hasData).length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(scheme, filledCount, invalidCount),
          const SizedBox(height: 10),
          _sectionPicker(),
          if (invalidCount > 0) ...[
            const SizedBox(height: 10),
            _validationBanner(scheme),
          ],
          const SizedBox(height: 10),
          Expanded(child: _grid(scheme)),
          if (_saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _toolbar(ColorScheme scheme, int filledCount, int invalidCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.table_view_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ثبت ستونی کارکنان',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'ردیف پرشده: $filledCount'
                    '${invalidCount > 0 ? '  |  نیازمند اصلاح: $invalidCount' : ''}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _saving ? null : () => _addRows(5),
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('۵ ردیف جدید'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _clearGrid,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('پاک کردن'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('ثبت و همگام‌سازی'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_EmployeeGridSection>(
        segments: const [
          ButtonSegment(
            value: _EmployeeGridSection.identity,
            icon: Icon(Icons.badge_rounded),
            label: Text('اطلاعات هویتی'),
          ),
          ButtonSegment(
            value: _EmployeeGridSection.job,
            icon: Icon(Icons.work_rounded),
            label: Text('شغلی و استخدامی'),
          ),
          ButtonSegment(
            value: _EmployeeGridSection.payroll,
            icon: Icon(Icons.payments_rounded),
            label: Text('حقوق و مزایا'),
          ),
          ButtonSegment(
            value: _EmployeeGridSection.supplemental,
            icon: Icon(Icons.account_balance_rounded),
            label: Text('بانکی و تکمیلی'),
          ),
        ],
        selected: {_section},
        onSelectionChanged: (values) => setState(() => _section = values.first),
      ),
    );
  }

  Widget _validationBanner(ColorScheme scheme) {
    final errors = <String>[];
    for (var i = 0; i < _drafts.length; i++) {
      if (_drafts[i].errors.isEmpty) continue;
      errors.add('ردیف ${i + 1}: ${_drafts[i].errors.join(' ، ')}');
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        errors.take(4).join('\n'),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }

  Widget _grid(ColorScheme scheme) {
    final columns = _columnsForSection();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => Scrollbar(
          controller: _horizontalScroll,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 10,
          radius: const Radius.circular(5),
          scrollbarOrientation: ScrollbarOrientation.bottom,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Scrollbar(
                controller: _verticalScroll,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                thickness: 10,
                radius: const Radius.circular(5),
                scrollbarOrientation: ScrollbarOrientation.right,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  controller: _verticalScroll,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DataTable(
                      headingRowHeight: 52,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      columns: [
                        const DataColumn(
                          label: SizedBox(width: 88, child: Text('ردیف')),
                        ),
                        for (final column in columns)
                          DataColumn(
                            label: SizedBox(
                              width: column.width,
                              child: Text(
                                column.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                      rows: [
                        for (var index = 0; index < _drafts.length; index++)
                          _dataRow(index, _drafts[index], columns, scheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _dataRow(
    int index,
    _EmployeeDraft draft,
    List<_EmployeeGridColumn> columns,
    ColorScheme scheme,
  ) {
    return DataRow(
      color: WidgetStatePropertyAll(
        draft.errors.isEmpty
            ? null
            : scheme.errorContainer.withValues(alpha: 0.28),
      ),
      cells: [
        DataCell(
          SizedBox(
            width: 88,
            child: Row(
              children: [
                Text('${index + 1}'),
                if (draft.errors.isNotEmpty)
                  Tooltip(
                    message: draft.errors.join('\n'),
                    child: Icon(
                      Icons.error_rounded,
                      color: scheme.error,
                      size: 18,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'حذف ردیف',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _saving ? null : () => _removeRow(index),
                ),
              ],
            ),
          ),
        ),
        for (final column in columns) DataCell(column.builder(draft)),
      ],
    );
  }

  List<_EmployeeGridColumn> _columnsForSection() {
    return switch (_section) {
      _EmployeeGridSection.identity => [
        _textColumn('کد پرسنلی *', 110, (d) => d.personnelCode, numeric: true),
        _textColumn('نام *', 140, (d) => d.firstName),
        _textColumn('نام خانوادگی *', 160, (d) => d.lastName),
        _textColumn('کد ملی *', 130, (d) => d.nationalId, numeric: true),
        _textColumn('نام پدر', 140, (d) => d.fatherName),
        _textColumn('شماره شناسنامه', 140, (d) => d.birthCertificateNumber),
        _choiceColumn(
          'جنس',
          100,
          (d) => d.gender,
          EmployeeReferenceData.genders,
          (d, value) => d.gender = value,
        ),
        _textColumn('تاریخ تولد', 130, (d) => d.birthDate, hint: '1400/01/01'),
        _textColumn('محل تولد', 150, (d) => d.birthPlace),
      ],
      _EmployeeGridSection.job => [
        _textColumn('تلفن', 140, (d) => d.phone, numeric: true),
        _textColumn('محل خدمت', 180, (d) => d.workplace),
        _textColumn('کد شغل', 120, (d) => d.jobCode),
        _textColumn('عنوان شغل', 190, (d) => d.jobTitle),
        _textColumn('سمت', 160, (d) => d.position),
        _textColumn(
          'تاریخ شروع *',
          130,
          (d) => d.startDate,
          hint: '1405/01/01',
        ),
        _choiceColumn(
          'نوع استخدام',
          130,
          (d) => d.employmentType,
          EmployeeReferenceData.employmentTypes,
          (d, value) => d.employmentType = value,
        ),
        _boolColumn(
          'فعال',
          90,
          (d) => d.isActive,
          (d, value) => d.isActive = value,
        ),
        _textColumn('تاریخ ترک کار', 130, (d) => d.endDate, hint: '1405/12/29'),
        _boolColumn(
          'دارای سابقه',
          120,
          (d) => d.hasPriorExperience,
          (d, value) => d.hasPriorExperience = value,
        ),
        _boolColumn(
          'متاهل',
          90,
          (d) => d.isMarried,
          (d, value) => d.isMarried = value,
        ),
        _textColumn('تعداد فرزند', 110, (d) => d.childrenCount, numeric: true),
      ],
      _EmployeeGridSection.payroll => [
        _textColumn(
          'دستمزد روزانه ۱۴۰۴',
          160,
          (d) => d.dailyWage1404,
          numeric: true,
        ),
        _textColumn(
          'دستمزد روزانه ۱۴۰۵',
          160,
          (d) => d.dailyWage1405,
          numeric: true,
        ),
        _textColumn(
          'حقوق پایه ۳۰ روز',
          160,
          (d) => d.baseSalary30Days,
          numeric: true,
        ),
        _textColumn(
          'مسکن روزانه',
          150,
          (d) => d.dailyHousing,
          numeric: true,
          hint: '1000000',
        ),
        _textColumn(
          'خواروبار روزانه',
          160,
          (d) => d.dailyFood,
          numeric: true,
          hint: '733333',
        ),
        _textColumn(
          'حق تاهل روزانه',
          160,
          (d) => d.dailyMarriage,
          numeric: true,
        ),
        _textColumn(
          'حق فرزند روزانه',
          170,
          (d) => d.dailyChildAllowance,
          numeric: true,
          hint: '554185',
        ),
        _textColumn(
          'سنوات روزانه',
          150,
          (d) => d.dailySeniority,
          numeric: true,
        ),
        _textColumn(
          'سایر مزایای روزانه',
          170,
          (d) => d.otherBenefitsDaily,
          numeric: true,
        ),
        _textColumn(
          'ساعت مزایای ساعتی',
          170,
          (d) => d.hourlyBenefits,
          numeric: true,
        ),
        _textColumn(
          'سنوات سال قبل',
          150,
          (d) => d.lastYearSeniority,
          numeric: true,
        ),
      ],
      _EmployeeGridSection.supplemental => [
        _textColumn('نام بانک', 170, (d) => d.bankName),
        _textColumn('نوع حساب', 150, (d) => d.bankAccountType),
        _textColumn(
          'شماره حساب',
          170,
          (d) => d.bankAccountNumber,
          numeric: true,
        ),
        _textColumn('شماره کارت', 180, (d) => d.cardNumber, numeric: true),
        _textColumn('شماره بیمه', 150, (d) => d.insuranceNumber, numeric: true),
        _textColumn('تحصیلات', 150, (d) => d.education),
        _textColumn('آدرس', 240, (d) => d.address),
        _boolColumn(
          'سخت و زیان‌آور',
          140,
          (d) => d.hardAndHarmfulJob,
          (d, value) => d.hardAndHarmfulJob = value,
        ),
        _textColumn('توضیح انتهای فیش', 220, (d) => d.payslipFooterNote),
        _textColumn('یادداشت', 220, (d) => d.notes),
      ],
    };
  }

  _EmployeeGridColumn _textColumn(
    String label,
    double width,
    TextEditingController Function(_EmployeeDraft) controller, {
    bool numeric = false,
    String? hint,
  }) {
    return _EmployeeGridColumn(
      label: label,
      width: width,
      builder: (draft) => SizedBox(
        width: width,
        child: TextField(
          controller: controller(draft),
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
          textAlign: numeric ? TextAlign.left : TextAlign.right,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
          ),
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
      ),
    );
  }

  _EmployeeGridColumn _choiceColumn(
    String label,
    double width,
    String Function(_EmployeeDraft) value,
    List<String> items,
    void Function(_EmployeeDraft, String) onChanged,
  ) {
    return _EmployeeGridColumn(
      label: label,
      width: width,
      builder: (draft) => SizedBox(
        width: width,
        child: DropdownButtonFormField<String>(
          key: ValueKey('${identityHashCode(draft)}-$label'),
          initialValue: value(draft),
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(draft, next);
          },
        ),
      ),
    );
  }

  _EmployeeGridColumn _boolColumn(
    String label,
    double width,
    bool Function(_EmployeeDraft) value,
    void Function(_EmployeeDraft, bool) onChanged,
  ) {
    return _EmployeeGridColumn(
      label: label,
      width: width,
      builder: (draft) => SizedBox(
        width: width,
        child: DropdownButtonFormField<bool>(
          key: ValueKey('${identityHashCode(draft)}-$label'),
          initialValue: value(draft),
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: const [
            DropdownMenuItem(value: true, child: Text('بله')),
            DropdownMenuItem(value: false, child: Text('خیر')),
          ],
          onChanged: (next) {
            if (next != null) onChanged(draft, next);
          },
        ),
      ),
    );
  }
}

class _EmployeeGridColumn {
  final String label;
  final double width;
  final Widget Function(_EmployeeDraft draft) builder;

  const _EmployeeGridColumn({
    required this.label,
    required this.width,
    required this.builder,
  });
}

class _EmployeeDraft {
  final personnelCode = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final nationalId = TextEditingController();
  final fatherName = TextEditingController();
  final birthCertificateNumber = TextEditingController();
  final workplace = TextEditingController();
  final bankName = TextEditingController();
  final bankAccountType = TextEditingController();
  final bankAccountNumber = TextEditingController();
  final jobCode = TextEditingController();
  final jobTitle = TextEditingController();
  final birthDate = TextEditingController();
  final birthPlace = TextEditingController();
  final phone = TextEditingController();
  final childrenCount = TextEditingController();
  final lastYearSeniority = TextEditingController();
  final baseSalary30Days = TextEditingController();
  final dailyWage1405 = TextEditingController();
  final dailyWage1404 = TextEditingController();
  final dailyHousing = TextEditingController();
  final dailyFood = TextEditingController();
  final dailyMarriage = TextEditingController();
  final dailyChildAllowance = TextEditingController();
  final dailySeniority = TextEditingController();
  final otherBenefitsDaily = TextEditingController();
  final hourlyBenefits = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();
  final cardNumber = TextEditingController();
  final insuranceNumber = TextEditingController();
  final education = TextEditingController();
  final position = TextEditingController();
  final address = TextEditingController();
  final payslipFooterNote = TextEditingController();
  final notes = TextEditingController();

  String gender = EmployeeReferenceData.genders.first;
  String employmentType = EmployeeReferenceData.employmentTypes.first;
  bool hasPriorExperience = true;
  bool isMarried = false;
  bool isActive = true;
  bool hardAndHarmfulJob = false;
  List<String> errors = [];

  List<TextEditingController> get _controllers => [
    personnelCode,
    firstName,
    lastName,
    nationalId,
    fatherName,
    birthCertificateNumber,
    workplace,
    bankName,
    bankAccountType,
    bankAccountNumber,
    jobCode,
    jobTitle,
    birthDate,
    birthPlace,
    phone,
    childrenCount,
    lastYearSeniority,
    baseSalary30Days,
    dailyWage1405,
    dailyWage1404,
    dailyHousing,
    dailyFood,
    dailyMarriage,
    dailyChildAllowance,
    dailySeniority,
    otherBenefitsDaily,
    hourlyBenefits,
    startDate,
    endDate,
    cardNumber,
    insuranceNumber,
    education,
    position,
    address,
    payslipFooterNote,
    notes,
  ];

  bool get hasData =>
      _controllers.any((controller) => controller.text.trim().isNotEmpty);

  List<String> validate({
    required Set<int> existingCodes,
    required Set<String> existingNationalIds,
    required Set<int> seenCodes,
    required Set<String> seenNationalIds,
  }) {
    final result = <String>[];
    final code = _int(personnelCode.text);
    if (code == null || code <= 0) {
      result.add('کد پرسنلی نامعتبر است');
    } else if (existingCodes.contains(code) || !seenCodes.add(code)) {
      result.add('کد پرسنلی تکراری است');
    }
    if (firstName.text.trim().isEmpty) result.add('نام الزامی است');
    if (lastName.text.trim().isEmpty) result.add('نام خانوادگی الزامی است');

    final national = _digits(nationalId.text);
    if (national.length != 10) {
      result.add('کد ملی باید ۱۰ رقم باشد');
    } else if (existingNationalIds.contains(national) ||
        !seenNationalIds.add(national)) {
      result.add('کد ملی تکراری است');
    }

    final start = _text(startDate);
    if (SeniorityHelper.parseStartDate(start) == null) {
      result.add('تاریخ شروع به کار نامعتبر است');
    }
    final birth = _text(birthDate);
    if (birth.isNotEmpty && SeniorityHelper.parseStartDate(birth) == null) {
      result.add('تاریخ تولد نامعتبر است');
    }
    final end = _text(endDate);
    if (end.isNotEmpty && SeniorityHelper.parseStartDate(end) == null) {
      result.add('تاریخ ترک کار نامعتبر است');
    }
    if (!isActive && _text(endDate).isEmpty) {
      result.add('برای کارمند غیرفعال تاریخ ترک کار الزامی است');
    }

    for (final field in <(String, TextEditingController)>[
      ('تعداد فرزند', childrenCount),
      ('سنوات سال قبل', lastYearSeniority),
      ('حقوق پایه', baseSalary30Days),
      ('دستمزد ۱۴۰۵', dailyWage1405),
      ('دستمزد ۱۴۰۴', dailyWage1404),
      ('مسکن', dailyHousing),
      ('خواروبار', dailyFood),
      ('حق تاهل', dailyMarriage),
      ('حق فرزند', dailyChildAllowance),
      ('سنوات', dailySeniority),
      ('سایر مزایا', otherBenefitsDaily),
      ('مزایای ساعتی', hourlyBenefits),
    ]) {
      if (field.$2.text.trim().isEmpty) continue;
      final value = _number(field.$2.text);
      if (value == null) {
        result.add('${field.$1} عدد معتبری نیست');
      } else if (value < 0) {
        result.add('${field.$1} نمی‌تواند منفی باشد');
      }
    }
    return result;
  }

  Employee toEmployee() => Employee(
    personnelCode: _int(personnelCode.text)!,
    firstName: firstName.text.trim(),
    lastName: lastName.text.trim(),
    nationalId: _digits(nationalId.text),
    fatherName: fatherName.text.trim(),
    birthCertificateNumber: _digits(birthCertificateNumber.text),
    gender: gender,
    workplace: workplace.text.trim(),
    bankName: bankName.text.trim(),
    bankAccountType: bankAccountType.text.trim(),
    bankAccountNumber: _digits(bankAccountNumber.text),
    jobCode: _text(jobCode),
    jobTitle: jobTitle.text.trim(),
    birthDate: _text(birthDate),
    birthPlace: birthPlace.text.trim(),
    phone: _digits(phone.text),
    hasPriorExperience: hasPriorExperience,
    isMarried: isMarried,
    childrenCount: _int(childrenCount.text) ?? 0,
    lastYearSeniority: _number(lastYearSeniority.text) ?? 0,
    baseSalary30Days: _number(baseSalary30Days.text) ?? 0,
    dailyWage1405: _number(dailyWage1405.text) ?? 0,
    dailyWage1404: _number(dailyWage1404.text) ?? 0,
    dailyHousing: _number(dailyHousing.text) ?? 1000000,
    dailyFood: _number(dailyFood.text) ?? 733333,
    dailyMarriage: _number(dailyMarriage.text) ?? 0,
    dailyChildAllowance: _number(dailyChildAllowance.text) ?? 554185,
    dailySeniority: _number(dailySeniority.text) ?? 0,
    otherBenefitsDaily: _number(otherBenefitsDaily.text) ?? 0,
    hourlyBenefits: _number(hourlyBenefits.text) ?? 0,
    startDate: _text(startDate),
    isActive: isActive,
    endDate: _text(endDate),
    cardNumber: _digits(cardNumber.text),
    insuranceNumber: _digits(insuranceNumber.text),
    education: education.text.trim(),
    position: position.text.trim(),
    employmentType: employmentType,
    address: address.text.trim(),
    hardAndHarmfulJob: hardAndHarmfulJob,
    payslipFooterNote: payslipFooterNote.text.trim(),
    notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
  );

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    gender = EmployeeReferenceData.genders.first;
    employmentType = EmployeeReferenceData.employmentTypes.first;
    hasPriorExperience = true;
    isMarried = false;
    isActive = true;
    hardAndHarmfulJob = false;
    errors = [];
  }

  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  static String _text(TextEditingController controller) =>
      PersianNumberFormatter.toEnglish(controller.text.trim());

  static String _digits(String value) =>
      PersianNumberFormatter.toEnglish(value).replaceAll(RegExp(r'[^0-9]'), '');

  static String _normalizedNumber(String value) =>
      PersianNumberFormatter.toEnglish(
        value,
      ).replaceAll('٬', '').replaceAll(',', '').trim();

  static int? _int(String value) {
    final normalized = _normalizedNumber(value);
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  static double? _number(String value) {
    final normalized = _normalizedNumber(value);
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}
