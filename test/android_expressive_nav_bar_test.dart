import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/theme/app_theme.dart';
import 'package:payroll_app/widgets/android_expressive_nav_bar.dart';

void main() {
  testWidgets('android expressive nav exposes selected item and taps', (
    tester,
  ) async {
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: AndroidExpressiveNavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
                  destinations: const [
                    AndroidExpressiveNavDestination(
                      icon: Icons.dashboard_rounded,
                      label: 'داشبورد',
                    ),
                    AndroidExpressiveNavDestination(
                      icon: Icons.groups_rounded,
                      label: 'کارکنان',
                    ),
                    AndroidExpressiveNavDestination(
                      icon: Icons.calculate_rounded,
                      label: 'محاسبه',
                    ),
                    AndroidExpressiveNavDestination(
                      icon: Icons.receipt_long_rounded,
                      label: 'فیش‌ها',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byTooltip('داشبورد'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.dashboard_rounded)).size, 27);

    await tester.tap(find.byTooltip('کارکنان'));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(tester.widget<Icon>(find.byIcon(Icons.dashboard_rounded)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.groups_rounded)).size, 27);
  });

  testWidgets('android expressive nav keeps scaffold body visible', (
    tester,
  ) async {
    const bodyKey = ValueKey('body');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: const SizedBox.expand(key: bodyKey),
          bottomNavigationBar: AndroidExpressiveNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: const [
              AndroidExpressiveNavDestination(
                icon: Icons.dashboard_rounded,
                label: 'داشبورد',
              ),
              AndroidExpressiveNavDestination(
                icon: Icons.groups_rounded,
                label: 'کارکنان',
              ),
              AndroidExpressiveNavDestination(
                icon: Icons.calculate_rounded,
                label: 'محاسبه',
              ),
              AndroidExpressiveNavDestination(
                icon: Icons.receipt_long_rounded,
                label: 'فیش‌ها',
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AndroidExpressiveNavigationBar)).height,
      lessThan(120),
    );
    expect(tester.getSize(find.byKey(bodyKey)).height, greaterThan(450));
  });
}
