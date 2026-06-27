import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/widgets/responsive_data_view.dart';

void main() {
  testWidgets('desktop data table keeps pinned columns and scrollbars alive', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1180, 760);
    addTearDown(tester.view.reset);

    final rows = [
      for (var index = 1; index <= 24; index++)
        _PayrollRow(
          index: index,
          code: 1000 + index,
          name: 'کارمند $index',
          period: 'خرداد ۱۴۰۵',
          workDays: 30,
          netPay: '${index * 1000000} ریال',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1040,
            height: 420,
            child: ResponsiveDataView<_PayrollRow>(
              items: rows,
              columns: [
                ResponsiveTableColumn(
                  label: 'ردیف',
                  sortValue: (row) => row.index,
                  cellBuilder: (row) => Text(row.index.toString()),
                ),
                ResponsiveTableColumn(
                  label: 'کد',
                  sortValue: (row) => row.code,
                  cellBuilder: (row) => Text(row.code.toString()),
                ),
                ResponsiveTableColumn(
                  label: 'نام کارمند',
                  sortValue: (row) => row.name,
                  cellBuilder: (row) => Text(row.name),
                ),
                ResponsiveTableColumn(
                  label: 'دوره',
                  sortValue: (row) => row.period,
                  cellBuilder: (row) => Text(row.period),
                ),
                ResponsiveTableColumn(
                  label: 'کارکرد',
                  numeric: true,
                  sortValue: (row) => row.workDays,
                  cellBuilder: (row) => Text(row.workDays.toString()),
                ),
                ResponsiveTableColumn(
                  label: 'خالص دریافتی',
                  numeric: true,
                  sortValue: (row) => row.netPay,
                  cellBuilder: (row) => Text(row.netPay),
                ),
              ],
              mobileCardBuilder: (_, row, _) => Text(row.name),
              sortColumnIndex: 0,
              sortAscending: true,
              onSortColumnChanged: (_) {},
              onSortDirectionChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ردیف'), findsOneWidget);
    expect(find.text('کد'), findsOneWidget);
    expect(find.text('نام کارمند'), findsOneWidget);
    expect(find.byType(Scrollbar), findsNWidgets(2));

    final netPayHeader = find.byKey(const ValueKey('responsive-header-cell-5'));
    final netPayHandle = find.byKey(
      const ValueKey('responsive-column-resize-5'),
    );
    final beforeWidth = tester.getSize(netPayHeader).width;

    await tester.drag(netPayHandle, const Offset(-42, 0));
    await tester.pumpAndSettle();

    expect(tester.getSize(netPayHeader).width, greaterThan(beforeWidth));
  });
}

class _PayrollRow {
  final int index;
  final int code;
  final String name;
  final String period;
  final int workDays;
  final String netPay;

  const _PayrollRow({
    required this.index,
    required this.code,
    required this.name,
    required this.period,
    required this.workDays,
    required this.netPay,
  });
}
