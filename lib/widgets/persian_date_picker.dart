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
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        textDirection: TextDirection.rtl,
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
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
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
              childAspectRatio: 1.25,
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
}
