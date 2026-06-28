import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/widgets/app_notification.dart';

void main() {
  testWidgets('notification shows its semantic type and dismisses smoothly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => AppNotification.success(
                  context,
                  'اطلاعات ذخیره شد',
                  duration: const Duration(milliseconds: 800),
                ),
                child: const Text('نمایش'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('نمایش'));
    await tester.pump();
    expect(find.text('انجام شد'), findsOneWidget);
    expect(find.text('اطلاعات ذخیره شد'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-notification-slide')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('app-notification-fade')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('اطلاعات ذخیره شد'), findsNothing);
  });

  testWidgets('new notification replaces the active notification', (
    tester,
  ) async {
    late BuildContext notificationContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            notificationContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    AppNotification.info(
      notificationContext,
      'پیام اول',
      duration: const Duration(seconds: 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));
    expect(find.text('پیام اول'), findsOneWidget);

    AppNotification.error(
      notificationContext,
      'پیام دوم',
      duration: const Duration(seconds: 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('پیام اول'), findsNothing);
    expect(find.text('پیام دوم'), findsOneWidget);
    expect(find.text('خطا'), findsOneWidget);

    final dismiss = AppNotification.dismissCurrent();
    await tester.pumpAndSettle();
    await dismiss;
  });
}
