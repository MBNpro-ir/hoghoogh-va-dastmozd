import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/widgets/floating_nav_safe_area.dart';

void main() {
  testWidgets('floating nav inset applies on compact Android only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    double? androidInset;
    double? wideInset;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            androidInset = FloatingNavSafeArea.scrollBottomInset(
              context,
              minimum: 88,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            wideInset = FloatingNavSafeArea.scrollBottomInset(
              context,
              minimum: 88,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(androidInset, greaterThan(88));
    expect(wideInset, 88);
  });

  testWidgets('floating action buttons are lifted on compact Android', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const fabKey = ValueKey('fab');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            return FloatingNavSafeArea.padFloatingActionButton(
              context,
              const FloatingActionButton(key: fabKey, onPressed: null),
            );
          },
        ),
      ),
    );

    final paddingFinder = find.ancestor(
      of: find.byKey(fabKey),
      matching: find.byType(Padding),
    );
    final padding = tester.widget<Padding>(paddingFinder.first);
    expect(padding.padding.resolve(TextDirection.ltr).bottom, greaterThan(0));
  });
}
