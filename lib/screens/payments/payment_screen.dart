import 'package:flutter/material.dart';

import '../../services/salary_payment_service.dart';
import '../../utils/business_validation.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/period_filter_bar.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _service = SalaryPaymentService();
  final _searchController = TextEditingController();
  List<PaymentSlipRow> _rows = const [];
  List<(int, int)> _periods = const [];
  (int, int)? _selectedPeriod;
  String _search = '';
  String? _savingKey;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PaymentSlipRow> get _filteredRows {
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

  @override
  Widget build(BuildContext context) {
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
              trailing: _PaymentSummary(rows: visible),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
              sliver: SliverList.separated(
                itemBuilder: (context, index) => _PaymentCard(
                  row: visible[index],
                  saving: _savingKey == _keyOf(visible[index]),
                  onPaid: () => _save(row: visible[index], isPaid: true),
                  onUnpaid: () => _markUnpaid(visible[index]),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: visible.length,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markUnpaid(PaymentSlipRow row) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _UnpaidReasonDialog(initial: row.unpaidReason),
    );
    if (reason == null) return;
    await _save(row: row, isPaid: false, reason: reason);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPaid ? 'پرداخت ثبت شد' : 'پرداخت‌نشدن ثبت شد'),
        ),
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

  String _keyOf(PaymentSlipRow row) =>
      '${row.employeeId}-${row.year}-${row.month}';
}

class _PaymentSummary extends StatelessWidget {
  final List<PaymentSlipRow> rows;
  const _PaymentSummary({required this.rows});

  @override
  Widget build(BuildContext context) {
    final paid = rows.where((row) => row.isPaid == true).length;
    final unpaid = rows.where((row) => row.isPaid == false).length;
    final pending = rows.length - paid - unpaid;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          label: 'پرداخت‌شده',
          value: paid,
          icon: Icons.check_rounded,
        ),
        _SummaryChip(
          label: 'پرداخت‌نشده',
          value: unpaid,
          icon: Icons.close_rounded,
        ),
        _SummaryChip(
          label: 'ثبت‌نشده',
          value: pending,
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(
        '$label: ${PersianNumberFormatter.toPersian(value.toString())}',
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentSlipRow row;
  final bool saving;
  final VoidCallback onPaid;
  final VoidCallback onUnpaid;

  const _PaymentCard({
    required this.row,
    required this.saving,
    required this.onPaid,
    required this.onUnpaid,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(width: 12),
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
                const SizedBox(width: 8),
                Chip(
                  side: BorderSide(color: statusColor.withValues(alpha: 0.45)),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  label: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AmountTile(
                    label: 'خالص دریافتی',
                    value: row.finalPayment,
                  ),
                ),
                const SizedBox(width: 10),
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
              const SizedBox(height: 12),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saving ? null : onPaid,
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
                    onPressed: saving ? null : onUnpaid,
                    icon: const Icon(Icons.report_problem_rounded),
                    label: const Text('پرداخت نشد'),
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

class _AmountTile extends StatelessWidget {
  final String label;
  final double value;
  const _AmountTile({required this.label, required this.value});

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
