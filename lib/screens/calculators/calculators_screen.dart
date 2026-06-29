import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/calculator_run.dart';
import '../../services/calculator_run_service.dart';
import '../../services/payroll_calculator_registry.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/currency_text.dart';
import '../../widgets/floating_nav_safe_area.dart';
import '../../widgets/persian_number_field.dart';
import '../salary/salary_calculation_screen.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  final _settingsService = SettingsService();
  final _runService = CalculatorRunService();

  AppSettings? _settings;
  String _category = CalculatorCategory.payroll;
  PayrollCalculatorDefinition? _selected;
  Map<String, double> _inputs = {};
  Map<String, double> _outputs = {};
  List<CalculatorRun> _history = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = PayrollCalculatorRegistry.all.first;
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.getCurrentSettings();
    final history = await _runService.getRecent();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _history = history;
      _resetInputsForSelection(settings);
      _loading = false;
    });
  }

  void _resetInputsForSelection(AppSettings settings) {
    final selected = _selected;
    if (selected == null) return;
    _inputs = selected.defaultInputs(settings);
    _outputs = selected.calculate(_inputs, settings);
  }

  void _selectCategory(String category) {
    final definitions = PayrollCalculatorRegistry.all
        .where((item) => item.category == category)
        .toList();
    if (definitions.isEmpty || _settings == null) return;
    setState(() {
      _category = category;
      _selected = definitions.first;
      _resetInputsForSelection(_settings!);
    });
  }

  void _selectCalculator(PayrollCalculatorDefinition definition) {
    if (_settings == null) return;
    setState(() {
      _selected = definition;
      _resetInputsForSelection(_settings!);
    });
  }

  void _setInput(String key, num? value) {
    final settings = _settings;
    final selected = _selected;
    if (settings == null || selected == null) return;
    setState(() {
      _inputs[key] = value?.toDouble() ?? 0;
      _outputs = selected.calculate(_inputs, settings);
    });
  }

  Future<void> _saveRun() async {
    final settings = _settings;
    final selected = _selected;
    if (settings == null || selected == null || _saving) return;
    setState(() => _saving = true);
    try {
      final today = PersianDateHelper.today();
      final id = await _runService.insert(
        CalculatorRun(
          calculatorId: selected.id,
          year: settings.year,
          month: today.month,
          inputsJson: jsonEncode(_inputs),
          outputsJson: jsonEncode(_outputs),
          formulaVersion: selected.formulaVersion,
          sourceUrlsJson: jsonEncode(selected.sourceUrls),
          createdAt: DateTime.now(),
        ),
      );
      final run = CalculatorRun(
        id: id,
        calculatorId: selected.id,
        year: settings.year,
        month: today.month,
        inputsJson: jsonEncode(_inputs),
        outputsJson: jsonEncode(_outputs),
        formulaVersion: selected.formulaVersion,
        sourceUrlsJson: jsonEncode(selected.sourceUrls),
        createdAt: DateTime.now(),
      );
      if (!mounted) return;
      setState(() => _history = [run, ..._history].take(50).toList());
      AppNotification.success(context, 'محاسبه ذخیره شد');
    } catch (error) {
      if (!mounted) return;
      AppNotification.error(context, 'ذخیره محاسبه انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null || _selected == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final selected = _selected!;
    final definitions = PayrollCalculatorRegistry.all
        .where((item) => item.category == _category)
        .toList();
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    final content = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: _calculatorList(definitions)),
              const SizedBox(width: 16),
              Expanded(child: _calculatorBody(selected)),
              const SizedBox(width: 16),
              SizedBox(width: 320, child: _historyPanel()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _calculatorList(definitions),
              const SizedBox(height: 12),
              _calculatorBody(selected),
              const SizedBox(height: 12),
              _historyPanel(),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('محاسبه‌گرها')),
      body: SingleChildScrollView(
        padding: FloatingNavSafeArea.scrollPadding(
          context,
          left: 16,
          top: 16,
          right: 16,
          minimumBottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_categoryBar(), const SizedBox(height: 16), content],
        ),
      ),
    );
  }

  Widget _categoryBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in CalculatorCategory.all)
          ChoiceChip(
            label: Text(category),
            selected: _category == category,
            onSelected: (_) => _selectCategory(category),
          ),
      ],
    );
  }

  Widget _calculatorList(List<PayrollCalculatorDefinition> definitions) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (final definition in definitions)
            ListTile(
              selected: definition.id == _selected?.id,
              leading: Icon(
                definition.appliesToPayslip
                    ? Icons.receipt_long_rounded
                    : Icons.calculate_rounded,
              ),
              title: Text(definition.title),
              subtitle: Text('نسخه ${definition.formulaVersion}'),
              onTap: () => _selectCalculator(definition),
            ),
        ],
      ),
    );
  }

  Widget _calculatorBody(PayrollCalculatorDefinition selected) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected.appliesToPayslip)
                  Tooltip(
                    message: 'باز کردن فرم فیش حقوقی',
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.receipt_long_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SalaryCalculationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldsGrid(selected),
            const SizedBox(height: 16),
            _outputsPanel(selected),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveRun,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('ذخیره در تاریخچه'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldsGrid(PayrollCalculatorDefinition selected) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final children = [
      for (final field in selected.fields)
        PersianNumberField(
          key: ValueKey('${selected.id}_${field.key}'),
          label: field.label,
          initialValue: _inputs[field.key] ?? 0,
          isCurrency: field.isCurrency,
          suffix: field.suffix,
          prefixIcon: field.isCurrency
              ? Icons.payments_rounded
              : Icons.numbers_rounded,
          onChanged: (value) => _setInput(field.key, value),
        ),
    ];
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final child in children) SizedBox(width: 260, child: child),
      ],
    );
  }

  Widget _outputsPanel(PayrollCalculatorDefinition selected) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          for (final output in selected.outputs)
            _resultRow(
              output.label,
              _outputs[output.key] ?? 0,
              isCurrency: output.isCurrency,
              suffix: output.suffix,
            ),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    double value, {
    bool isCurrency = true,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (isCurrency)
            CurrencyText(
              value,
              showUnit: true,
              style: const TextStyle(fontWeight: FontWeight.w800),
            )
          else
            Text(
              '${PersianNumberFormatter.toPersian(value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2))}${suffix == null ? '' : ' $suffix'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }

  Widget _historyPanel() {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'تاریخچه',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'هنوز محاسبه‌ای ذخیره نشده است.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (final run in _history.take(12)) _historyTile(run),
        ],
      ),
    );
  }

  Widget _historyTile(CalculatorRun run) {
    final definition = PayrollCalculatorRegistry.byId(run.calculatorId);
    final outputs = _decodeDoubleMap(run.outputsJson);
    final firstValue = outputs.values.isEmpty ? 0.0 : outputs.values.first;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history_rounded),
      title: Text(definition?.title ?? run.calculatorId),
      subtitle: Text(
        '${PersianNumberFormatter.toPersian(run.year.toString())}'
        '${run.month == null ? '' : '/${PersianNumberFormatter.toPersian(run.month.toString())}'}',
      ),
      trailing: CurrencyText(firstValue, showUnit: true),
    );
  }

  Map<String, double> _decodeDoubleMap(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          entry.key: (entry.value as num?)?.toDouble() ?? 0,
      };
    } catch (_) {
      return const {};
    }
  }
}
