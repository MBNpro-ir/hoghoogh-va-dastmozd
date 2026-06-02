import 'package:flutter/material.dart';

import '../utils/persian_number_formatter.dart';

/// نمایش مقدار ریالی با فرمت فارسی
class CurrencyText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final bool showUnit;
  final bool persian;
  final TextAlign? align;
  final Color? color;

  const CurrencyText(
    this.value, {
    super.key,
    this.style,
    this.showUnit = false,
    this.persian = true,
    this.align,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      PersianNumberFormatter.formatRial(
        value,
        persian: persian,
        showUnit: showUnit,
      ),
      textAlign: align,
      style: (style ?? theme.textTheme.bodyMedium)?.copyWith(
        color: color ?? style?.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
