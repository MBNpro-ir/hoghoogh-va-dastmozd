import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_client.dart';
import '../../services/salary_payment_service.dart';
import '../../utils/business_validation.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/period_filter_bar.dart';
import '../salary/payslip_screen.dart';

enum _PaymentFilter { all, paid, unpaid, pending, unlocked, locked }

enum _PaymentSort {
  periodDesc,
  personnelAsc,
  nameAsc,
  amountDesc,
  amountAsc,
  status,
  lastChangedDesc,
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _columnsPrefsKey = 'hvm_payment_grid_columns_v1';
  static const _cardScalePrefsKey = 'hvm_payment_card_scale_v1';

  final _service = SalaryPaymentService();
  final _api = ApiClient();
  final _searchController = TextEditingController();
  List<PaymentSlipRow> _rows = const [];
  List<(int, int)> _periods = const [];
  (int, int)? _selectedPeriod;
  String _search = '';
  String? _savingKey;
  final Set<String> _selectedKeys = {};
  bool _loading = true;
  bool _batchSaving = false;
  String _error = '';
  String _userRole = '';
  bool _roleLoaded = false;
  int _gridColumns = 0;
  double _cardScale = 1;
  _PaymentFilter _filter = _PaymentFilter.all;
  _PaymentSort _sort = _PaymentSort.periodDesc;

  bool get _isPaymentRole => _userRole == 'payment';
  bool get _canManagePayments => _roleLoaded && !_isPaymentRole;

  @override
  void initState() {
    super.initState();
    _loadViewPreferences();
    _loadUserRole();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final periods = await _service.getAvailablePeriods();
      final selected =
          _selectedPeriod != null && periods.contains(_selectedPeriod)
          ? _selectedPeriod
          : (periods.isEmpty ? null : periods.first);
      final rows = await _service.getRows(period: selected);
      if (!mounted) return;
      setState(() {
        _periods = periods;
        _selectedPeriod = selected;
        _rows = rows;
        _selectedKeys.removeWhere(
          (key) => !rows.any((row) => _keyOf(row) == key),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUserRole() async {
    final user = await _api.getUser();
    if (!mounted) return;
    setState(() {
      _userRole = user?['role']?.toString() ?? '';
      _roleLoaded = true;
    });
  }

  Future<void> _loadViewPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _gridColumns = (prefs.getInt(_columnsPrefsKey) ?? 0).clamp(0, 6);
      _cardScale = (prefs.getDouble(_cardScalePrefsKey) ?? 1).clamp(0.85, 1.2);
    });
  }

  Future<void> _setGridColumns(int columns) async {
    final clean = columns.clamp(0, 6);
    setState(() => _gridColumns = clean);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_columnsPrefsKey, clean);
  }

