import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/screens/batch/employee_batch_entry_view.dart';
import 'package:payroll_app/utils/constants.dart';
import 'package:payroll_app/utils/persian_date_helper.dart';

void main() {
  const companyName = 'شرکت آزمایشی';
  final settings = AppSettings(
    companyName: companyName,
    monthlyHousing: 30000000,
    monthlyFood: 21000000,
    monthlyMarriage: 6000000,
    monthlyChild: 15000000,
    dailySeniority: 200000,
    salaryRateA: 1.45,
    salaryRateB: 1.50,
    fixedRial: 500000,
  );

  test('batch employee row starts with single-form defaults', () {
    final draft = EmployeeBatchDraft(settings: settings, personnelCode: 42);
    addTearDown(draft.dispose);

    expect(draft.personnelCode.text, '۴۲');
    expect(draft.workplace.text, companyName);
    expect(draft.startDateEnglish, PersianDateHelper.todayText());
    expect(draft.selectedRate, settings.salaryRateA);
    expect(draft.isActive, isTrue);
    expect(draft.isMarried, isFalse);
    expect(draft.hasPriorExperience, isFalse);
    expect(draft.hasData, isFalse);

    final expectedWage =
        AppConstants.defaultDailyWage1404 * settings.salaryRateA +
        settings.fixedRial;
    expect(_value(draft.dailyWage1404), AppConstants.defaultDailyWage1404);
    expect(_value(draft.dailyWage1405), expectedWage.round());
    expect(
      _value(draft.baseSalary30Days),
      (expectedWage * AppConstants.standardMonthDays).round(),
    );
    expect(_value(draft.monthlyHousing), settings.monthlyHousing);
    expect(_value(draft.monthlyFood), settings.monthlyFood);
    expect(_value(draft.dailyChildAllowance), 0);
    expect(_value(draft.monthlyChildAllowance), 0);
    expect(_value(draft.monthlyMarriage), 0);
  });

  test('batch employee row recalculates linked values and stays editable', () {
    final draft = EmployeeBatchDraft(settings: settings, personnelCode: 7);
    addTearDown(draft.dispose);

    draft
      ..markTouched()
      ..dailyWage1404.text = '4,000,000'
      ..selectedRate = settings.salaryRateB
      ..isMarried = true
      ..autoCalculate(settings);

    expect(draft.hasData, isTrue);
    expect(_value(draft.dailyWage1405), 6500000);
    expect(_value(draft.baseSalary30Days), 195000000);
    expect(_value(draft.dailyMarriage), 200000);
    expect(_value(draft.monthlyMarriage), settings.monthlyMarriage);

    draft.startDate.text = '۱۳۹۹/۰۱/۰۱';
    draft.syncExperienceAndSeniority(settings);
    expect(draft.hasPriorExperience, isTrue);
    expect(_value(draft.dailySeniority), 0);
    expect(_value(draft.monthlySeniority), 0);

    draft.monthlyHousing.text = '45,000,000';
    draft.syncDailyFromMonthly(draft.monthlyHousing, draft.dailyHousing);
    expect(_value(draft.dailyHousing), 1500000);

    draft.dailyFood.text = '800,000';
    draft.syncMonthlyFromDaily(draft.dailyFood, draft.monthlyFood);
    expect(_value(draft.monthlyFood), 24000000);

    draft.setChildrenCount(3);
    draft.autoCalculate(settings);
    expect(draft.childrenCountValue, 3);
    expect(_value(draft.dailyChildAllowance), settings.monthlyChild / 30);
    expect(_value(draft.monthlyChildAllowance), settings.monthlyChild);

    draft.setChildrenCount(0);
    draft.autoCalculate(settings);
    expect(_value(draft.dailyChildAllowance), 0);
    expect(_value(draft.monthlyChildAllowance), 0);
  });

  test('existing employee row keeps identity and copies as a new row', () {
    final employee = Employee(
      id: 12,
      personnelCode: 8,
      firstName: 'علی',
      lastName: 'احمدی',
      nationalId: '1234567890',
      dailyWage1404: 4000000,
      dailyWage1405: 6500000,
      startDate: '1399/02/03',
      birthDate: '1370/04/05',
      isMarried: true,
      hasShiftWork: true,
    );
    final draft = EmployeeBatchDraft.fromEmployee(
      employee: employee,
      settings: settings,
    );
    addTearDown(draft.dispose);

    expect(draft.isExisting, isTrue);
    expect(draft.employeeId, 12);
    expect(draft.touched, isFalse);
    expect(draft.startDate.text, '۱۳۹۹/۰۲/۰۳');
    expect(draft.birthDate.text, '۱۳۷۰/۰۴/۰۵');
    expect(draft.selectedRate, settings.salaryRateB);
    expect(draft.toEmployee().startDate, '1399/02/03');
    expect(draft.hasShiftWork, isTrue);
    expect(draft.toEmployee().hasShiftWork, isTrue);

    final copy = draft.copyAsNew(settings: settings, personnelCode: 25);
    addTearDown(copy.dispose);
    expect(copy.isExisting, isFalse);
    expect(copy.personnelCode.text, '۲۵');
    expect(copy.fullName, draft.fullName);
    expect(copy.touched, isTrue);
    expect(copy.startDate.text, '۱۳۹۹/۰۲/۰۳');
  });
}

num? _value(TextEditingController controller) =>
    EmployeeBatchDraft.parseNumber(controller.text);
