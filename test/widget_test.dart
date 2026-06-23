// Basic placeholder test
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/screens/batch/batch_operations_screen.dart';
import 'package:payroll_app/services/window_close_service.dart';
import 'package:payroll_app/widgets/windows_window_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('placeholder test', () {
    expect(1 + 1, 2);
  });

  test('window close behavior falls back to ask for invalid values', () async {
    SharedPreferences.setMockInitialValues({
      'hvm_window_close_behavior_v1': 'bad-value',
    });

    expect(await WindowClosePreferences.getBehavior(), WindowCloseBehavior.ask);
  });

  test('window close behavior and pin state persist locally', () async {
    SharedPreferences.setMockInitialValues({});

    await WindowClosePreferences.setBehavior(WindowCloseBehavior.exit);
    await WindowPinPreferences.setPinned(true);

    expect(
      await WindowClosePreferences.getBehavior(),
      WindowCloseBehavior.exit,
    );
    expect(await WindowPinPreferences.getPinned(), isTrue);
  });

  testWidgets('batch operations shows desktop-only message on mobile', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(const MaterialApp(home: BatchOperationsScreen()));

      expect(
        find.text('بخش عملیات دسته‌ای هنوز برای گوشی آماده نشده است.'),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
