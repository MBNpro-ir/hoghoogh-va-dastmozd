import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/app_settings.dart';
import 'package:payroll_app/utils/seniority_helper.dart';

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
      settings.dailySeniority,
    );
  });
}
