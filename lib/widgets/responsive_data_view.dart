import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ResponsiveTableColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;
  final Object? Function(T item)? sortValue;
  final bool numeric;

  const ResponsiveTableColumn({
    required this.label,
    required this.cellBuilder,
    this.sortValue,
    this.numeric = false,
  });
}

class ResponsiveDataView<T> extends StatelessWidget {
  final List<T> items;
  final List<ResponsiveTableColumn<T>> columns;
  final Widget Function(BuildContext context, T item, int index)
  mobileCardBuilder;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSortColumnChanged;
  final ValueChanged<bool> onSortDirectionChanged;
  final Color? accentColor;

  const ResponsiveDataView({
    super.key,
    required this.items,
    required this.columns,
    required this.mobileCardBuilder,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSortColumnChanged,
    required this.onSortDirectionChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              _MobileSortStrip<T>(
                columns: columns,
                selectedIndex: sortColumnIndex,
                ascending: sortAscending,
                onColumnChanged: onSortColumnChanged,
                onDirectionChanged: onSortDirectionChanged,
                accentColor: accentColor,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      mobileCardBuilder(context, items[index], index),
                ),
              ),
            ],
          );
        }

        final scheme = Theme.of(context).colorScheme;
        final headerColor = accentColor ?? scheme.primary;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: sortAscending,
                    headingRowColor: WidgetStateProperty.all(
                      headerColor.withValues(alpha: 0.14),
                    ),
                    headingTextStyle: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 13),
                    dividerThickness: 0.6,
                    columnSpacing: 22,
                    horizontalMargin: 18,
                    columns: [
                      for (var i = 0; i < columns.length; i++)
                        DataColumn(
                          label: Text(columns[i].label),
                          numeric: columns[i].numeric,
                          onSort: columns[i].sortValue == null
                              ? null
                              : (columnIndex, ascending) {
                                  onSortColumnChanged(columnIndex);
                                  onSortDirectionChanged(ascending);
                                },
                        ),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          color: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return headerColor.withValues(alpha: 0.06);
                            }
                            return null;
                          }),
                          cells: [
                            for (final column in columns)
                              DataCell(column.cellBuilder(item)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MobileDataCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> metrics;
  final List<Widget> actions;

  const MobileDataCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.metrics = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: metrics),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class MobileMetric extends StatelessWidget {
  final String label;
  final Widget value;
  final Color? color;

  const MobileMetric({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 3),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            child: value,
          ),
        ],
      ),
    );
  }
}

class _MobileSortStrip<T> extends StatelessWidget {
  final List<ResponsiveTableColumn<T>> columns;
  final int? selectedIndex;
  final bool ascending;
  final ValueChanged<int> onColumnChanged;
  final ValueChanged<bool> onDirectionChanged;
  final Color? accentColor;

  const _MobileSortStrip({
    required this.columns,
    required this.selectedIndex,
    required this.ascending,
    required this.onColumnChanged,
    required this.onDirectionChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final sortable = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].sortValue != null) i,
    ];
    if (sortable.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final color = accentColor ?? scheme.primary;
    final chipBackground = scheme.surfaceContainerLowest;
    final chipSelected = color.withValues(alpha: 0.16);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final index in sortable)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        label: Text(columns[index].label),
                        selected: selectedIndex == index,
                        onSelected: (_) => onColumnChanged(index),
                        backgroundColor: chipBackground,
                        selectedColor: chipSelected,
                        side: BorderSide(
                          color: selectedIndex == index
                              ? color.withValues(alpha: 0.55)
                              : scheme.outlineVariant,
                        ),
                        checkmarkColor: color,
                        labelStyle: TextStyle(
                          color: selectedIndex == index
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => onDirectionChanged(!ascending),
            icon: Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
            ),
            tooltip: ascending ? 'صعودی' : 'نزولی',
          ),
        ],
      ),
    );
  }
}

List<T> sortResponsiveItems<T>(
  List<T> items,
  List<ResponsiveTableColumn<T>> columns,
  int? sortColumnIndex,
  bool ascending,
) {
  final sorted = List<T>.of(items);
  final index = sortColumnIndex;
  if (index == null || index < 0 || index >= columns.length) return sorted;
  final getter = columns[index].sortValue;
  if (getter == null) return sorted;
  sorted.sort((a, b) {
    final av = getter(a);
    final bv = getter(b);
    final result = _compareSortValues(av, bv);
    return ascending ? result : -result;
  });
  return sorted;
}

int _compareSortValues(Object? a, Object? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  if (a is num && b is num) return a.compareTo(b);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  return a.toString().compareTo(b.toString());
}
