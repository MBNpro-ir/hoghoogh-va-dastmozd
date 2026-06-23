import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/services/appearance_service.dart';
import 'package:payroll_app/widgets/app_viewport_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('old accessibility settings default to a normal UI scale', () async {
    SharedPreferences.setMockInitialValues({
      'app.accessibility': 'ts=1.15;hc=1;rm=0;sr=1;lc=0;es=0;el=1',
    });

    final settings = await AppearanceService().loadAccessibility();

    expect(settings.textScale, 1.15);
    expect(settings.uiScale, 1);
    expect(settings.highContrast, isTrue);
  });

  test('UI scale persists with accessibility settings', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppearanceService();

    await service.saveAccessibility(
      const AccessibilitySettings(textScale: 1.1, uiScale: 1.25),
    );
    final settings = await service.loadAccessibility();

    expect(settings.textScale, 1.1);
    expect(settings.uiScale, 1.25);
  });

  testWidgets('viewport scale changes the logical size of the whole UI', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    Size? logicalSize;
    BoxConstraints? logicalConstraints;
    await tester.pumpWidget(
      MaterialApp(
        home: AppViewportScale(
          scale: 1.25,
          child: Builder(
            builder: (context) {
              logicalSize = MediaQuery.sizeOf(context);
              return LayoutBuilder(
                builder: (context, constraints) {
                  logicalConstraints = constraints;
                  return const SizedBox.expand();
                },
              );
            },
          ),
        ),
      ),
    );

    expect(logicalSize, const Size(640, 480));
    expect(logicalConstraints?.biggest, const Size(640, 480));
    expect(tester.takeException(), isNull);
  });
}
