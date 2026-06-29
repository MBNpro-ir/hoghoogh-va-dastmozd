import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/utils/seniority_helper.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  final settings = AppSettings(year: 1405, dailySeniority: 210000);

  test('prior experience is eligible after one payroll-year service', () {
    expect(
      SeniorityHelper.isEligibleForPriorExperience(
        startDate: '1404/12/29',
        settings: settings,
      ),
      isTrue,
    );
    expect(
      SeniorityHelper.isEligibleForPriorExperience(
        startDate: '1405/01/01',
        settings: settings,
      ),
      isFalse,
    );
  });

  test('daily seniority starts at one year of service', () {
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1405/01/01',
        settings: settings,
      ),
      0,
    );
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1404/01/01',
        settings: settings,
      ),
      166667,
    );
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1403/01/01',
        settings: settings,
      ),
      302967,
    );
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1395/01/01',
        settings: settings,
      ),
      1504079,
    );
  });

  test('1405 seniority changes on the exact employment anniversary', () {
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1389/07/24',
        settings: settings,
        asOf: Jalali(1405, 1, 1),
      ),
      1654549,
    );
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1389/07/24',
        settings: settings,
        asOf: Jalali(1405, 7, 23),
      ),
      1654549,
    );
    expect(
      SeniorityHelper.calculateDailySeniority(
        startDate: '1389/07/24',
        settings: settings,
        asOf: Jalali(1405, 7, 24),
      ),
      1821216,
    );
  });

  test('monthly seniority preserves the anniversary-day split', () {
    expect(
      SeniorityHelper.calculateMonthlySeniority(
        startDate: '1389/07/24',
        settings: settings,
        year: 1405,
        month: 1,
        payableDays: 31,
      ),
      51291019,
    );
    expect(
      SeniorityHelper.calculateMonthlySeniority(
        startDate: '1389/07/24',
        settings: settings,
        year: 1405,
        month: 7,
        payableDays: 30,
      ),
      50803139,
    );
  });
}
