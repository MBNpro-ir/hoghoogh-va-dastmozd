import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/employee_reference_data.dart';
import '../../models/app_settings.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../services/salary_calculator.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/app_error_message.dart';
import '../../utils/seniority_helper.dart';
import '../../widgets/app_notification.dart';

enum _EmployeeGridSection {
  identity,
  job,
  payroll,
  monthlyBenefits,
  supplemental,
}

enum _EmployeeEntryMode { manageExisting, createNew }

class EmployeeBatchEntryView extends StatefulWidget {
  final VoidCallback? onSaved;

  const EmployeeBatchEntryView({super.key, this.onSaved});

  @override
  State<EmployeeBatchEntryView> createState() => _EmployeeBatchEntryViewState();
}

class _EmployeeBatchEntryViewState extends State<EmployeeBatchEntryView> {
  static const double _pinnedColumnWidth = 220;
  static const double _pinnedColumnInnerWidth = 204;
  static const double _tableHeaderHeight = 52;
  static const double _tableRowHeight = 64;

  final _employeeService = EmployeeService();
  final _settingsService = SettingsService();
  final _sync = SyncService();
  final _horizontalScroll = ScrollController();
  final _headerHorizontalScroll = ScrollController();
  final _verticalScroll = ScrollController();
  final _pinnedVerticalScroll = ScrollController();
  final List<EmployeeBatchDraft> _drafts = [];
  final Set<int> _deletedEmployeeIds = {};

  List<Employee> _existingEmployees = const [];
  AppSettings? _settings;
  _EmployeeEntryMode? _mode;
  _EmployeeGridSection _section = _EmployeeGridSection.identity;
  int _databaseNextPersonnelCode = 1;
  int _nextPersonnelCode = 1;
  bool _loading = true;
  bool _saving = false;
  bool _syncingHorizontalScroll = false;
  bool _syncingVerticalScroll = false;

  @override
  void initState() {
    super.initState();
    _horizontalScroll.addListener(
      () => _syncHorizontalScroll(_horizontalScroll, _headerHorizontalScroll),
    );
    _headerHorizontalScroll.addListener(
      () => _syncHorizontalScroll(_headerHorizontalScroll, _horizontalScroll),
    );
    _verticalScroll.addListener(
      () => _syncVerticalScroll(_verticalScroll, _pinnedVerticalScroll),
    );
    _pinnedVerticalScroll.addListener(
      () => _syncVerticalScroll(_pinnedVerticalScroll, _verticalScroll),
    );
    _loadExisting();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _horizontalScroll.dispose();
    _headerHorizontalScroll.dispose();
    _verticalScroll.dispose();
    _pinnedVerticalScroll.dispose();
    super.dispose();
  }

  void _syncHorizontalScroll(ScrollController source, ScrollController target) {
    if (_syncingHorizontalScroll) return;
    _syncScrollOffset(
      source: source,
      target: target,
      setSyncing: (value) => _syncingHorizontalScroll = value,
    );
  }

  void _syncVerticalScroll(ScrollController source, ScrollController target) {
    if (_syncingVerticalScroll) return;
    _syncScrollOffset(
      source: source,
      target: target,
      setSyncing: (value) => _syncingVerticalScroll = value,
    );
  }

  void _syncScrollOffset({
    required ScrollController source,
    required ScrollController target,
    required ValueChanged<bool> setSyncing,
  }) {
    if (!source.hasClients || !target.hasClients) return;
    final nextOffset = source.offset
        .clamp(target.position.minScrollExtent, target.position.maxScrollExtent)
        .toDouble();
    if ((target.offset - nextOffset).abs() < 0.5) return;
    setSyncing(true);
    try {
      target.jumpTo(nextOffset);
    } finally {
      setSyncing(false);
    }
  }

