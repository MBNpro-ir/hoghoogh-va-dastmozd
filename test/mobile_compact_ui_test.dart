import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/services/sync_service.dart';
import 'package:payroll_app/widgets/period_filter_bar.dart';
import 'package:payroll_app/widgets/responsive_data_view.dart';
import 'package:payroll_app/widgets/sync_status_banner.dart';

void main() {
  testWidgets('mobile period filter starts collapsed', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodFilterBar(
            selectedPeriod: null,
            availablePeriods: const [(1405, 4)],
            onPeriodChanged: (_) {},
            searchController: TextEditingController(),
            onSearchChanged: (_) {},
            searchHint: 'جستجوی آزمایشی',
          ),
        ),
      ),
    );

    expect(find.text('فیلتر و جستجو'), findsOneWidget);
    expect(find.text('جستجوی آزمایشی'), findsNothing);

    await tester.tap(find.text('فیلتر و جستجو'));
    await tester.pumpAndSettle();

    expect(find.text('جستجوی آزمایشی'), findsOneWidget);
    expect(find.text('همه دوره‌ها'), findsOneWidget);
  });

  testWidgets('mobile sorting starts collapsed', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveDataView<int>(
            items: const [1],
            columns: const [
              ResponsiveTableColumn<int>(
                label: 'ستون آزمایشی',
                sortValue: _identity,
                cellBuilder: _numberCell,
              ),
            ],
            mobileCardBuilder: (_, item, _) => Text('ردیف $item'),
            sortColumnIndex: 0,
            sortAscending: true,
            onSortColumnChanged: (_) {},
            onSortDirectionChanged: (_) {},
            mobileHeader: const Text('خلاصه آزمایشی'),
          ),
        ),
      ),
    );

    expect(find.text('مرتب‌سازی'), findsOneWidget);
    expect(find.text('ستون آزمایشی'), findsNothing);
    expect(find.text('خلاصه آزمایشی'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('خلاصه آزمایشی')).dy,
      greaterThan(tester.getTopLeft(find.text('مرتب‌سازی')).dy),
    );

    await tester.tap(find.text('مرتب‌سازی'));
    await tester.pumpAndSettle();

    expect(find.text('ستون آزمایشی'), findsOneWidget);
  });

  testWidgets('mobile sync button surfaces sync errors', (tester) async {
    final sync = SyncService();
    sync.status.value = SyncSnapshot.initial();
    addTearDown(() => sync.status.value = SyncSnapshot.initial());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: const [MobileSyncStatusButton()]),
          body: const SizedBox.expand(),
        ),
      ),
    );

    sync.status.value = const SyncSnapshot(
      phase: SyncPhase.error,
      pendingCount: 2,
      message: 'خطای آزمایشی همگام‌سازی',
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('mobile-sync-status-button')),
      findsOneWidget,
    );
    expect(find.text('خطای آزمایشی همگام‌سازی'), findsOneWidget);
    expect(find.text('جزئیات'), findsOneWidget);
  });
}

Object _identity(int value) => value;

Widget _numberCell(int value) => Text('$value');
