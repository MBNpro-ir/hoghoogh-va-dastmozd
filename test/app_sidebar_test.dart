import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/widgets/app_sidebar.dart';

void main() {
  const items = [
    SidebarItem(label: 'داشبورد', icon: Icons.dashboard_rounded),
    SidebarItem(label: 'مدیریت کارکنان', icon: Icons.groups_rounded),
  ];

  testWidgets('collapsed sidebar keeps navigation and expand control visible', (
    tester,
  ) async {
    var toggleCount = 0;
    await tester.pumpWidget(
      _sidebarHost(
        width: 84,
        collapsed: true,
        items: items,
        onToggle: () => toggleCount++,
      ),
    );

    expect(find.byTooltip('باز کردن منو'), findsOneWidget);
    expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    expect(find.text('داشبورد'), findsNothing);

    await tester.tap(find.byTooltip('باز کردن منو'));
    expect(toggleCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar expands labels without overflow across widths', (
    tester,
  ) async {
    for (final width in [84.0, 140.0, 199.0, 200.0, 240.0, 280.0]) {
      await tester.pumpWidget(
        _sidebarHost(
          width: width,
          collapsed: width < 200,
          items: items,
          onToggle: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull, reason: 'sidebar width $width');
    }

    expect(find.byTooltip('جمع کردن منو'), findsOneWidget);
    expect(find.text('داشبورد'), findsOneWidget);
    expect(find.text('مدیریت کارکنان'), findsOneWidget);
  });
}

Widget _sidebarHost({
  required double width,
  required bool collapsed,
  required List<SidebarItem> items,
  required VoidCallback onToggle,
}) {
  return MaterialApp(
    home: Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: width,
        height: 640,
        child: AppSidebar(
          currentIndex: 0,
          onSelect: (_) {},
          items: items,
          collapsed: collapsed,
          onToggleCollapsed: onToggle,
        ),
      ),
    ),
  );
}
