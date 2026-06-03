import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/theme/app_theme.dart';

void main() {
  test('light and dark themes interpolate without text style assertions', () {
    final light = AppTheme.lightTheme();
    final dark = AppTheme.darkTheme();

    for (final t in <double>[0, 0.25, 0.5, 0.75, 1]) {
      expect(() => ThemeData.lerp(light, dark, t), returnsNormally);
      expect(() => ThemeData.lerp(dark, light, t), returnsNormally);
    }
  });

  testWidgets('SwitchListTile survives animated theme changes', (tester) async {
    final mode = ValueNotifier(ThemeMode.light);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            themeMode: themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: Scaffold(
              body: SwitchListTile(
                value: true,
                title: const Text('Theme'),
                subtitle: const Text('Light or dark'),
                onChanged: (_) {},
              ),
            ),
          );
        },
      ),
    );
    expect(tester.takeException(), isNull);

    mode.value = ThemeMode.dark;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    mode.value = ThemeMode.light;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
