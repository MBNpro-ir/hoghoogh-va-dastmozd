import 'package:flutter/services.dart';

import 'persian_number_formatter.dart';

class PersianDigitsInputFormatter extends TextInputFormatter {
  const PersianDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = PersianNumberFormatter.toPersian(
      PersianNumberFormatter.toEnglish(newValue.text),
    );
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset.clamp(0, text.length),
      ),
      composing: TextRange.empty,
    );
  }
}

class PersianDigitsOnlyInputFormatter extends TextInputFormatter {
  const PersianDigitsOnlyInputFormatter();

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

class PersianDateInputFormatter extends TextInputFormatter {
  const PersianDateInputFormatter();

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

class PersianNumberInputFormatter extends TextInputFormatter {
  const PersianNumberInputFormatter();

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
    final normalized = PersianNumberFormatter.toPersian(
      PersianNumberFormatter.toEnglish(value),
    );
    for (final rune in normalized.runes) {
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
