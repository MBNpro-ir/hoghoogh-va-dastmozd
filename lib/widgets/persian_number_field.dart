import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/persian_number_formatter.dart';

/// فیلد ورودی عدد با جداکننده هزارگان فارسی
class PersianNumberField extends StatefulWidget {
  final String label;
  final String? hint;
  final num? initialValue;
  final ValueChanged<num?>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool isCurrency;
  final IconData? prefixIcon;
  final String? suffix;
  final bool autofocus;
  final TextEditingController? controller;

  const PersianNumberField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.isCurrency = false,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<PersianNumberField> createState() => _PersianNumberFieldState();
}

class _PersianNumberFieldState extends State<PersianNumberField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(
        text: widget.initialValue != null
            ? PersianNumberFormatter.formatNumber(widget.initialValue!)
            : '',
      );
      _ownsController = true;
    }
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant PersianNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsController || _focusNode.hasFocus) return;
    final nextText = widget.initialValue != null
        ? PersianNumberFormatter.formatNumber(widget.initialValue!)
        : '';
    if (_controller.text != nextText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_ownsController || _focusNode.hasFocus) return;
        if (_controller.text == nextText) return;
        _controller.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹,،\.]')),
        _ThousandsSeparatorFormatter(),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        suffixText: widget.suffix ?? (widget.isCurrency ? 'ریال' : null),
        suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      validator: widget.validator,
      onChanged: (text) {
        final value = PersianNumberFormatter.parseNumber(text);
        widget.onChanged?.call(value);
      },
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    // تبدیل ارقام به انگلیسی و حذف کاما
    String cleaned = PersianNumberFormatter.toEnglish(
      newValue.text,
    ).replaceAll(',', '').replaceAll('،', '');
    if (cleaned.isEmpty) return newValue.copyWith(text: '');
    // اگر عدد اعشاری دارد، فقط بخش صحیح را فرمت کن
    String intPart = cleaned;
    String? decPart;
    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      intPart = parts[0];
      decPart = parts.length > 1 ? parts[1] : '';
    }
    final num? value = num.tryParse(intPart);
    if (value == null) return oldValue;
    String formatted = PersianNumberFormatter.formatNumber(value);
    if (decPart != null) formatted = '$formatted.$decPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