  Future<void> _setCardScale(double scale) async {
    final clean = scale.clamp(0.85, 1.2);
    setState(() => _cardScale = clean);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cardScalePrefsKey, clean);
  }

  List<PaymentSlipRow> get _searchedRows {
    final query = PersianNumberFormatter.toEnglish(
      _search.trim(),
    ).toLowerCase();
    if (query.isEmpty) return _rows;
    return _rows.where((row) {
      final haystack = PersianNumberFormatter.toEnglish(
        '${row.employeeName} ${row.personnelCode} ${row.nationalId} '
        '${row.year}/${row.month} ${row.unpaidReason}',
      ).toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<PaymentSlipRow> get _filteredRows {
    final rows = _searchedRows.where(_matchesFilter).toList();
    rows.sort(_compareRows);
    return rows;
  }

  bool _matchesFilter(PaymentSlipRow row) {
    return switch (_filter) {
      _PaymentFilter.all => true,
      _PaymentFilter.paid => row.isPaid == true,
      _PaymentFilter.unpaid => row.isPaid == false,
      _PaymentFilter.pending => row.isPaid == null,
      _PaymentFilter.unlocked => row.paymentUnlocked,
      _PaymentFilter.locked => !row.paymentUnlocked,
    };
  }

  int _compareRows(PaymentSlipRow a, PaymentSlipRow b) {
    final result = switch (_sort) {
      _PaymentSort.periodDesc => (b.year * 100 + b.month).compareTo(
        a.year * 100 + a.month,
      ),
      _PaymentSort.personnelAsc => a.personnelCode.compareTo(b.personnelCode),
      _PaymentSort.nameAsc => a.employeeName.compareTo(b.employeeName),
      _PaymentSort.amountDesc => b.finalPayment.compareTo(a.finalPayment),
      _PaymentSort.amountAsc => a.finalPayment.compareTo(b.finalPayment),
      _PaymentSort.status => _statusRank(a).compareTo(_statusRank(b)),
      _PaymentSort.lastChangedDesc =>
        (b.statusChangedAt ?? DateTime(0)).compareTo(
          a.statusChangedAt ?? DateTime(0),
        ),
    };
    if (result != 0) return result;
    return a.personnelCode.compareTo(b.personnelCode);
  }

  int _statusRank(PaymentSlipRow row) {
    if (row.isPaid == null) return 0;
    if (row.isPaid == false) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final searched = _searchedRows;
    final visible = _filteredRows;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: PeriodFilterBar(
              selectedPeriod: _selectedPeriod,
              availablePeriods: _periods,
              onPeriodChanged: (period) {
                setState(() => _selectedPeriod = period);
                _load();
              },
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _search = value),
              searchHint: 'جستجوی نام، کد پرسنلی یا کد ملی',
              trailing: _PaymentSummary(
                rows: searched,
                filter: _filter,
                onFilterChanged: (filter) => setState(() {
                  _filter = filter;
                  _selectedKeys.clear();
                }),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PaymentLayoutControls(
                    columns: _gridColumns,
                    cardScale: _cardScale,
                    onColumnsChanged: _setGridColumns,
                    onCardScaleChanged: _setCardScale,
                  ),
                  const SizedBox(height: 8),
                  _PaymentActionBar(
                    sort: _sort,
                    canManagePayments: _canManagePayments,
                    selectedCount: _selectedKeys.length,
                    visibleCount: visible.length,
                    busy: _batchSaving,
                    onSortChanged: (sort) => setState(() => _sort = sort),
                    onSelectAll: () => _selectVisible(visible),
                    onClearSelection: () =>
                        setState(() => _selectedKeys.clear()),
                    onUnlockSelected: () =>
                        _setSelectedUnlocked(visible, unlocked: true),
                    onLockSelected: () =>
                        _setSelectedUnlocked(visible, unlocked: false),
                  ),
                ],
              ),
            ),
          ),
          if (_error.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _InlineError(message: _error),
              ),
            ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyPaymentState(hasAnyPeriod: _periods.isNotEmpty),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 10.0 * _cardScale;
                    final columns = _effectiveColumns(constraints.maxWidth);
                    final itemWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final row in visible)
                          SizedBox(
                            width: itemWidth.clamp(220.0, constraints.maxWidth),
                            child: _PaymentCard(
                              row: row,
                              scale: _cardScale,
                              saving: _savingKey == _keyOf(row),
                              selected: _selectedKeys.contains(_keyOf(row)),
                              canManagePayments: _canManagePayments,
                              isPaymentRole: _isPaymentRole,
                              onSelectionChanged: (selected) =>
                                  _setSelected(row, selected),
                              onCopyAmount: () => _copyFinalPayment(row),
                              onOpenPayslip: () => _openPayslip(row),
                              onPaid: () => _save(row: row, isPaid: true),
                              onUnpaid: () => _markUnpaid(row),
                              onToggleUnlocked: (unlocked) =>
                                  _setPaymentUnlocked(row, unlocked),
                              onDeleteHistoryEntry: (index) =>
                                  _deleteHistoryEntry(row, index),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _effectiveColumns(double width) {
    if (_gridColumns > 0) {
      final maxForWidth = width < 560 ? 2 : 6;
      return _gridColumns.clamp(1, maxForWidth);
    }
    if (width >= 1320) return 4;
    if (width >= 960) return 3;
    if (width >= 620) return 2;
    return 1;
  }

  Future<void> _markUnpaid(PaymentSlipRow row) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _UnpaidReasonDialog(initial: row.unpaidReason),
    );
    if (reason == null) return;
    await _save(row: row, isPaid: false, reason: reason);
  }

  Future<void> _openPayslip(PaymentSlipRow row) async {
    try {
      final data = await _service.payslipData(row);
      if (!mounted) return;
      if (data == null) {
        setState(() => _error = 'اطلاعات فیش برای نمایش پیدا نشد.');
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayslipScreen(
            employee: data.employee,
            settings: data.settings,
            record: data.record,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _copyFinalPayment(PaymentSlipRow row) async {
    final raw = row.finalPayment.round().toString();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    AppNotification.info(
      context,
      'مبلغ خالص دریافتی ${PersianNumberFormatter.toPersian(raw)} ریال کپی شد',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _save({
    required PaymentSlipRow row,
    required bool isPaid,
    String reason = '',
  }) async {
    final key = _keyOf(row);
    setState(() {
      _savingKey = key;
      _error = '';
    });
    try {
      await _service.saveStatus(
        employeeId: row.employeeId,
        year: row.year,
        month: row.month,
        isPaid: isPaid,
        unpaidReason: reason,
      );
      await _load();
      if (!mounted) return;
      AppNotification.success(
        context,
        isPaid ? 'پرداخت ثبت شد' : 'پرداخت‌نشدن ثبت شد',
      );
    } on BusinessValidationException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  void _setSelected(PaymentSlipRow row, bool selected) {
    setState(() {
      final key = _keyOf(row);
      if (selected) {
        _selectedKeys.add(key);
      } else {
        _selectedKeys.remove(key);
      }
    });
  }

  void _selectVisible(List<PaymentSlipRow> visible) {
    setState(() {
      final visibleKeys = visible.map(_keyOf).toSet();
      if (visibleKeys.isNotEmpty && visibleKeys.every(_selectedKeys.contains)) {
        _selectedKeys.removeAll(visibleKeys);
      } else {
        _selectedKeys.addAll(visibleKeys);
      }
    });
  }

  Future<void> _setPaymentUnlocked(PaymentSlipRow row, bool unlocked) async {
    final key = _keyOf(row);
    setState(() {
      _savingKey = key;
      _error = '';
    });
    try {
      await _service.setPaymentUnlocked(
        employeeId: row.employeeId,
        year: row.year,
        month: row.month,
        unlocked: unlocked,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  Future<void> _setSelectedUnlocked(
    List<PaymentSlipRow> visible, {
    required bool unlocked,
  }) async {
    final selectedRows = visible
        .where((row) => _selectedKeys.contains(_keyOf(row)))
        .toList();
    if (selectedRows.isEmpty) return;
    setState(() {
      _batchSaving = true;
      _error = '';
    });
    try {
      await _service.setPaymentUnlockedForRows(
        rows: selectedRows,
        unlocked: unlocked,
      );
      await _load();
      if (!mounted) return;
      setState(() => _selectedKeys.clear());
      AppNotification.success(
        context,
        unlocked ? 'قفل پرداخت باز شد' : 'قفل پرداخت بسته شد',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _batchSaving = false);
    }
  }

  Future<void> _deleteHistoryEntry(PaymentSlipRow row, int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف لاگ پرداخت'),
            content: const Text('این مورد از تاریخچه پرداخت حذف شود؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final key = _keyOf(row);
    setState(() {
      _savingKey = key;
      _error = '';
    });
    try {
      await _service.deleteHistoryEntry(row: row, historyIndex: index);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  String _keyOf(PaymentSlipRow row) =>
      '${row.employeeId}-${row.year}-${row.month}';
}

class _PaymentSummary extends StatelessWidget {
  final List<PaymentSlipRow> rows;
  final _PaymentFilter filter;
  final ValueChanged<_PaymentFilter> onFilterChanged;

  const _PaymentSummary({
    required this.rows,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final paid = rows.where((row) => row.isPaid == true).length;
    final unpaid = rows.where((row) => row.isPaid == false).length;
    final pending = rows.length - paid - unpaid;
    final unlocked = rows.where((row) => row.paymentUnlocked).length;
    final locked = rows.length - unlocked;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          label: 'همه',
          value: rows.length,
          icon: Icons.filter_alt_off_rounded,
          selected: filter == _PaymentFilter.all,
          onSelected: () => onFilterChanged(_PaymentFilter.all),
        ),
        _SummaryChip(
          label: 'پرداخت‌شده',
          value: paid,
          icon: Icons.check_rounded,
          selected: filter == _PaymentFilter.paid,
          onSelected: () => onFilterChanged(_PaymentFilter.paid),
        ),
        _SummaryChip(
          label: 'پرداخت‌نشده',
          value: unpaid,
          icon: Icons.close_rounded,
          selected: filter == _PaymentFilter.unpaid,
          onSelected: () => onFilterChanged(_PaymentFilter.unpaid),
        ),
        _SummaryChip(
          label: 'ثبت‌نشده',
          value: pending,
          icon: Icons.pending_actions_rounded,
          selected: filter == _PaymentFilter.pending,
          onSelected: () => onFilterChanged(_PaymentFilter.pending),
        ),
        _SummaryChip(
          label: 'باز',
          value: unlocked,
          icon: Icons.lock_open_rounded,
          selected: filter == _PaymentFilter.unlocked,
          onSelected: () => onFilterChanged(_PaymentFilter.unlocked),
        ),
        _SummaryChip(
          label: 'قفل',
          value: locked,
          icon: Icons.lock_rounded,
          selected: filter == _PaymentFilter.locked,
          onSelected: () => onFilterChanged(_PaymentFilter.locked),
        ),
      ],
    );
  }
}

class _PaymentActionBar extends StatelessWidget {
  final _PaymentSort sort;
  final bool canManagePayments;
  final int selectedCount;
  final int visibleCount;
  final bool busy;
  final ValueChanged<_PaymentSort> onSortChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onUnlockSelected;
  final VoidCallback onLockSelected;

  const _PaymentActionBar({
    required this.sort,
    required this.canManagePayments,
    required this.selectedCount,
    required this.visibleCount,
    required this.busy,
    required this.onSortChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onUnlockSelected,
    required this.onLockSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<_PaymentSort>(
                initialValue: sort,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'مرتب‌سازی',
                  prefixIcon: Icon(Icons.sort_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: _PaymentSort.periodDesc,
                    child: Text('جدیدترین دوره'),
                  ),
                  DropdownMenuItem(
                    value: _PaymentSort.personnelAsc,
                    child: Text('کد پرسنلی'),
                  ),
                  DropdownMenuItem(
                    value: _PaymentSort.nameAsc,
                    child: Text('نام کارمند'),
                  ),
                  DropdownMenuItem(
                    value: _PaymentSort.amountDesc,
                    child: Text('بیشترین مبلغ'),
                  ),
                  DropdownMenuItem(
                    value: _PaymentSort.amountAsc,
                    child: Text('کمترین مبلغ'),
                  ),
                  DropdownMenuItem(
                    value: _PaymentSort.status,
                    child: Text('وضعیت پرداخت'),
                  ),
                  DropdownMenuItem(
                    value: _PaymentSort.lastChangedDesc,
                    child: Text('آخرین تغییر'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onSortChanged(value);
                },
              ),
            ),
            if (canManagePayments) ...[
              FilterChip(
                avatar: const Icon(Icons.checklist_rounded, size: 18),
                label: Text(
                  selectedCount == 0
                      ? 'انتخاب فیش‌ها'
                      : 'انتخاب‌شده: ${PersianNumberFormatter.toPersian(selectedCount.toString())}',
                ),
                selected: selectedCount > 0,
                onSelected: visibleCount == 0 || busy
                    ? null
                    : (_) => onSelectAll(),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || busy ? null : onUnlockSelected,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: const Text('باز کردن قفل'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || busy ? null : onLockSelected,
                icon: const Icon(Icons.lock_rounded),
                label: const Text('بستن قفل'),
              ),
              if (selectedCount > 0)
                IconButton(
                  tooltip: 'پاک‌کردن انتخاب',
                  onPressed: busy ? null : onClearSelection,
                  icon: Icon(Icons.clear_rounded, color: scheme.onSurface),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentLayoutControls extends StatelessWidget {
  final int columns;
  final double cardScale;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<double> onCardScaleChanged;

  const _PaymentLayoutControls({
    required this.columns,
    required this.cardScale,
    required this.onColumnsChanged,
    required this.onCardScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = ((cardScale - 1) * 100).round();
    final percentText = percent == 0
        ? 'عادی'
        : '${percent > 0 ? '+' : ''}${PersianNumberFormatter.toPersian(percent.toString())}%';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final columnsMenu = DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: columns,
                borderRadius: BorderRadius.circular(12),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('ستون خودکار')),
                  for (var i = 1; i <= 6; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${PersianNumberFormatter.toPersian(i.toString())} ستون',
                      ),
                    ),
                ],
                onChanged: (value) => onColumnsChanged(value ?? 0),
              ),
            );
            final scaleControl = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fit_screen_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(percentText),
                SizedBox(
                  width: narrow
                      ? math.max<double>(140, constraints.maxWidth - 220)
                      : 220,
                  child: Slider(
                    value: cardScale,
                    min: 0.85,
                    max: 1.2,
                    divisions: 7,
                    onChanged: onCardScaleChanged,
                  ),
                ),
              ],
            );
            final reset = IconButton(
              tooltip: 'بازنشانی چیدمان',
              onPressed: () {
                onColumnsChanged(0);
                onCardScaleChanged(1);
              },
              icon: const Icon(Icons.restart_alt_rounded),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_comfy_alt_rounded),
                      const SizedBox(width: 8),
                      Expanded(child: columnsMenu),
                      reset,
                    ],
                  ),
                  scaleControl,
                ],
              );
            }
            return Row(
              children: [
                const Icon(Icons.view_comfy_alt_rounded),
                const SizedBox(width: 8),
                columnsMenu,
                const SizedBox(width: 24),
                Expanded(child: scaleControl),
                reset,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer.withValues(alpha: 0.65),
      side: BorderSide(color: scheme.outlineVariant),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      label: Text(
        '$label: ${PersianNumberFormatter.toPersian(value.toString())}',
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentSlipRow row;
  final double scale;
  final bool saving;
  final bool selected;
  final bool canManagePayments;
  final bool isPaymentRole;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onCopyAmount;
  final VoidCallback onOpenPayslip;
  final VoidCallback onPaid;
  final VoidCallback onUnpaid;
  final ValueChanged<bool> onToggleUnlocked;
  final ValueChanged<int> onDeleteHistoryEntry;

  const _PaymentCard({
    required this.row,
    required this.scale,
    required this.saving,
    required this.selected,
    required this.canManagePayments,
    required this.isPaymentRole,
    required this.onSelectionChanged,
    required this.onCopyAmount,
    required this.onOpenPayslip,
    required this.onPaid,
    required this.onUnpaid,
    required this.onToggleUnlocked,
    required this.onDeleteHistoryEntry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paid = row.isPaid == true;
    final unpaid = row.isPaid == false;
    final period =
        '${PersianDateHelper.monthName(row.month)} ${PersianNumberFormatter.toPersian(row.year.toString())}';
    final statusColor = paid
        ? Colors.green
        : unpaid
        ? scheme.error
        : scheme.tertiary;
    final statusText = paid
        ? 'پرداخت‌شده'
        : unpaid
        ? 'پرداخت‌نشده'
        : 'ثبت‌نشده';
    final canChangeStatus = !saving && (!isPaymentRole || row.paymentUnlocked);
    final padding = 14.0 * scale;
    final gap = 10.0 * scale;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canManagePayments) ...[
                  Checkbox(
                    value: selected,
                    onChanged: saving
                        ? null
                        : (value) => onSelectionChanged(value ?? false),
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: gap * 0.3),
                ],
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    PersianNumberFormatter.toPersian(
                      row.personnelCode.toString(),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.employeeName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$period • کد ملی ${PersianNumberFormatter.toPersian(row.nationalId)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: gap * 0.8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      side: BorderSide(
                        color: statusColor.withValues(alpha: 0.45),
                      ),
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      label: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _PaymentLockControl(
                      unlocked: row.paymentUnlocked,
                      canManage: canManagePayments,
                      saving: saving,
                      onChanged: onToggleUnlocked,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: gap + 4),
            Row(
              children: [
                Expanded(
                  child: _AmountTile(
                    label: 'خالص دریافتی',
                    value: row.finalPayment,
                    onCopy: onCopyAmount,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _MetaTile(
                    label: 'آخرین ثبت',
                    value: row.statusChangedAt == null
                        ? '-'
                        : PersianNumberFormatter.toPersian(
                            PersianDateHelper.formatJalali(
                              PersianDateHelper.fromGregorian(
                                row.statusChangedAt!.toLocal(),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (unpaid && row.unpaidReason.trim().isNotEmpty) ...[
              SizedBox(height: gap + 2),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    row.unpaidReason,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            if (row.history.isNotEmpty) ...[
              SizedBox(height: gap + 2),
              _PaymentHistoryTimeline(
                entries: row.history,
                canDelete: canManagePayments && !saving,
                onDelete: onDeleteHistoryEntry,
              ),
            ],
            SizedBox(height: gap + 4),
            OutlinedButton.icon(
              onPressed: saving ? null : onOpenPayslip,
              icon: const Icon(Icons.print_rounded),
              label: const Text('نمایش و چاپ فیش'),
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canChangeStatus ? onPaid : null,
                    icon: saving && !unpaid
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('پرداخت شد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canChangeStatus ? onUnpaid : null,
                    icon: Icon(
                      isPaymentRole && !row.paymentUnlocked
                          ? Icons.lock_rounded
                          : Icons.report_problem_rounded,
                    ),
                    label: Text(
                      isPaymentRole && !row.paymentUnlocked
                          ? 'قفل است'
                          : 'پرداخت نشد',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentLockControl extends StatelessWidget {
  final bool unlocked;
  final bool canManage;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _PaymentLockControl({
    required this.unlocked,
    required this.canManage,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = unlocked ? scheme.primary : scheme.outline;
    if (canManage) {
      return Tooltip(
        message: unlocked ? 'پرداخت باز است' : 'پرداخت قفل است',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 18,
              color: color,
            ),
            Switch.adaptive(
              value: unlocked,
              onChanged: saving ? null : onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
    }
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
        size: 16,
        color: color,
      ),
      label: Text(unlocked ? 'باز' : 'قفل'),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _PaymentHistoryTimeline extends StatelessWidget {
  final List<PaymentStatusLogEntry> entries;
  final bool canDelete;
  final ValueChanged<int> onDelete;

  const _PaymentHistoryTimeline({
    required this.entries,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latest = <({PaymentStatusLogEntry entry, int index})>[];
    for (var i = entries.length - 1; i >= 0 && latest.length < 4; i--) {
      latest.add((entry: entries[i], index: i));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تاریخچه وضعیت',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final item in latest)
              _PaymentHistoryRow(
                entry: item.entry,
                canDelete: canDelete,
                onDelete: () => onDelete(item.index),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final PaymentStatusLogEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;

  const _PaymentHistoryRow({
    required this.entry,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = entry.isPaid ? Colors.green : scheme.error;
    final date = PersianNumberFormatter.toPersian(
      PersianDateHelper.formatJalali(
        PersianDateHelper.fromGregorian(entry.changedAt.toLocal()),
      ),
    );
    final status = entry.isPaid ? 'پرداخت شد' : 'پرداخت نشد';
    final actor = entry.actor.trim().isEmpty ? '' : ' - ${entry.actor}';
    final reason = entry.reason.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.isPaid
                ? Icons.check_circle_rounded
                : Icons.report_problem_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason.isEmpty
                  ? '$date - $status$actor'
                  : '$date - $status$actor؛ دلیل: $reason',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'حذف لاگ',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: scheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final double value;
  final VoidCallback onCopy;
  const _AmountTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'کپی مبلغ',
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            CurrencyText(
              value,
              showUnit: true,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetaTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnpaidReasonDialog extends StatefulWidget {
  final String initial;
  const _UnpaidReasonDialog({required this.initial});

  @override
  State<_UnpaidReasonDialog> createState() => _UnpaidReasonDialogState();
}

class _UnpaidReasonDialogState extends State<_UnpaidReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('دلیل پرداخت نشدن'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 5,
        maxLength: 500,
        decoration: const InputDecoration(
          hintText: 'مثلا: مغایرت حساب، انتظار تایید بانک، نقص مدارک...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(context, reason);
          },
          child: const Text('ثبت'),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
      ),
    );
  }
}

class _EmptyPaymentState extends StatelessWidget {
  final bool hasAnyPeriod;
  const _EmptyPaymentState({required this.hasAnyPeriod});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_rounded,
              size: 54,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasAnyPeriod
                  ? 'برای این فیلتر فیشی پیدا نشد'
                  : 'هنوز فیش حقوقی ثبت نشده است',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
