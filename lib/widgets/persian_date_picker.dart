import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../utils/persian_date_helper.dart';
import '../utils/persian_number_formatter.dart';

Future<Jalali?> showPersianDatePicker({
  required BuildContext context,
  Jalali? initialDate,
}) {
  return showDialog<Jalali>(
    context: context,
    builder: (_) =>
        _PersianDatePickerDialog(initialDate: initialDate ?? Jalali.now()),
  );
}

class _PersianDatePickerDialog extends StatefulWidget {
  final Jalali initialDate;

  const _PersianDatePickerDialog({required this.initialDate});

  @override
  State<_PersianDatePickerDialog> createState() =>
      _PersianDatePickerDialogState();
}

class _PersianDatePickerDialogState extends State<_PersianDatePickerDialog> {
  late Jalali _visibleMonth;
  late Jalali _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _visibleMonth = Jalali(widget.initialDate.year, widget.initialDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = (MediaQuery.sizeOf(context).width - 72)
        .clamp(260.0, 540.0)
        .toDouble();
    final isCompact = width < 420;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        title: Row(
          children: [
            IconButton(
              tooltip: 'ماه قبل',
              onPressed: () => setState(() {
                _visibleMonth = _addMonths(_visibleMonth, -1);
              }),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            Expanded(
              child: Text(
                '${PersianDateHelper.monthName(_visibleMonth.month)} ${PersianNumberFormatter.toPersian(_visibleMonth.year.toString())}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'ماه بعد',
              onPressed: () => setState(() {
                _visibleMonth = _addMonths(_visibleMonth, 1);
              }),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _monthYearControls(isCompact),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isCompact ? 1.15 : 1.35,
                children: PersianDateHelper.weekDays
                    .map(
                      (d) => Center(
                        child: Text(
                          d.substring(0, 1),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isCompact ? 1.05 : 1.25,
                children: _dayCells(scheme),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selectedDate),
            child: const Text('انتخاب'),
          ),
        ],
      ),
    );
  }

  Widget _monthYearControls(bool isCompact) {
    Widget monthControl() => DropdownButtonFormField<int>(
      initialValue: _visibleMonth.month,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'ماه'),
      items: [
        for (var month = 1; month <= 12; month++)
          DropdownMenuItem(
            value: month,
            child: Text(PersianDateHelper.monthName(month)),
          ),
      ],
      onChanged: (month) {
        if (month == null) return;
        _setVisibleMonth(_visibleMonth.year, month);
      },
    );

    Widget yearControl() => DropdownButtonFormField<int>(
      initialValue: _visibleMonth.year,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'سال'),
      items: _yearOptions
          .map(
            (year) => DropdownMenuItem(
              value: year,
              child: Text(PersianNumberFormatter.toPersian(year.toString())),
            ),
          )
          .toList(),
      onChanged: (year) {
        if (year == null) return;
        _setVisibleMonth(year, _visibleMonth.month);
      },
    );

    if (isCompact) {
      return Column(
        children: [monthControl(), const SizedBox(height: 8), yearControl()],
      );
    }

    return Row(
      children: [
        Expanded(child: monthControl()),
        const SizedBox(width: 10),
        Expanded(child: yearControl()),
      ],
    );
  }

  List<Widget> _dayCells(ColorScheme scheme) {
    final daysInMonth = PersianDateHelper.daysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final firstDay = Jalali(_visibleMonth.year, _visibleMonth.month, 1);
    final leadingEmpty = (firstDay.weekDay - 1).clamp(0, 6);
    final cells = <Widget>[
      for (var i = 0; i < leadingEmpty; i++) const SizedBox.shrink(),
    ];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = Jalali(_visibleMonth.year, _visibleMonth.month, day);
      final selected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      cells.add(
        Padding(
          padding: const EdgeInsets.all(2),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : Colors.transparent,
              ),
              child: Text(
                PersianNumberFormatter.toPersian(day.toString()),
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return cells;
  }

  Jalali _addMonths(Jalali date, int delta) {
    var year = date.year;
    var month = date.month + delta;
    while (month < 1) {
      year--;
      month += 12;
    }
    while (month > 12) {
      year++;
      month -= 12;
    }
    return Jalali(year, month);
  }

  List<int> get _yearOptions {
    const firstYear = 1300;
    const lastYear = 1450;
    return List.generate(lastYear - firstYear + 1, (i) => firstYear + i);
  }

  void _setVisibleMonth(int year, int month) {
    final maxDay = PersianDateHelper.daysInMonth(year, month);
    final day = _selectedDate.day > maxDay ? maxDay : _selectedDate.day;
    setState(() {
      _visibleMonth = Jalali(year, month);
      _selectedDate = Jalali(year, month, day);
    });
  }
}
