import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/utils/persian_digit_input_formatter.dart';

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  test('PersianDigitsInputFormatter converts visible digits in mixed text', () {
    const formatter = PersianDigitsInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value('هادی شریف 2 - کد 12٠٣'),
    );

    expect(result.text, 'هادی شریف ۲ - کد ۱۲۰۳');
  });

  test('PersianDigitsOnlyInputFormatter keeps only Persian digits', () {
    const formatter = PersianDigitsOnlyInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value('کد 12-٣۴'),
    );

    expect(result.text, '۱۲۳۴');
  });

  test('PersianNumberInputFormatter formats numbers with Persian digits', () {
    const formatter = PersianNumberInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value('1234567'),
    );

    expect(result.text, '۱,۲۳۴,۵۶۷');
  });

  test('employee display getters expose Persian digits', () {
    final employee = Employee(
      personnelCode: 12,
      firstName: 'هادی',
      lastName: 'شریف 2',
      nationalId: '4011710261',
      jobTitle: 'اپراتور 3',
      jobCode: '812345',
      startDate: '1405/01/01',
    );

    expect(employee.fullName, 'هادی شریف ۲');
    expect(employee.displayJob, 'اپراتور ۳ - ۸۱۲۳۴۵');
  });
}