  Future<void> _loadExisting({bool pullLatest = true}) async {
    if (pullLatest) await _sync.pullLatest(silent: true);
    final settings = await _settingsService.getCurrentSettings();
    final employees = await _employeeService.getAll();
    final nextPersonnelCode = await _employeeService.getNextPersonnelCode();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _existingEmployees = employees;
      _databaseNextPersonnelCode = nextPersonnelCode;
      _nextPersonnelCode = nextPersonnelCode;
      _loading = false;
    });
  }

  void _selectMode(_EmployeeEntryMode mode) {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts.clear();
    _deletedEmployeeIds.clear();
    _nextPersonnelCode = _databaseNextPersonnelCode;
    if (mode == _EmployeeEntryMode.manageExisting) {
      _drafts.addAll(
        _existingEmployees.map(
          (employee) => EmployeeBatchDraft.fromEmployee(
            employee: employee,
            settings: _settings!,
          ),
        ),
      );
      if (_drafts.isEmpty) _appendRows(1);
    } else {
      _appendRows(6);
    }
    setState(() => _mode = mode);
  }

  EmployeeBatchDraft _createDraft() {
    final settings = _settings!;
    return EmployeeBatchDraft(
      settings: settings,
      personnelCode: _nextPersonnelCode++,
    );
  }

  void _appendRows(int count) {
    _drafts.addAll(List.generate(count, (_) => _createDraft()));
  }

  void _addRows(int count, {bool notify = true}) {
    if (_settings == null) return;

    if (notify) {
      setState(() => _appendRows(count));
    } else {
      _appendRows(count);
    }
  }

  Future<void> _removeRow(int index) async {
    final draft = _drafts[index];
    if (draft.isExisting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('حذف کارمند'),
          content: Text(
            'آیا از حذف «${draft.fullName}» مطمئن هستید؟\n'
            'وام‌ها، مساعده‌ها و فیش‌های حقوق این کارمند نیز حذف خواهند شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('آماده حذف'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _deletedEmployeeIds.add(draft.employeeId!);
    }
    if (_drafts.length == 1 && _mode == _EmployeeEntryMode.createNew) {
      _nextPersonnelCode = _databaseNextPersonnelCode;
      _drafts.first.reset(
        settings: _settings!,
        personnelCode: _nextPersonnelCode++,
      );
      setState(() {});
      return;
    }
    final removed = _drafts.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _resetGrid() => _selectMode(_mode!);

  void _copyRow(int index) {
    final copy = _drafts[index].copyAsNew(
      settings: _settings!,
      personnelCode: _nextPersonnelCode++,
    );
    setState(() => _drafts.insert(index + 1, copy));
  }

  Future<void> _save() async {
    if (_saving) return;
    final representedIds = _drafts
        .map((draft) => draft.employeeId)
        .whereType<int>()
        .toSet();
    final externalEmployees = _existingEmployees.where((employee) {
      final id = employee.id;
      return id == null ||
          (!representedIds.contains(id) && !_deletedEmployeeIds.contains(id));
    }).toList();
    final existingCodes = externalEmployees
        .map((employee) => employee.personnelCode)
        .toSet();
    final existingNationalIds = externalEmployees
        .map((employee) => EmployeeBatchDraft.digits(employee.nationalId))
        .where((value) => value.isNotEmpty)
        .toSet();
    final seenCodes = <int>{};
    final seenNationalIds = <String>{};
    for (final draft in _drafts.where(
      (draft) => draft.isExisting && !draft.touched,
    )) {
      final code = EmployeeBatchDraft.parseInt(draft.personnelCode.text);
      if (code != null) seenCodes.add(code);
      final national = EmployeeBatchDraft.digits(draft.nationalId.text);
      if (national.isNotEmpty) seenNationalIds.add(national);
    }

    final newEmployees = <Employee>[];
    final updatedEmployees = <Employee>[];
    var invalidRows = 0;

    for (final draft in _drafts) {
      draft.errors = [];
      if (!draft.touched) continue;
      draft.errors = draft.validate(
        settings: _settings!,
        existingCodes: existingCodes,
        existingNationalIds: existingNationalIds,
        seenCodes: seenCodes,
        seenNationalIds: seenNationalIds,
      );
      if (draft.errors.isEmpty) {
        if (draft.isExisting) {
          updatedEmployees.add(draft.toEmployee());
        } else {
          newEmployees.add(draft.toEmployee());
        }
      } else {
        invalidRows++;
      }
    }
    setState(() {});

    if (newEmployees.isEmpty &&
        updatedEmployees.isEmpty &&
        _deletedEmployeeIds.isEmpty &&
        invalidRows == 0) {
      _message(
        _mode == _EmployeeEntryMode.manageExisting
            ? 'تغییری برای ذخیره وجود ندارد'
            : 'حداقل یک ردیف کارمند وارد کنید',
        isError: true,
      );
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
      final deletedCount = _deletedEmployeeIds.length;
      await _employeeService.applyBatchChanges(
        newEmployees: newEmployees,
        updatedEmployees: updatedEmployees,
        deletedIds: _deletedEmployeeIds,
      );
      await _loadExisting(pullLatest: false);
      if (!mounted) return;
      final snapshot = _sync.status.value;
      final synced =
          snapshot.pendingCount == 0 && snapshot.phase == SyncPhase.synced;
      final changes = <String>[
        if (newEmployees.isNotEmpty) '${newEmployees.length} ثبت',
        if (updatedEmployees.isNotEmpty) '${updatedEmployees.length} ویرایش',
        if (deletedCount > 0) '$deletedCount حذف',
      ];
      _resetGrid();
      widget.onSaved?.call();
      _message(
        synced
            ? '${changes.join('، ')} انجام و با سرور همگام شد'
            : '${changes.join('، ')} انجام شد؛ همگام‌سازی با سرور در پس‌زمینه ادامه دارد',
      );
    } catch (error) {
      final message = AppErrorMessage.from(
        error,
        fallback: 'ثبت گروهی انجام نشد. ردیف‌ها را بررسی کنید.',
      );
      _message('ثبت گروهی انجام نشد: $message', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppNotification.error(context, message);
    } else {
      AppNotification.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final scheme = Theme.of(context).colorScheme;
    if (_mode == null) return _modePicker(scheme);
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

  Widget _modePicker(ColorScheme scheme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ورود دسته‌ای کارکنان',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _modeCard(
                      scheme: scheme,
                      icon: Icons.manage_accounts_rounded,
                      title: 'نمایش و ویرایش اطلاعات قبلی',
                      subtitle: 'مشاهده، ویرایش، کپی، حذف و افزودن کارکنان',
                      onTap: () =>
                          _selectMode(_EmployeeEntryMode.manageExisting),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _modeCard(
                      scheme: scheme,
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'ثبت اطلاعات جدید',
                      subtitle: 'جدول خالی برای ثبت کارکنان جدید',
                      onTap: () => _selectMode(_EmployeeEntryMode.createNew),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required ColorScheme scheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar(ColorScheme scheme, int filledCount, int invalidCount) {
    final managing = _mode == _EmployeeEntryMode.manageExisting;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'تغییر حالت',
              onPressed: _saving ? null : () => setState(() => _mode = null),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            Icon(Icons.table_view_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    managing
                        ? 'نمایش و ویرایش اطلاعات کارکنان'
                        : 'ثبت ستونی کارکنان جدید',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${managing ? 'تعداد کارکنان: ${_drafts.where((draft) => draft.isExisting).length}' : 'ردیف پرشده: $filledCount'}'
                    '${_deletedEmployeeIds.isNotEmpty ? '  |  آماده حذف: ${_deletedEmployeeIds.length}' : ''}'
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
              onPressed: _saving ? null : _resetGrid,
              icon: Icon(
                managing ? Icons.restart_alt_rounded : Icons.clear_all_rounded,
              ),
              label: Text(managing ? 'بازنشانی تغییرات' : 'پاک کردن'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(managing ? 'ذخیره تغییرات' : 'ثبت و همگام‌سازی'),
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
            label: Text('حقوق و مزایای روزانه'),
          ),
          ButtonSegment(
            value: _EmployeeGridSection.monthlyBenefits,
            icon: Icon(Icons.calendar_month_rounded),
            label: Text('مزایای ماهانه'),
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
        builder: (context, constraints) {
          final bodyWidth = (constraints.maxWidth - _pinnedColumnWidth)
              .clamp(360.0, double.infinity)
              .toDouble();
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pinnedHeader(scheme),
                    SizedBox(
                      width: bodyWidth,
                      height: _tableHeaderHeight,
                      child: _withoutAutomaticScrollbars(
                        child: SingleChildScrollView(
                          controller: _headerHorizontalScroll,
                          scrollDirection: Axis.horizontal,
                          child: _bodyHeader(columns),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pinnedRowsViewport(scheme),
                      SizedBox(
                        width: bodyWidth,
                        child: Scrollbar(
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
                            child: _withoutAutomaticScrollbars(
                              child: SingleChildScrollView(
                                controller: _verticalScroll,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _bodyRows(columns, scheme),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pinnedHeader(ColorScheme scheme) {
    return Container(
      width: _pinnedColumnWidth,
      height: _tableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          left: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: const SizedBox(
        width: _pinnedColumnInnerWidth,
        child: Text(
          'ردیف و نام کارمند',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _pinnedRowsViewport(ColorScheme scheme) {
    return Container(
      width: _pinnedColumnWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Scrollbar(
        controller: _pinnedVerticalScroll,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 10,
        radius: const Radius.circular(5),
        scrollbarOrientation: ScrollbarOrientation.right,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        child: _withoutAutomaticScrollbars(
          child: SingleChildScrollView(
            controller: _pinnedVerticalScroll,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _pinnedRows(scheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _withoutAutomaticScrollbars({required Widget child}) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: child,
    );
  }

  Widget _bodyHeader(List<_EmployeeGridColumn> columns) {
    return DataTable(
      headingRowHeight: _tableHeaderHeight,
      dataRowMinHeight: 0,
      dataRowMaxHeight: 0,
      columnSpacing: 12,
      horizontalMargin: 12,
      columns: [
        for (final column in columns)
          DataColumn(
            label: SizedBox(
              width: column.width,
              child: Text(
                column.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
      rows: const [],
    );
  }

  Widget _bodyRows(List<_EmployeeGridColumn> columns, ColorScheme scheme) {
    return DataTable(
      headingRowHeight: 0,
      dataRowMinHeight: _tableRowHeight,
      dataRowMaxHeight: _tableRowHeight,
      columnSpacing: 12,
      horizontalMargin: 12,
      columns: [
        for (final column in columns)
          DataColumn(label: SizedBox(width: column.width)),
      ],
      rows: [
        for (var index = 0; index < _drafts.length; index++)
          _bodyDataRow(_drafts[index], columns, scheme),
      ],
    );
  }

  Widget _pinnedRows(ColorScheme scheme) {
    return DataTable(
      headingRowHeight: 0,
      dataRowMinHeight: _tableRowHeight,
      dataRowMaxHeight: _tableRowHeight,
      columnSpacing: 0,
      horizontalMargin: 8,
      columns: const [
        DataColumn(label: SizedBox(width: _pinnedColumnInnerWidth)),
      ],
      rows: [
        for (var index = 0; index < _drafts.length; index++)
          _pinnedDataRow(index, _drafts[index], scheme),
      ],
    );
  }

  DataRow _pinnedDataRow(
    int index,
    EmployeeBatchDraft draft,
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
            width: _pinnedColumnInnerWidth,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    PersianNumberFormatter.toPersian('${index + 1}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                if (draft.errors.isNotEmpty)
                  Tooltip(
                    message: draft.errors.join('\n'),
                    child: Icon(
                      Icons.error_rounded,
                      color: scheme.error,
                      size: 18,
                    ),
                  ),
                Expanded(child: _PinnedEmployeeName(draft: draft)),
                IconButton(
                  tooltip: 'کپی ردیف',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 34,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.content_copy_rounded, size: 17),
                  onPressed: _saving ? null : () => _copyRow(index),
                ),
                if (_settings != null &&
                    draft.hasAutomaticDeviation(_settings!))
                  IconButton(
                    tooltip: 'بازگشت مقادیر خودکار',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    onPressed: _saving
                        ? null
                        : () {
                            draft.resetAutomaticPayroll(_settings!);
                            setState(() {});
                          },
                  ),
                IconButton(
                  tooltip: 'حذف ردیف',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 34,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _saving ? null : () => _removeRow(index),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _bodyDataRow(
    EmployeeBatchDraft draft,
    List<_EmployeeGridColumn> columns,
    ColorScheme scheme,
  ) {
    return DataRow(
      color: WidgetStatePropertyAll(
        draft.errors.isEmpty
            ? null
            : scheme.errorContainer.withValues(alpha: 0.28),
      ),
      cells: [for (final column in columns) DataCell(column.builder(draft))],
    );
  }

  List<_EmployeeGridColumn> _columnsForSection() {
    final settings = _settings!;
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
        _dateColumn('تاریخ تولد', 130, (d) => d.birthDate),
        _textColumn('محل تولد', 150, (d) => d.birthPlace),
      ],
      _EmployeeGridSection.job => [
        _textColumn('تلفن', 140, (d) => d.phone, numeric: true),
        _textColumn('محل خدمت', 180, (d) => d.workplace),
        _textColumn('کد شغل', 120, (d) => d.jobCode),
        _textColumn(
          'عنوان شغل',
          190,
          (d) => d.jobTitle,
          onChanged: (draft, value) {
            if (draft.position.text.trim().isEmpty) {
              draft.position.text = value;
            }
          },
        ),
        _textColumn('سمت', 160, (d) => d.position),
        _dateColumn(
          'تاریخ شروع *',
          130,
          (d) => d.startDate,
          onChanged: (draft, _) => draft.syncExperienceAndSeniority(settings),
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
        _dateColumn('تاریخ ترک کار', 130, (d) => d.endDate),
        _boolColumn('متاهل', 90, (d) => d.isMarried, (draft, value) {
          draft.isMarried = value;
          draft.autoCalculate(settings);
        }),
        _childrenCounterColumn(settings),
      ],
      _EmployeeGridSection.payroll => [
        _textColumn(
          'دستمزد روزانه ۱۴۰۴ *',
          160,
          (d) => d.dailyWage1404,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) => draft.autoCalculate(settings),
        ),
        _rateColumn(settings),
        _textColumn(
          'دستمزد روزانه ۱۴۰۵',
          160,
          (d) => d.dailyWage1405,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) => draft.syncBaseSalary(),
        ),
        _textColumn(
          'حقوق پایه ۳۰ روز',
          160,
          (d) => d.baseSalary30Days,
          numeric: true,
          separateThousands: true,
        ),
        _textColumn(
          'مسکن روزانه',
          150,
          (d) => d.dailyHousing,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) => draft.syncMonthlyFromDaily(
            draft.dailyHousing,
            draft.monthlyHousing,
          ),
        ),
        _textColumn(
          'خواروبار روزانه',
          160,
          (d) => d.dailyFood,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) =>
              draft.syncMonthlyFromDaily(draft.dailyFood, draft.monthlyFood),
        ),
        _textColumn(
          'حق تاهل روزانه',
          160,
          (d) => d.dailyMarriage,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) => draft.syncMonthlyFromDaily(
            draft.dailyMarriage,
            draft.monthlyMarriage,
          ),
        ),
        _textColumn(
          'حق هر فرزند روزانه',
          170,
          (d) => d.dailyChildAllowance,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) => draft.syncMonthlyFromDaily(
            draft.dailyChildAllowance,
            draft.monthlyChildAllowance,
          ),
        ),
        _textColumn(
          'سایر مزایای روزانه',
          170,
          (d) => d.otherBenefitsDaily,
          numeric: true,
          separateThousands: true,
          onChanged: (draft, _) => draft.syncMonthlyFromDaily(
            draft.otherBenefitsDaily,
            draft.monthlyOtherBenefits,
          ),
        ),
        _textColumn(
          'ساعت مزایای ساعتی',
          170,
          (d) => d.hourlyBenefits,
          numeric: true,
          separateThousands: true,
        ),
        _boolColumn(
          'نوبت‌کاری',
          120,
          (d) => d.hasShiftWork,
          (d, value) => d.hasShiftWork = value,
        ),
      ],
      _EmployeeGridSection.monthlyBenefits => [
        _monthlyBenefitColumn(
          'حق مسکن ماهانه',
          (d) => d.monthlyHousing,
          (d) => d.dailyHousing,
        ),
        _monthlyBenefitColumn(
          'حق خواروبار ماهانه',
          (d) => d.monthlyFood,
          (d) => d.dailyFood,
        ),
        _monthlyBenefitColumn(
          'حق تاهل ماهانه',
          (d) => d.monthlyMarriage,
          (d) => d.dailyMarriage,
        ),
        _monthlyBenefitColumn(
          'حق هر فرزند ماهانه',
          (d) => d.monthlyChildAllowance,
          (d) => d.dailyChildAllowance,
        ),
        _monthlyBenefitColumn(
          'سایر مزایا ماهانه',
          (d) => d.monthlyOtherBenefits,
          (d) => d.otherBenefitsDaily,
        ),
      ],
      _EmployeeGridSection.supplemental => [
        _choiceColumn(
          'نام بانک',
          190,
          (d) => d.bankName,
          EmployeeReferenceData.iranianBanks,
          (d, value) => d.bankName = value,
          optional: true,
        ),
        _choiceColumn(
          'نوع حساب',
          170,
          (d) => d.bankAccountType,
          EmployeeReferenceData.bankAccountTypes,
          (d, value) => d.bankAccountType = value,
          optional: true,
        ),
        _textColumn(
          'شماره حساب',
          170,
          (d) => d.bankAccountNumber,
          numeric: true,
        ),
        _textColumn('شماره کارت', 180, (d) => d.cardNumber, numeric: true),
        _textColumn('شماره بیمه', 150, (d) => d.insuranceNumber, numeric: true),
        _choiceColumn(
          'تحصیلات',
          170,
          (d) => d.education,
          EmployeeReferenceData.educations,
          (d, value) => d.education = value,
          optional: true,
        ),
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
    TextEditingController Function(EmployeeBatchDraft) controller, {
    bool numeric = false,
    bool separateThousands = false,
    bool date = false,
    String? hint,
    void Function(EmployeeBatchDraft, String)? onChanged,
  }) {
    return _EmployeeGridColumn(
      label: label,
      width: width,
      builder: (draft) => SizedBox(
        width: width,
        child: TextField(
          controller: controller(draft),
          enabled: !_saving,
          keyboardType: date
              ? TextInputType.datetime
              : numeric
              ? TextInputType.number
              : TextInputType.text,
          textDirection: numeric || date
              ? TextDirection.ltr
              : TextDirection.rtl,
          textAlign: numeric || date ? TextAlign.left : TextAlign.right,
          inputFormatters: date
              ? const [_PersianDateInputFormatter()]
              : numeric
              ? [
                  separateThousands
                      ? const _PersianNumberInputFormatter()
                      : const _PersianDigitsInputFormatter(),
                ]
              : const [PersianDigitsInputFormatter()],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            draft.markTouched();
            onChanged?.call(draft, value);
            if (mounted) setState(() {});
          },
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
      ),
    );
  }

  _EmployeeGridColumn _dateColumn(
    String label,
    double width,
    TextEditingController Function(EmployeeBatchDraft) controller, {
    void Function(EmployeeBatchDraft, String)? onChanged,
  }) {
    return _textColumn(
      label,
      width,
      controller,
      date: true,
      hint: '۱۴۰۵/۰۱/۰۱',
      onChanged: onChanged,
    );
  }

  _EmployeeGridColumn _choiceColumn(
    String label,
    double width,
    String Function(EmployeeBatchDraft) value,
    List<String> items,
    void Function(EmployeeBatchDraft, String) onChanged, {
    bool optional = false,
  }) {
    return _EmployeeGridColumn(
      label: label,
      width: width,
      builder: (draft) {
        final current = value(draft);
        return SizedBox(
          width: width,
          child: DropdownButtonFormField<String>(
            key: ValueKey('${identityHashCode(draft)}-$label'),
            initialValue: current.isEmpty ? null : current,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              if (optional)
                const DropdownMenuItem(value: '', child: Text('انتخاب نشده')),
              ...items.map(
                (item) => DropdownMenuItem(value: item, child: Text(item)),
              ),
            ],
            onChanged: _saving
                ? null
                : (next) {
                    if (next == null) return;
                    draft.markTouched();
                    onChanged(draft, next);
                    if (mounted) setState(() {});
                  },
          ),
        );
      },
    );
  }

  _EmployeeGridColumn _boolColumn(
    String label,
    double width,
    bool Function(EmployeeBatchDraft) value,
    FutureOr<void> Function(EmployeeBatchDraft, bool) onChanged,
  ) {
    return _EmployeeGridColumn(
      label: label,
      width: width,
      builder: (draft) => SizedBox(
        width: width,
        child: Center(
          child: Tooltip(
            message: label,
            child: Checkbox(
              value: value(draft),
              onChanged: _saving
                  ? null
                  : (next) async {
                      if (next == null) return;
                      draft.markTouched();
                      await onChanged(draft, next);
                      if (mounted) setState(() {});
                    },
            ),
          ),
        ),
      ),
    );
  }

  _EmployeeGridColumn _monthlyBenefitColumn(
    String label,
    TextEditingController Function(EmployeeBatchDraft) monthly,
    TextEditingController Function(EmployeeBatchDraft) daily,
  ) {
    return _textColumn(
      label,
      180,
      monthly,
      numeric: true,
      separateThousands: true,
      onChanged: (draft, _) =>
          draft.syncDailyFromMonthly(monthly(draft), daily(draft)),
    );
  }

  _EmployeeGridColumn _rateColumn(AppSettings settings) {
    final items = <double, String>{
      settings.salaryRateA: 'کارگری',
      settings.salaryRateB: 'سایر',
    };
    return _EmployeeGridColumn(
      label: 'ضریب افزایش ۱۴۰۵',
      width: 150,
      builder: (draft) => SizedBox(
        width: 150,
        child: DropdownButtonFormField<double>(
          key: ValueKey('${identityHashCode(draft)}-salary-rate'),
          initialValue: draft.selectedRate,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: items.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    '${_formatSalaryRate(entry.key)} (${entry.value})',
                  ),
                ),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (value) {
                  if (value == null) return;
                  draft
                    ..markTouched()
                    ..selectedRate = value
                    ..autoCalculate(settings);
                  setState(() {});
                },
        ),
      ),
    );
  }

  _EmployeeGridColumn _childrenCounterColumn(AppSettings settings) {
    return _EmployeeGridColumn(
      label: 'تعداد فرزند',
      width: 142,
      builder: (draft) => SizedBox(
        width: 142,
        child: Row(
          children: [
            _counterButton(
              icon: Icons.remove_rounded,
              enabled: !_saving && draft.childrenCountValue > 0,
              onPressed: () {
                draft
                  ..markTouched()
                  ..setChildrenCount(draft.childrenCountValue - 1)
                  ..autoCalculate(settings);
                setState(() {});
              },
            ),
            Expanded(
              child: TextField(
                controller: draft.childrenCount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                inputFormatters: const [_PersianDigitsInputFormatter()],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) {
                  draft
                    ..markTouched()
                    ..autoCalculate(settings);
                  setState(() {});
                },
              ),
            ),
            _counterButton(
              icon: Icons.add_rounded,
              enabled: !_saving,
              onPressed: () {
                draft
                  ..markTouched()
                  ..setChildrenCount(draft.childrenCountValue + 1)
                  ..autoCalculate(settings);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 36),
      padding: EdgeInsets.zero,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
    );
  }

  String _formatSalaryRate(double value) {
    final formatted = value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return PersianNumberFormatter.toPersian(formatted);
  }
}

class _PinnedEmployeeName extends StatelessWidget {
  final EmployeeBatchDraft draft;

  const _PinnedEmployeeName({required this.draft});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = draft.fullName.isEmpty ? 'نام وارد نشده' : draft.fullName;
    final code = draft.personnelCode.text.trim();
    return Tooltip(
      message: code.isEmpty ? name : '$name\nکد پرسنلی: $code',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: draft.fullName.isEmpty
                  ? scheme.onSurfaceVariant
                  : scheme.onSurface,
            ),
          ),
          if (code.isNotEmpty)
            Text(
              'کد ${PersianNumberFormatter.toPersian(code)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployeeGridColumn {
  final String label;
  final double width;
  final Widget Function(EmployeeBatchDraft draft) builder;

  const _EmployeeGridColumn({
    required this.label,
    required this.width,
    required this.builder,
  });
}

class _PersianDateInputFormatter extends TextInputFormatter {
  const _PersianDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = PersianNumberFormatter.toPersian(
      PersianNumberFormatter.toEnglish(newValue.text),
    ).replaceAll('-', '/');
    final text = normalized.replaceAll(RegExp(r'[^۰-۹/]'), '');
    final offset = newValue.selection.baseOffset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class _PersianDigitsInputFormatter extends TextInputFormatter {
  const _PersianDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = _NumberInputText.persianDigitsOnly(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _NumberInputText.selectionOffset(
          formatted: text,
          sourceText: newValue.text,
          sourceOffset: newValue.selection.extentOffset,
        ),
      ),
      composing: TextRange.empty,
    );
  }
}

class _PersianNumberInputFormatter extends TextInputFormatter {
  const _PersianNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.trim().isEmpty) return newValue.copyWith(text: '');
    final normalized = PersianNumberFormatter.toEnglish(newValue.text);
    final numeric = normalized
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    if (numeric.isEmpty) return newValue.copyWith(text: '');

    final parts = numeric.split('.');
    final intPart = parts.first;
    if (intPart.isEmpty) return oldValue;
    final value = int.tryParse(intPart);
    if (value == null) return oldValue;

    var formatted = PersianNumberFormatter.formatNumber(value);
    if (parts.length > 1) {
      final decimal = parts.skip(1).join();
      formatted = '$formatted.${PersianNumberFormatter.toPersian(decimal)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _NumberInputText.selectionOffset(
          formatted: formatted,
          sourceText: newValue.text,
          sourceOffset: newValue.selection.extentOffset,
          countDecimalPoint: true,
        ),
      ),
      composing: TextRange.empty,
    );
  }
}

class _NumberInputText {
  const _NumberInputText._();

  static String persianDigitsOnly(String value) {
    final buffer = StringBuffer();
    for (final rune in PersianNumberFormatter.toPersian(value).runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[۰-۹]').hasMatch(char)) buffer.write(char);
    }
    return buffer.toString();
  }

  static int selectionOffset({
    required String formatted,
    required String sourceText,
    required int sourceOffset,
    bool countDecimalPoint = false,
  }) {
    final source = PersianNumberFormatter.toEnglish(
      sourceText.substring(0, sourceOffset.clamp(0, sourceText.length)),
    );
    var wanted = 0;
    for (final rune in source.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[0-9]').hasMatch(char) ||
          (countDecimalPoint && char == '.')) {
        wanted++;
      }
    }
    if (wanted <= 0) return 0;
    var seen = 0;
    for (var index = 0; index < formatted.length; index++) {
      final char = formatted[index];
      if (RegExp(r'[۰-۹]').hasMatch(char) ||
          (countDecimalPoint && char == '.')) {
        seen++;
        if (seen >= wanted) return index + 1;
      }
    }
    return formatted.length;
  }
}

class EmployeeBatchDraft {
  EmployeeBatchDraft({
    required AppSettings settings,
    required int personnelCode,
  }) {
    reset(settings: settings, personnelCode: personnelCode);
  }

  EmployeeBatchDraft.fromEmployee({
    required Employee employee,
    required AppSettings settings,
  }) {
    employeeId = employee.id;
    personnelCode.text = PersianNumberFormatter.toPersian(
      employee.personnelCode.toString(),
    );
    firstName.text = PersianNumberFormatter.toPersian(employee.firstName);
    lastName.text = PersianNumberFormatter.toPersian(employee.lastName);
    nationalId.text = PersianNumberFormatter.toPersian(employee.nationalId);
    fatherName.text = PersianNumberFormatter.toPersian(employee.fatherName);
    birthCertificateNumber.text = PersianNumberFormatter.toPersian(
      employee.birthCertificateNumber,
    );
    workplace.text = PersianNumberFormatter.toPersian(employee.workplace);
    bankAccountNumber.text = PersianNumberFormatter.toPersian(
      employee.bankAccountNumber,
    );
    jobCode.text = PersianNumberFormatter.toPersian(employee.jobCode);
    jobTitle.text = PersianNumberFormatter.toPersian(employee.jobTitle);
    birthDate.text = PersianNumberFormatter.toPersian(employee.birthDate);
    birthPlace.text = PersianNumberFormatter.toPersian(employee.birthPlace);
    phone.text = PersianNumberFormatter.toPersian(employee.phone);
    childrenCount.text = PersianNumberFormatter.toPersian(
      employee.childrenCount.toString(),
    );
    lastYearSeniority.text = formatNumber(employee.lastYearSeniority);
    baseSalary30Days.text = formatNumber(employee.baseSalary30Days);
    dailyWage1405.text = formatNumber(employee.dailyWage1405);
    dailyWage1404.text = formatNumber(employee.dailyWage1404);
    dailyHousing.text = formatNumber(employee.dailyHousing);
    dailyFood.text = formatNumber(employee.dailyFood);
    dailyMarriage.text = formatNumber(employee.dailyMarriage);
    dailyChildAllowance.text = formatNumber(employee.dailyChildAllowance);
    dailySeniority.text = formatNumber(employee.dailySeniority);
    otherBenefitsDaily.text = formatNumber(employee.otherBenefitsDaily);
    hourlyBenefits.text = formatNumber(employee.hourlyBenefits);
    startDate.text = PersianNumberFormatter.toPersian(employee.startDate);
    endDate.text = PersianNumberFormatter.toPersian(employee.endDate);
    cardNumber.text = PersianNumberFormatter.toPersian(employee.cardNumber);
    insuranceNumber.text = PersianNumberFormatter.toPersian(
      employee.insuranceNumber,
    );
    position.text = PersianNumberFormatter.toPersian(employee.position);
    address.text = PersianNumberFormatter.toPersian(employee.address);
    payslipFooterNote.text = PersianNumberFormatter.toPersian(
      employee.payslipFooterNote,
    );
    notes.text = PersianNumberFormatter.toPersian(employee.notes ?? '');

    gender = EmployeeReferenceData.genders.contains(employee.gender)
        ? employee.gender
        : EmployeeReferenceData.genders.first;
    employmentType =
        EmployeeReferenceData.employmentTypes.contains(employee.employmentType)
        ? employee.employmentType
        : EmployeeReferenceData.employmentTypes.first;
    bankName = EmployeeReferenceData.iranianBanks.contains(employee.bankName)
        ? employee.bankName
        : '';
    bankAccountType =
        EmployeeReferenceData.bankAccountTypes.contains(
          employee.bankAccountType,
        )
        ? employee.bankAccountType
        : '';
    education = EmployeeReferenceData.educations.contains(employee.education)
        ? employee.education
        : '';
    selectedRate = inferSalaryRate(employee, settings);
    hasPriorExperience = employee.hasPriorExperience;
    isMarried = employee.isMarried;
    isActive = employee.isActive;
    hardAndHarmfulJob = employee.hardAndHarmfulJob;
    hasShiftWork = employee.hasShiftWork;
    syncMonthlyFromDaily(dailyHousing, monthlyHousing);
    syncMonthlyFromDaily(dailyFood, monthlyFood);
    syncMonthlyFromDaily(dailyMarriage, monthlyMarriage);
    syncMonthlyFromDaily(dailyChildAllowance, monthlyChildAllowance);
    syncMonthlyFromDaily(dailySeniority, monthlySeniority);
    syncMonthlyFromDaily(otherBenefitsDaily, monthlyOtherBenefits);
    touched = false;
  }

  int? employeeId;

  final personnelCode = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final nationalId = TextEditingController();
  final fatherName = TextEditingController();
  final birthCertificateNumber = TextEditingController();
  final workplace = TextEditingController();
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
  final monthlyHousing = TextEditingController();
  final monthlyFood = TextEditingController();
  final monthlyMarriage = TextEditingController();
  final monthlyChildAllowance = TextEditingController();
  final monthlySeniority = TextEditingController();
  final monthlyOtherBenefits = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();
  final cardNumber = TextEditingController();
  final insuranceNumber = TextEditingController();
  final position = TextEditingController();
  final address = TextEditingController();
  final payslipFooterNote = TextEditingController();
  final notes = TextEditingController();

  String gender = EmployeeReferenceData.genders.first;
  String employmentType = EmployeeReferenceData.employmentTypes.first;
  String bankName = '';
  String bankAccountType = '';
  String education = '';
  double selectedRate = AppConstants.salaryRateA;
  bool hasPriorExperience = false;
  bool isMarried = false;
  bool isActive = true;
  bool hardAndHarmfulJob = false;
  bool hasShiftWork = false;
  bool touched = false;
  List<String> errors = [];

  List<TextEditingController> get _controllers => [
    personnelCode,
    firstName,
    lastName,
    nationalId,
    fatherName,
    birthCertificateNumber,
    workplace,
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
    monthlyHousing,
    monthlyFood,
    monthlyMarriage,
    monthlyChildAllowance,
    monthlySeniority,
    monthlyOtherBenefits,
    startDate,
    endDate,
    cardNumber,
    insuranceNumber,
    position,
    address,
    payslipFooterNote,
    notes,
  ];

  bool get hasData => touched;

  bool get isExisting => employeeId != null;

  String get fullName => PersianNumberFormatter.toPersian(
    '${firstName.text} ${lastName.text}'.trim(),
  );

  int get childrenCountValue => parseInt(childrenCount.text) ?? 0;

  String get startDateEnglish => textOf(startDate);

  void markTouched() => touched = true;

  void reset({required AppSettings settings, required int personnelCode}) {
    for (final controller in _controllers) {
      controller.clear();
    }
    gender = EmployeeReferenceData.genders.first;
    employmentType = EmployeeReferenceData.employmentTypes.first;
    bankName = '';
    bankAccountType = '';
    education = '';
    selectedRate = settings.salaryRateA;
    hasPriorExperience = false;
    isMarried = false;
    isActive = true;
    hardAndHarmfulJob = false;
    hasShiftWork = false;
    errors = [];
    employeeId = null;

    this.personnelCode.text = PersianNumberFormatter.toPersian(
      personnelCode.toString(),
    );
    workplace.text = PersianNumberFormatter.toPersian(settings.companyName);
    startDate.text = PersianNumberFormatter.toPersian(
      PersianDateHelper.todayText(),
    );
    childrenCount.text = '۰';
    lastYearSeniority.text = formatNumber(0);
    otherBenefitsDaily.text = formatNumber(0);
    hourlyBenefits.text = formatNumber(0);
    dailyWage1404.text = formatNumber(AppConstants.defaultDailyWage1404);
    syncExperienceAndSeniority(settings);
    autoCalculate(settings);
    touched = false;
  }

  EmployeeBatchDraft copyAsNew({
    required AppSettings settings,
    required int personnelCode,
  }) {
    final copy = EmployeeBatchDraft.fromEmployee(
      employee: toEmployee(),
      settings: settings,
    );
    copy
      ..employeeId = null
      ..personnelCode.text = PersianNumberFormatter.toPersian(
        personnelCode.toString(),
      )
      ..errors = []
      ..touched = true;
    return copy;
  }

  void autoCalculate(AppSettings settings) {
    final wage1404 = parseNumber(dailyWage1404.text) ?? 0;
    final wage1405 = SalaryCalculator.calculateDailyWage1405(
      dailyWage1404: wage1404,
      rate: selectedRate,
      fixedRial: settings.fixedRial,
    );
    dailyWage1405.text = formatNumber(wage1405);
    baseSalary30Days.text = formatNumber(
      wage1405 * AppConstants.standardMonthDays,
    );
    setDailyAndMonthly(
      dailyHousing,
      monthlyHousing,
      settings.monthlyHousing / AppConstants.standardMonthDays,
    );
    setDailyAndMonthly(
      dailyFood,
      monthlyFood,
      settings.monthlyFood / AppConstants.standardMonthDays,
    );
    syncChildAllowance(settings);
    setDailyAndMonthly(
      dailyMarriage,
      monthlyMarriage,
      isMarried ? settings.monthlyMarriage / AppConstants.standardMonthDays : 0,
    );
    syncMonthlyFromDaily(otherBenefitsDaily, monthlyOtherBenefits);
  }

  bool hasAutomaticDeviation(AppSettings settings) {
    final wage1404 = parseNumber(dailyWage1404.text) ?? 0;
    final wage1405 = SalaryCalculator.calculateDailyWage1405(
      dailyWage1404: wage1404,
      rate: selectedRate,
      fixedRial: settings.fixedRial,
    );
    final defaults = <(TextEditingController controller, double value)>[
      (dailyWage1405, wage1405),
      (baseSalary30Days, wage1405 * AppConstants.standardMonthDays),
      (dailyHousing, settings.monthlyHousing / AppConstants.standardMonthDays),
      (monthlyHousing, settings.monthlyHousing),
      (dailyFood, settings.monthlyFood / AppConstants.standardMonthDays),
      (monthlyFood, settings.monthlyFood),
      (
        dailyMarriage,
        isMarried
            ? settings.monthlyMarriage / AppConstants.standardMonthDays
            : 0,
      ),
      (monthlyMarriage, isMarried ? settings.monthlyMarriage : 0),
      (
        dailyChildAllowance,
        childrenCountValue > 0
            ? settings.monthlyChild / AppConstants.standardMonthDays
            : 0,
      ),
      (
        monthlyChildAllowance,
        childrenCountValue > 0 ? settings.monthlyChild : 0,
      ),
      (
        monthlyOtherBenefits,
        (parseNumber(otherBenefitsDaily.text) ?? 0) *
            AppConstants.standardMonthDays,
      ),
    ];
    for (final item in defaults) {
      final current = parseNumber(item.$1.text) ?? 0;
      if ((current - item.$2).abs() >= 1) return true;
    }
    return false;
  }

  void resetAutomaticPayroll(AppSettings settings) {
    autoCalculate(settings);
    syncExperienceAndSeniority(settings);
    markTouched();
  }

  void syncExperienceAndSeniority(AppSettings settings) {
    final eligible = SeniorityHelper.isEligibleForPriorExperience(
      startDate: startDateEnglish,
      settings: settings,
    );
    hasPriorExperience = eligible;
    setDailyAndMonthly(dailySeniority, monthlySeniority, 0);
    lastYearSeniority.text = formatNumber(0);
  }

  void syncChildAllowance(AppSettings settings) {
    setDailyAndMonthly(
      dailyChildAllowance,
      monthlyChildAllowance,
      childrenCountValue > 0
          ? settings.monthlyChild / AppConstants.standardMonthDays
          : 0,
    );
  }

  void syncBaseSalary() {
    baseSalary30Days.text = formatNumber(
      (parseNumber(dailyWage1405.text) ?? 0) * AppConstants.standardMonthDays,
    );
  }

  void syncMonthlyFromDaily(
    TextEditingController daily,
    TextEditingController monthly,
  ) {
    monthly.text = formatNumber(
      (parseNumber(daily.text) ?? 0) * AppConstants.standardMonthDays,
    );
  }

  void syncDailyFromMonthly(
    TextEditingController monthly,
    TextEditingController daily,
  ) {
    daily.text = formatNumber(
      (parseNumber(monthly.text) ?? 0) / AppConstants.standardMonthDays,
    );
  }

  void setDailyAndMonthly(
    TextEditingController daily,
    TextEditingController monthly,
    double value,
  ) {
    daily.text = formatNumber(value);
    monthly.text = formatNumber(value * AppConstants.standardMonthDays);
  }

  void setChildrenCount(int value) {
    childrenCount.text = PersianNumberFormatter.toPersian(
      value.clamp(0, 99).toString(),
    );
  }

  List<String> validate({
    required AppSettings settings,
    required Set<int> existingCodes,
    required Set<String> existingNationalIds,
    required Set<int> seenCodes,
    required Set<String> seenNationalIds,
  }) {
    final result = <String>[];
    final code = parseInt(personnelCode.text);
    if (code == null || code <= 0) {
      result.add('کد پرسنلی نامعتبر است');
    } else if (existingCodes.contains(code) || !seenCodes.add(code)) {
      result.add('کد پرسنلی تکراری است');
    }
    if (firstName.text.trim().isEmpty) result.add('نام الزامی است');
    if (lastName.text.trim().isEmpty) result.add('نام خانوادگی الزامی است');

    final national = digits(nationalId.text);
    if (national.length != 10) {
      result.add('کد ملی باید ۱۰ رقم باشد');
    } else if (existingNationalIds.contains(national) ||
        !seenNationalIds.add(national)) {
      result.add('کد ملی تکراری است');
    }

    final start = textOf(startDate);
    if (SeniorityHelper.parseStartDate(start) == null) {
      result.add('تاریخ شروع به کار نامعتبر است');
    } else if (hasPriorExperience &&
        !SeniorityHelper.isEligibleForPriorExperience(
          startDate: start,
          settings: settings,
        )) {
      result.add(
        'دارای سابقه نیازمند حداقل یک سال سابقه تا پایان سال مالی است',
      );
    }
    final birth = textOf(birthDate);
    if (birth.isNotEmpty && SeniorityHelper.parseStartDate(birth) == null) {
      result.add('تاریخ تولد نامعتبر است');
    }
    final end = textOf(endDate);
    if (end.isNotEmpty && SeniorityHelper.parseStartDate(end) == null) {
      result.add('تاریخ ترک کار نامعتبر است');
    }
    if (!isActive && textOf(endDate).isEmpty) {
      result.add('برای کارمند غیرفعال تاریخ ترک کار الزامی است');
    }
    if (dailyWage1404.text.trim().isEmpty) {
      result.add('دستمزد روزانه ۱۴۰۴ الزامی است');
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
      ('حق هر فرزند', dailyChildAllowance),
      ('سنوات', dailySeniority),
      ('سایر مزایا', otherBenefitsDaily),
      ('مزایای ساعتی', hourlyBenefits),
      ('مسکن ماهانه', monthlyHousing),
      ('خواروبار ماهانه', monthlyFood),
      ('حق تاهل ماهانه', monthlyMarriage),
      ('حق هر فرزند ماهانه', monthlyChildAllowance),
      ('سنوات ماهانه', monthlySeniority),
      ('سایر مزایا ماهانه', monthlyOtherBenefits),
    ]) {
      if (field.$2.text.trim().isEmpty) continue;
      final value = parseNumber(field.$2.text);
      if (value == null) {
        result.add('${field.$1} عدد معتبری نیست');
      } else if (value < 0) {
        result.add('${field.$1} نمی‌تواند منفی باشد');
      }
    }
    return result;
  }

  Employee toEmployee() => Employee(
    id: employeeId,
    personnelCode: parseInt(personnelCode.text)!,
    firstName: firstName.text.trim(),
    lastName: lastName.text.trim(),
    nationalId: digits(nationalId.text),
    fatherName: fatherName.text.trim(),
    birthCertificateNumber: digits(birthCertificateNumber.text),
    gender: gender,
    workplace: workplace.text.trim(),
    bankName: bankName,
    bankAccountType: bankAccountType,
    bankAccountNumber: digits(bankAccountNumber.text),
    jobCode: textOf(jobCode),
    jobTitle: jobTitle.text.trim(),
    birthDate: textOf(birthDate),
    birthPlace: birthPlace.text.trim(),
    phone: digits(phone.text),
    hasPriorExperience: hasPriorExperience,
    isMarried: isMarried,
    childrenCount: parseInt(childrenCount.text) ?? 0,
    lastYearSeniority: 0,
    baseSalary30Days: parseNumber(baseSalary30Days.text) ?? 0,
    dailyWage1405: parseNumber(dailyWage1405.text) ?? 0,
    dailyWage1404: parseNumber(dailyWage1404.text) ?? 0,
    dailyHousing: parseNumber(dailyHousing.text) ?? 0,
    dailyFood: parseNumber(dailyFood.text) ?? 0,
    dailyMarriage: parseNumber(dailyMarriage.text) ?? 0,
    dailyChildAllowance: parseNumber(dailyChildAllowance.text) ?? 0,
    dailySeniority: 0,
    otherBenefitsDaily: parseNumber(otherBenefitsDaily.text) ?? 0,
    hourlyBenefits: parseNumber(hourlyBenefits.text) ?? 0,
    hasShiftWork: hasShiftWork,
    startDate: textOf(startDate),
    isActive: isActive,
    endDate: textOf(endDate),
    cardNumber: digits(cardNumber.text),
    insuranceNumber: digits(insuranceNumber.text),
    education: education,
    position: position.text.trim(),
    employmentType: employmentType,
    address: address.text.trim(),
    hardAndHarmfulJob: hardAndHarmfulJob,
    payslipFooterNote: payslipFooterNote.text.trim(),
    notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
  );

  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  static String textOf(TextEditingController controller) =>
      PersianNumberFormatter.toEnglish(controller.text.trim());

  static String digits(String value) =>
      PersianNumberFormatter.toEnglish(value).replaceAll(RegExp(r'[^0-9]'), '');

  static String _normalizedNumber(String value) =>
      PersianNumberFormatter.toEnglish(
        value,
      ).replaceAll('٬', '').replaceAll(',', '').replaceAll('،', '').trim();

  static int? parseInt(String value) {
    final normalized = _normalizedNumber(value);
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  static double? parseNumber(String value) {
    final normalized = _normalizedNumber(value);
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static String formatNumber(num value) =>
      PersianNumberFormatter.formatNumber(value);

  static double inferSalaryRate(Employee employee, AppSettings settings) {
    if (employee.dailyWage1404 <= 0) return settings.salaryRateA;
    final inferred =
        (employee.dailyWage1405 - settings.fixedRial) / employee.dailyWage1404;
    final distanceA = (inferred - settings.salaryRateA).abs();
    final distanceB = (inferred - settings.salaryRateB).abs();
    return distanceA <= distanceB ? settings.salaryRateA : settings.salaryRateB;
  }
}
